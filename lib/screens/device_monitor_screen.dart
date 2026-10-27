import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/firestore_service.dart';

// Firebase에 실제 보고된 정보만 표시합니다. ESP32 연결을 추측하지 않습니다.
class DeviceMonitorScreen extends StatelessWidget {
  const DeviceMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('효자손 기기 상태')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().deviceStatus(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('기기 정보를 읽을 수 없습니다.\n\u0024{snapshot.error}',
                textAlign: TextAlign.center));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final seen = data['lastSeenAt'];
          final lastSeen = seen is Timestamp ? seen.toDate().toLocal() : null;
          final connected = data['online'] == true &&
              lastSeen != null &&
              DateTime.now().difference(lastSeen).inSeconds.abs() < 120;
          final rawLocation = data['location'];
          final location = rawLocation is Map ? rawLocation : const <String, dynamic>{};
          final latitude = _coordinate(location['latitude'] ?? location['lat'] ?? data['latitude']);
          final longitude = _coordinate(location['longitude'] ?? location['lng'] ?? data['longitude']);
          final locationTime = location['updatedAt'];
          final locationDate = locationTime is Timestamp ? locationTime.toDate().toLocal() : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: connected ? AppTheme.greenSoft : AppTheme.orangeSoft,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(connected ? '온라인' : '연결 미확인',
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(lastSeen == null
                        ? '기기에서 상태 보고를 아직 받지 못했습니다.'
                        : '마지막 보고: \u0024{_date(lastSeen)}'),
                    const SizedBox(height: 6),
                    const Text('2분 이내 서버 보고가 있을 때에만 온라인으로 표시합니다.'),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              _value('기기 ID', FirestoreService.deviceId),
              _value('배터리', data['battery'] is num ? '\u0024{data['battery']}%' : '정보 없음'),
              _value('네트워크', data['networkName'] is String ? data['networkName'] : '정보 없음'),
              const SizedBox(height: 20),
              const Text('마지막 GPS 위치', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (latitude == null || longitude == null) ...[
                const Text('서버에 확인된 GPS 좌표가 없습니다.'),
              ] else ...[
                _value('위도', latitude.toStringAsFixed(6)),
                _value('경도', longitude.toStringAsFixed(6)),
                _value('측정 시각', locationDate == null ? '확인 불가' : _date(locationDate)),
                const SizedBox(height: 8),
                const SelectableText('좌표는 복사해 지도 앱에서 확인할 수 있습니다.'),
              ],
              const SizedBox(height: 24),
              const Text('긴급 상황 알림은 앱의 알림 탭에서 확인하세요. '
                  '현재 화면은 실시간 구조 요청을 보장하지 않습니다.',
                  style: TextStyle(color: AppTheme.muted)),
            ],
          );
        },
      ),
    );
  }

  static double? _coordinate(dynamic value) {
    if (value is num) return value.toDouble();
    return value is String ? double.tryParse(value) : null;
  }

  static String _date(DateTime date) =>
      '\u0024{date.year}-\u0024{date.month.toString().padLeft(2, '0')}-\u0024{date.day.toString().padLeft(2, '0')} '
      '\u0024{date.hour.toString().padLeft(2, '0')}:\u0024{date.minute.toString().padLeft(2, '0')}';

  static Widget _value(String label, String value) => ListTile(
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
