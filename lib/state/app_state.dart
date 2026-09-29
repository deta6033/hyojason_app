import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

// 앱 전체에서 사용하는 데이터를 관리합니다.
class AppState extends ChangeNotifier {
  final LocalStorageService storage;

  AppState({required this.storage});

  final List<DailyRecord> _records = [];
  final List<MedicationSchedule> _medications = [];
  final List<AppNotificationItem> _notifications = [];

  GuardianSettings _guardian = const GuardianSettings(
    guardianName: '보호자',
    elderName: '김OO',
    relationship: '자녀',
    phone: '',
    notificationEnabled: true,
  );

  DeviceStatus _baseDevice = DeviceStatus(
    connected: true,
    battery: 82,
    networkName: 'HOME Wi-Fi',
    lastSync: DateTime.now(),
    deviceId: 'HYOJA-001',
  );

  bool _onboardingComplete = false;
  DemoScenario _demoScenario = DemoScenario.normal;

  List<DailyRecord> get records => List.unmodifiable(_records);
  List<MedicationSchedule> get medications => List.unmodifiable(_medications);
  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);
  GuardianSettings get guardian => _guardian;
  bool get onboardingComplete => _onboardingComplete;
  DemoScenario get demoScenario => _demoScenario;

  DeviceStatus get device => switch (_demoScenario) {
        DemoScenario.disconnected => _baseDevice.copyWith(connected: false),
        DemoScenario.lowBattery => _baseDevice.copyWith(battery: 8),
        _ => _baseDevice,
      };

  DailyRecord get todayRecord {
    final now = DateTime.now();
    final base = _records.firstWhere(
      (record) => isSameDate(record.date, now),
      orElse: () => _records.first,
    );

    return switch (_demoScenario) {
      DemoScenario.medicineMissing => base.copyWith(
          medicine: false,
          summary:
              '오늘 식사와 외출 기록은 정상적으로 확인되었지만 오후 5시 혈압약 복용 여부가 아직 확인되지 않았습니다.',
          aiComment: '복약 여부를 보호자가 한 번 확인해 주세요.',
        ),
      DemoScenario.noConversation => base.copyWith(
          summary: '최근 24시간 동안 새로운 대화가 확인되지 않았습니다.',
          aiComment: '어르신의 상태를 직접 확인해보는 것이 좋습니다.',
          conversations: const [],
        ),
      _ => base,
    };
  }

  int get unreadNotificationCount => _notifications.where((item) => !item.read).length;

  DailyRecord? recordForDate(DateTime date) {
    for (final record in _records) {
      if (isSameDate(record.date, date)) return record;
    }
    return null;
  }

  Future<void> initialize() async {
    _createFakeDailyRecords();

    _guardian = await storage.loadGuardian() ?? _guardian;

    final savedMedications = await storage.loadMedications();
    _medications
      ..clear()
      ..addAll(savedMedications.isEmpty ? _defaultMedications() : savedMedications);
    if (savedMedications.isEmpty) await storage.saveMedications(_medications);

    final savedNotifications = await storage.loadNotifications();
    _notifications
      ..clear()
      ..addAll(savedNotifications.isEmpty ? _defaultNotifications() : savedNotifications);
    if (savedNotifications.isEmpty) await storage.saveNotifications(_notifications);

    _onboardingComplete = await storage.isOnboardingComplete();
    _demoScenario = await storage.loadDemoScenario();
    _baseDevice = DeviceStatus(
      connected: true,
      battery: 82,
      networkName: 'HOME Wi-Fi',
      lastSync: DateTime.now().subtract(const Duration(minutes: 3)),
      deviceId: 'HYOJA-001',
    );

    await NotificationService.instance.initialize();
    await NotificationService.instance.rescheduleAll(_medications);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String guardianName,
    required String elderName,
    required String relationship,
  }) async {
    _guardian = _guardian.copyWith(
      guardianName: guardianName,
      elderName: elderName,
      relationship: relationship,
    );
    _onboardingComplete = true;
    await storage.saveGuardian(_guardian);
    await storage.setOnboardingComplete(true);
    await NotificationService.instance.requestPermission();
    notifyListeners();
  }

  Future<void> addMedication(MedicationSchedule schedule) async {
    _medications.add(schedule);
    await _persistMedications();
    if (schedule.enabled) await NotificationService.instance.scheduleMedication(schedule);
    notifyListeners();
  }

  Future<void> updateMedication(MedicationSchedule schedule) async {
    final index = _medications.indexWhere((item) => item.id == schedule.id);
    if (index < 0) return;
    _medications[index] = schedule;
    await _persistMedications();
    await NotificationService.instance.cancelMedication(schedule.id);
    if (schedule.enabled) await NotificationService.instance.scheduleMedication(schedule);
    notifyListeners();
  }

  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((item) => item.id == id);
    await _persistMedications();
    await NotificationService.instance.cancelMedication(id);
    notifyListeners();
  }

  Future<void> _persistMedications() => storage.saveMedications(_medications);

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].read) return;
    _notifications[index] = _notifications[index].copyWith(read: true);
    await storage.saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    await storage.saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> addAppNotification({
    required String title,
    required String message,
    required AppNotificationType type,
  }) async {
    _notifications.insert(
      0,
      AppNotificationItem(
        id: 'notification_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        message: message,
        time: DateTime.now(),
        type: type,
        read: false,
      ),
    );
    await storage.saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> updateGuardian(GuardianSettings settings) async {
    _guardian = settings;
    await storage.saveGuardian(settings);
    notifyListeners();
  }

  Future<void> setDemoScenario(DemoScenario scenario) async {
    if (_demoScenario == scenario) return;
    _demoScenario = scenario;
    await storage.saveDemoScenario(scenario);

    final notification = switch (scenario) {
      DemoScenario.normal => null,
      DemoScenario.medicineMissing => (
          '복약 확인이 필요해요',
          '오후 5시 혈압약 복용 응답이 아직 확인되지 않았습니다.',
          AppNotificationType.warning,
        ),
      DemoScenario.noConversation => (
          '24시간 동안 대화가 없어요',
          '어르신의 상태를 직접 확인해주세요.',
          AppNotificationType.warning,
        ),
      DemoScenario.disconnected => (
          '효자손 연결 끊김',
          '효자손 기기와 연결되지 않고 있습니다.',
          AppNotificationType.device,
        ),
      DemoScenario.lowBattery => (
          '효자손 배터리 부족',
          '기기 배터리가 8% 남았습니다. 충전해주세요.',
          AppNotificationType.device,
        ),
    };

    if (notification != null) {
      await addAppNotification(
        title: notification.$1,
        message: notification.$2,
        type: notification.$3,
      );
    } else {
      notifyListeners();
    }
  }

  Future<void> showTestNotification() async {
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.showTestNotification();
  }

  Future<void> resetPrototype() async {
    for (final medication in _medications) {
      await NotificationService.instance.cancelMedication(medication.id);
    }
    await storage.resetAll();
    _records.clear();
    _medications.clear();
    _notifications.clear();
    _guardian = const GuardianSettings(
      guardianName: '보호자',
      elderName: '김OO',
      relationship: '자녀',
      phone: '',
      notificationEnabled: true,
    );
    _onboardingComplete = false;
    _demoScenario = DemoScenario.normal;
    _createFakeDailyRecords();
    _medications.addAll(_defaultMedications());
    _notifications.addAll(_defaultNotifications());
    await storage.saveMedications(_medications);
    await storage.saveNotifications(_notifications);
    notifyListeners();
  }

  void _createFakeDailyRecords() {
    _records.clear();
    final now = DateTime.now();

    _records.add(
      DailyRecord(
        date: now,
        meal: true,
        medicine: true,
        outing: true,
        mood: '좋음',
        summary:
            '오늘 아침 식사를 완료했고 오후에는 동네 공원으로 산책을 다녀오셨습니다. 오후 5시 복약도 완료했으며 전반적으로 기분이 좋다고 말씀하셨습니다.',
        aiComment: '식사와 복약을 모두 잘 챙기셨고 산책도 다녀오셨어요. 특별히 걱정되는 내용은 없어요.',
        conversations: [
          ConversationMessage(
            time: DateTime(now.year, now.month, now.day, 9, 10),
            text: '좋은 아침이에요. 아침 식사는 하셨어요?',
            isAi: true,
          ),
          ConversationMessage(
            time: DateTime(now.year, now.month, now.day, 9, 11),
            text: '응. 오늘은 미역국이랑 밥 먹었어.',
            isAi: false,
          ),
          ConversationMessage(
            time: DateTime(now.year, now.month, now.day, 13, 20),
            text: '오늘은 밖에 다녀오셨어요?',
            isAi: true,
          ),
          ConversationMessage(
            time: DateTime(now.year, now.month, now.day, 13, 21),
            text: '동네 공원에 잠깐 산책 다녀왔어.',
            isAi: false,
          ),
          ConversationMessage(
            time: DateTime(now.year, now.month, now.day, 17, 2),
            text: '오후에 드실 약은 챙겨 드셨어요?',
            isAi: true,
          ),
          ConversationMessage(
            time: DateTime(now.year, now.month, now.day, 17, 3),
            text: '응. 방금 먹었어. 오늘 기분도 좋아.',
            isAi: false,
          ),
        ],
      ),
    );

    const moods = ['평온함', '좋음', '보통', '좋음', '조금 피곤함', '좋음'];
    for (var i = 1; i <= 6; i++) {
      final date = now.subtract(Duration(days: i));
      _records.add(
        DailyRecord(
          date: date,
          meal: true,
          medicine: i != 3,
          outing: i.isEven,
          mood: moods[i - 1],
          summary: i == 3
              ? '식사는 정상적으로 하셨지만 저녁 복약 확인이 되지 않았습니다. 보호자의 확인이 필요합니다.'
              : '식사를 정상적으로 하셨고 특별한 이상 징후 없이 평소와 비슷한 하루를 보내셨습니다.',
          aiComment: i == 3 ? '복약 여부를 한 번 확인해주세요.' : '특별히 걱정되는 내용은 없어요.',
          conversations: [
            ConversationMessage(
              time: DateTime(date.year, date.month, date.day, 10),
              text: '오늘 아침 식사는 하셨어요?',
              isAi: true,
            ),
            ConversationMessage(
              time: DateTime(date.year, date.month, date.day, 10, 1),
              text: '응. 아침 먹었어.',
              isAi: false,
            ),
          ],
        ),
      );
    }
  }

  List<MedicationSchedule> _defaultMedications() => const [
        MedicationSchedule(
          id: 'medicine_1',
          name: '혈압약',
          hour: 17,
          minute: 0,
          days: [1, 2, 3, 4, 5, 6, 7],
          enabled: true,
        ),
        MedicationSchedule(
          id: 'medicine_2',
          name: '비타민',
          hour: 9,
          minute: 0,
          days: [1, 2, 3, 4, 5],
          enabled: true,
        ),
      ];

  List<AppNotificationItem> _defaultNotifications() {
    final now = DateTime.now();
    return [
      AppNotificationItem(
        id: 'notification_1',
        title: '복약 확인 완료',
        message: '오후 5시 혈압약 복용이 확인되었습니다.',
        time: now.subtract(const Duration(minutes: 20)),
        type: AppNotificationType.medicine,
        read: false,
      ),
      AppNotificationItem(
        id: 'notification_2',
        title: '오늘의 요약이 도착했어요',
        message: '오늘 하루의 식사, 복약, 외출 기록을 확인해보세요.',
        time: now.subtract(const Duration(hours: 1)),
        type: AppNotificationType.summary,
        read: false,
      ),
      AppNotificationItem(
        id: 'notification_3',
        title: '효자손 연결 정상',
        message: '기기가 정상적으로 연결되어 있습니다.',
        time: now.subtract(const Duration(hours: 5)),
        type: AppNotificationType.device,
        read: true,
      ),
    ];
  }
}

// Provider 같은 외부 상태관리 패키지 없이 AppState를 앱 전체에 공유합니다.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope를 찾을 수 없습니다.');
    return scope!.notifier!;
  }
}
