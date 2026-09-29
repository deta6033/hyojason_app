import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

// 보호자 설정, 복약 일정, 앱 내 알림을 휴대폰에 저장합니다.
class LocalStorageService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const _guardianKey = 'guardian_settings';
  static const _medicationKey = 'medications';
  static const _notificationKey = 'notifications';
  static const _onboardingKey = 'onboarding_complete';
  static const _demoScenarioKey = 'demo_scenario';

  Future<bool> isOnboardingComplete() async =>
      await _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  Future<void> saveGuardian(GuardianSettings settings) =>
      _prefs.setString(_guardianKey, jsonEncode(settings.toJson()));

  Future<GuardianSettings?> loadGuardian() async {
    final raw = await _prefs.getString(_guardianKey);
    if (raw == null) return null;
    try {
      return GuardianSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMedications(List<MedicationSchedule> schedules) =>
      _prefs.setString(
        _medicationKey,
        jsonEncode(schedules.map((item) => item.toJson()).toList()),
      );

  Future<List<MedicationSchedule>> loadMedications() async {
    final raw = await _prefs.getString(_medicationKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => MedicationSchedule.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(List<AppNotificationItem> notifications) =>
      _prefs.setString(
        _notificationKey,
        jsonEncode(notifications.map((item) => item.toJson()).toList()),
      );

  Future<List<AppNotificationItem>> loadNotifications() async {
    final raw = await _prefs.getString(_notificationKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => AppNotificationItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDemoScenario(DemoScenario scenario) =>
      _prefs.setString(_demoScenarioKey, scenario.name);

  Future<DemoScenario> loadDemoScenario() async {
    final name = await _prefs.getString(_demoScenarioKey);
    return DemoScenario.values.firstWhere(
      (item) => item.name == name,
      orElse: () => DemoScenario.normal,
    );
  }

  Future<void> resetAll() async {
    for (final key in [
      _guardianKey,
      _medicationKey,
      _notificationKey,
      _onboardingKey,
      _demoScenarioKey,
    ]) {
      await _prefs.remove(key);
    }
  }
}
