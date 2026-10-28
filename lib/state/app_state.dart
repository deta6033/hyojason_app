import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

// 더미 기록을 사용하지 않는 실제 보호자 앱 상태.
// 대화/복약/알림은 Firestore 실시간 스냅샷으로 갱신한다.
class AppState extends ChangeNotifier {
  final LocalStorageService storage;
  final FirestoreService remote = FirestoreService();
  AppState({required this.storage});

  final List<DailyRecord> _records = [];
  final List<MedicationSchedule> _medications = [];
  final List<AppNotificationItem> _notifications = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  GuardianSettings _guardian = const GuardianSettings(
    guardianName: '보호자', elderName: '어르신', relationship: '보호자',
    phone: '', notificationEnabled: true);
  DeviceStatus _device = DeviceStatus(
    connected: false, battery: -1, networkName: '확인 불가',
    lastSync: DateTime.fromMillisecondsSinceEpoch(0),
    deviceId: FirestoreService.deviceId);
  bool _onboardingComplete = false;
  bool _liveReady = false;
  String? _error;

  List<DailyRecord> get records => List.unmodifiable(_records);
  List<MedicationSchedule> get medications => List.unmodifiable(_medications);
  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);
  GuardianSettings get guardian => _guardian;
  DeviceStatus get device => _device;
  bool get onboardingComplete => _onboardingComplete;
  bool get liveReady => _liveReady;
  String? get error => _error;
  DemoScenario get demoScenario => DemoScenario.normal;

  DailyRecord get todayRecord => recordForDate(DateTime.now()) ?? _emptyToday();
  DailyRecord _emptyToday() => DailyRecord(
    date: DateTime.now(), meal: false, medicine: false, outing: false,
    mood: '미확인', summary: '오늘 기록된 대화가 아직 없습니다.',
    aiComment: '실제 대화가 들어오면 여기에 표시됩니다.',
    conversations: const []);

  int get unreadNotificationCount =>
      _notifications.where((item) => !item.read).length;

  DailyRecord? recordForDate(DateTime date) {
    for (final record in _records) {
      if (isSameDate(record.date, date)) return record;
    }
    return null;
  }

  Future<void> initialize() async {
    // 이름 및 온보딩은 해당 휴대폰에 저장; 허가된 Firebase 계정만 서버 접근.
    _guardian = await storage.loadGuardian() ?? _guardian;
    _onboardingComplete = await storage.isOnboardingComplete();
    await NotificationService.instance.initialize();
    notifyListeners();
  }

  DateTime _when(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // 로그인 완료 후 실시간 수신 시작; 중복 구독은 반드시 해제한다.
  Future<void> startLive() async {
    await stopLive();
    try {
      if (!await remote.isAuthorized()) {
        _error = '이 계정에 효자손 기기 접근 권한이 없습니다. 관리자에게 UID 등록을 요청하세요.';
        notifyListeners();
        return;
      }
    } catch (e) {
      _error = 'Firebase 보호자 권한 검사 실패: $e';
      notifyListeners();
      return;
    }

    _liveReady = true;
    _error = null;
    notifyListeners();

    _subscriptions.add(remote.conversations().listen((snap) {
      final byDay = <DateTime, List<ConversationMessage>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final when = _when(data['createdAt']);
        if (when.year < 2020) continue;
        final date = DateTime(when.year, when.month, when.day);
        final messages = byDay.putIfAbsent(date, () => []);
        final question = (data['question'] as String? ?? '').trim();
        final answer = (data['reply'] as String? ?? '').trim();
        if (question.isNotEmpty) {
          messages.add(ConversationMessage(time: when, text: question, isAi: false));
        }
        if (answer.isNotEmpty) {
          messages.add(ConversationMessage(
            time: when.add(const Duration(milliseconds: 1)), text: answer, isAi: true));
        }
      }
      _records.clear();
      for (final item in byDay.entries) {
        item.value.sort((a, b) => a.time.compareTo(b.time));
        _records.add(DailyRecord(
          date: item.key, meal: false, medicine: false, outing: false,
          mood: '미확인',
          summary: '실제 AI 대화 ${item.value.where((m) => !m.isAi).length}건이 기록되었습니다. '
              '식사·복약·외출 정보는 아직 수집되지 않았습니다.',
          aiComment: '이 기록은 AI 하루 요약이 아닌 실제 대화 목록입니다.',
          conversations: item.value));
      }
      _records.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }, onError: _listenError));

    _subscriptions.add(remote.deviceStatus().listen((snap) {
      final info = snap.data();
      final battery = info?['battery'];
      final lastSeen = _when(info?['lastSeenAt']);
      // 서버 heartbeat가 2분 이내인 경우에만 온라인으로 표시.
      final validHeartbeat = lastSeen.year >= 2020 &&
          DateTime.now().difference(lastSeen).inSeconds.abs() < 120;
      _device = DeviceStatus(
        connected: validHeartbeat && info?['online'] == true,
        battery: battery is num ? battery.toInt() : -1,
        networkName: info?['networkName'] as String? ?? '확인 불가',
        lastSync: lastSeen,
        deviceId: FirestoreService.deviceId);
      notifyListeners();
    }, onError: _listenError));

    _subscriptions.add(remote.medications().listen((snap) {
      _medications
        ..clear()
        ..addAll(snap.docs.map((doc) => MedicationSchedule.fromJson({
          ...doc.data(), 'id': doc.id,
        })));
      _syncLocalMedicationAlerts();
      notifyListeners();
    }, onError: _listenError));

    _subscriptions.add(remote.notifications().listen((snap) {
      _notifications
        ..clear()
        ..addAll(snap.docs.map((doc) {
          final data = doc.data();
          final raw = data['time'];
          return AppNotificationItem(
            id: doc.id,
            title: data['title'] as String? ?? '',
            message: data['message'] as String? ?? '',
            time: _when(raw),
            type: AppNotificationType.values.firstWhere(
              (type) => type.name == data['type'],
              orElse: () => AppNotificationType.device),
            read: data['read'] == true);
        }));
      notifyListeners();
    }, onError: _listenError));
  }

  void _listenError(Object e) {
    _error = '실시간 데이터 수신 오류: $e';
    notifyListeners();
  }

  Future<void> _syncLocalMedicationAlerts() async {
    if (!_guardian.notificationEnabled) return;
    try {
      await NotificationService.instance.rescheduleAll(_medications);
    } catch (_) { /* 알림 권한 거부 시에도 서버 데이터는 유지 */ }
  }

  Future<void> stopLive() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _records.clear();
    _medications.clear();
    _notifications.clear();
    _liveReady = false;
    _error = null;
    _device = DeviceStatus(
      connected: false, battery: -1, networkName: '확인 불가',
      lastSync: DateTime.fromMillisecondsSinceEpoch(0),
      deviceId: FirestoreService.deviceId);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String guardianName,
    required String elderName,
    required String relationship,
  }) async {
    _guardian = _guardian.copyWith(
      guardianName: guardianName, elderName: elderName,
      relationship: relationship);
    _onboardingComplete = true;
    await storage.saveGuardian(_guardian);
    await storage.setOnboardingComplete(true);
    await NotificationService.instance.requestPermission();
    notifyListeners();
  }

  Future<void> addMedication(MedicationSchedule schedule) =>
      remote.saveMedication(schedule);
  Future<void> updateMedication(MedicationSchedule schedule) =>
      remote.saveMedication(schedule);
  Future<void> deleteMedication(String id) => remote.deleteMedication(id);

  Future<void> markNotificationRead(String id) => remote.markRead(id);
  Future<void> markAllNotificationsRead() => remote.markAllRead(
    _notifications.where((item) => !item.read).map((item) => item.id));

  Future<void> addAppNotification({
    required String title, required String message,
    required AppNotificationType type,
  }) => remote.addNotification(AppNotificationItem(
    id: 'notification_${DateTime.now().microsecondsSinceEpoch}',
    title: title, message: message, time: DateTime.now(),
    type: type, read: false));

  Future<void> updateGuardian(GuardianSettings settings) async {
    final changed = settings.notificationEnabled != _guardian.notificationEnabled;
    _guardian = settings;
    await storage.saveGuardian(settings);
    if (changed) {
      if (settings.notificationEnabled) {
        await NotificationService.instance.requestPermission();
        await NotificationService.instance.rescheduleAll(_medications);
      } else {
        for (final medication in _medications) {
          await NotificationService.instance.cancelMedication(medication.id);
        }
      }
    }
    notifyListeners();
  }

  // 시연용 가짜 상태 시나리오는 제거한다.
  Future<void> setDemoScenario(DemoScenario _) async {}

  Future<void> showTestNotification() async {
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.showTestNotification();
  }

  // 로컬 개인정보 초기화만 진행. 서버의 실제 대화 기록은 삭제하지 않는다.
  Future<void> resetPrototype() async {
    await storage.resetAll();
    _guardian = const GuardianSettings(
      guardianName: '보호자', elderName: '어르신',
      relationship: '보호자', phone: '', notificationEnabled: true);
    _onboardingComplete = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required super.child})
      : super(notifier: notifier);
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope를 찾을 수 없습니다.');
    return scope!.notifier!;
  }
}
