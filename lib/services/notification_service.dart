import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

// Android/iOS의 실제 시스템 알림을 담당합니다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_supportedPlatform) return;

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    if (!_supportedPlatform || !_initialized) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showTestNotification() async {
    if (!_supportedPlatform || !_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'hyojason_test',
        '효자손 테스트',
        channelDescription: '효자손 시스템 알림 테스트',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: 900001,
      title: '효자손',
      body: '알림이 정상적으로 작동하고 있어요.',
      notificationDetails: details,
    );
  }

  Future<void> scheduleMedication(MedicationSchedule schedule) async {
    if (!_supportedPlatform || !_initialized || !schedule.enabled) return;

    await cancelMedication(schedule.id);
    for (final weekday in schedule.days) {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'hyojason_medicine',
          '복약 알림',
          channelDescription: '등록된 복약 시간에 알려드립니다.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id: _notificationId(schedule.id, weekday),
        title: '효자손 복약 알림',
        body: '${schedule.name}을(를) 복용할 시간입니다.',
        scheduledDate: _nextInstanceOfWeekdayAndTime(
          weekday,
          schedule.hour,
          schedule.minute,
        ),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'medication:${schedule.id}',
      );
    }
  }

  Future<void> rescheduleAll(List<MedicationSchedule> medications) async {
    if (!_supportedPlatform || !_initialized) return;
    for (final medication in medications) {
      if (medication.enabled) {
        await scheduleMedication(medication);
      } else {
        await cancelMedication(medication.id);
      }
    }
  }

  Future<void> cancelMedication(String medicationId) async {
    if (!_supportedPlatform || !_initialized) return;
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(medicationId, weekday));
    }
  }

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      final nextDay = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
        tz.local,
        nextDay.year,
        nextDay.month,
        nextDay.day,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  int _notificationId(String medicationId, int weekday) {
    var hash = 0;
    for (final codeUnit in medicationId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return (hash % 100000) * 10 + weekday;
  }
}
