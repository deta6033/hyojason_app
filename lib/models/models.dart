// 효자손 앱의 데이터 구조를 정의합니다.

bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String twoDigits(int value) => value.toString().padLeft(2, '0');

String formatKoreanDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}

String formatKoreanTime(DateTime date) {
  final isPm = date.hour >= 12;
  var hour = date.hour % 12;
  if (hour == 0) hour = 12;
  return '${isPm ? '오후' : '오전'} $hour:${twoDigits(date.minute)}';
}

class ConversationMessage {
  final DateTime time;
  final String text;
  final bool isAi;

  const ConversationMessage({
    required this.time,
    required this.text,
    required this.isAi,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'text': text,
        'isAi': isAi,
      };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      time: DateTime.parse(json['time'] as String),
      text: json['text'] as String? ?? '',
      isAi: json['isAi'] as bool? ?? false,
    );
  }
}

class DailyRecord {
  final DateTime date;
  final bool meal;
  final bool medicine;
  final bool outing;
  final String mood;
  final String summary;
  final String aiComment;
  final List<ConversationMessage> conversations;

  const DailyRecord({
    required this.date,
    required this.meal,
    required this.medicine,
    required this.outing,
    required this.mood,
    required this.summary,
    required this.aiComment,
    required this.conversations,
  });

  DailyRecord copyWith({
    bool? meal,
    bool? medicine,
    bool? outing,
    String? mood,
    String? summary,
    String? aiComment,
    List<ConversationMessage>? conversations,
  }) {
    return DailyRecord(
      date: date,
      meal: meal ?? this.meal,
      medicine: medicine ?? this.medicine,
      outing: outing ?? this.outing,
      mood: mood ?? this.mood,
      summary: summary ?? this.summary,
      aiComment: aiComment ?? this.aiComment,
      conversations: conversations ?? this.conversations,
    );
  }
}

class MedicationSchedule {
  final String id;
  final String name;
  final int hour;
  final int minute;
  final List<int> days; // 월=1 ~ 일=7
  final bool enabled;

  const MedicationSchedule({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.days,
    required this.enabled,
  });

  MedicationSchedule copyWith({
    String? id,
    String? name,
    int? hour,
    int? minute,
    List<int>? days,
    bool? enabled,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
    );
  }

  String get timeText {
    final isPm = hour >= 12;
    var displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    return '${isPm ? '오후' : '오전'} $displayHour:${twoDigits(minute)}';
  }

  String get daysText {
    final sorted = [...days]..sort();
    if (sorted.length == 7) return '매일';
    if (sorted.join(',') == '1,2,3,4,5') return '평일';
    const names = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    return sorted.map((day) => names[day] ?? '').join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hour': hour,
        'minute': minute,
        'days': days,
        'enabled': enabled,
      };

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      days: List<int>.from(json['days'] as List? ?? const [1, 2, 3, 4, 5, 6, 7]),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

enum AppNotificationType { summary, medicine, warning, device }

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final AppNotificationType type;
  final bool read;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.read,
  });

  AppNotificationItem copyWith({bool? read}) => AppNotificationItem(
        id: id,
        title: title,
        message: message,
        time: time,
        type: type,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time.toIso8601String(),
        'type': type.name,
        'read': read,
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      time: DateTime.parse(json['time'] as String),
      type: AppNotificationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AppNotificationType.summary,
      ),
      read: json['read'] as bool? ?? false,
    );
  }
}

class DeviceStatus {
  final bool connected;
  final int battery;
  final String networkName;
  final DateTime lastSync;
  final String deviceId;

  const DeviceStatus({
    required this.connected,
    required this.battery,
    required this.networkName,
    required this.lastSync,
    required this.deviceId,
  });

  DeviceStatus copyWith({
    bool? connected,
    int? battery,
    String? networkName,
    DateTime? lastSync,
    String? deviceId,
  }) {
    return DeviceStatus(
      connected: connected ?? this.connected,
      battery: battery ?? this.battery,
      networkName: networkName ?? this.networkName,
      lastSync: lastSync ?? this.lastSync,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class GuardianSettings {
  final String guardianName;
  final String elderName;
  final String relationship;
  final String phone;
  final bool notificationEnabled;

  const GuardianSettings({
    required this.guardianName,
    required this.elderName,
    required this.relationship,
    required this.phone,
    required this.notificationEnabled,
  });

  GuardianSettings copyWith({
    String? guardianName,
    String? elderName,
    String? relationship,
    String? phone,
    bool? notificationEnabled,
  }) {
    return GuardianSettings(
      guardianName: guardianName ?? this.guardianName,
      elderName: elderName ?? this.elderName,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'guardianName': guardianName,
        'elderName': elderName,
        'relationship': relationship,
        'phone': phone,
        'notificationEnabled': notificationEnabled,
      };

  factory GuardianSettings.fromJson(Map<String, dynamic> json) {
    return GuardianSettings(
      guardianName: json['guardianName'] as String? ?? '보호자',
      elderName: json['elderName'] as String? ?? '김OO',
      relationship: json['relationship'] as String? ?? '자녀',
      phone: json['phone'] as String? ?? '',
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
    );
  }
}

enum DemoScenario { normal, medicineMissing, noConversation, disconnected, lowBattery }

extension DemoScenarioLabel on DemoScenario {
  String get displayName => switch (this) {
        DemoScenario.normal => '정상 상태',
        DemoScenario.medicineMissing => '복약 미확인',
        DemoScenario.noConversation => '24시간 대화 없음',
        DemoScenario.disconnected => '기기 연결 끊김',
        DemoScenario.lowBattery => '배터리 부족',
      };

  String get description => switch (this) {
        DemoScenario.normal => '모든 기록과 기기 상태가 정상인 상황',
        DemoScenario.medicineMissing => '정해진 복약 시간이 지났지만 응답이 없는 상황',
        DemoScenario.noConversation => '24시간 동안 어르신과 대화가 확인되지 않은 상황',
        DemoScenario.disconnected => '효자손 기기 연결이 끊긴 상황',
        DemoScenario.lowBattery => '기기 배터리가 15% 이하로 내려간 상황',
      };
}
