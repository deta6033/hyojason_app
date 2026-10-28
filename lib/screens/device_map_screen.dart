import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_theme.dart';
import '../services/firestore_service.dart';

/// 보호자에게 기기의 마지막 GPS 보고 위치를 표시합니다.
/// 위치가 없을 때 임의 좌표를 표시하지 않습니다.
class DeviceMapScreen extends StatelessWidget {
  const DeviceMapScreen({super.key});

  static double? _coordinate(dynamic value, double min, double max) {
    final result = value is num ? value.toDouble() :
        (value is String ? double.tryParse(value) : null);
    return result != null && result.isFinite && result >= min && result <= max
        ? result : null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().deviceStatus(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('GPS 정보를 읽지 못했습니다. 연결 및 권한을 확인해 주세요.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final raw = data['location'];
          final location = raw is Map ? raw : const <String, dynamic>{};
          final lat = _coordinate(location['latitude'] ?? location['lat'] ?? data['latitude'], -90, 90);
          final lon = _coordinate(location['longitude'] ?? location['lng'] ?? data['longitude'], -180, 180);
          final position = lat == null || lon == null ? null : LatLng(lat, lon);
          final seen = location['updatedAt'] ?? data['lastSeenAt'];
          final updatedAt = seen is Timestamp ? seen.toDate().toLocal() : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('효자손 지도', style: AppTheme.displayStyle),
              const SizedBox(height: 7),
              const Text('기기가 서버에 보고한 마지막 GPS 위치입니다.',
                  style: TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 18),
              if (position == null)
                Container(
                  height: 330,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.blueSoft,
                    borderRadius: BorderRadius.circular(24)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined, size: 56, color: AppTheme.primary),
                      SizedBox(height: 16),
                      Text('아직 GPS 위치가 없습니다',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('기기에서 위치 정보를 전송하면 이곳에 지도가 표시됩니다.',
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 350,
                    child: FlutterMap(
                      key: ValueKey('${lat}_${lon}'),
                      options: MapOptions(initialCenter: position, initialZoom: 15),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.hyojason_app',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: position,
                            width: 54,
                            height: 54,
                            child: const Icon(Icons.location_on_rounded,
                                size: 50, color: AppTheme.primary),
                          ),
                        ]),
                        RichAttributionWidget(attributions: [
                          TextSourceAttribution('OpenStreetMap contributors'),
                        ]),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('마지막 위치 정보',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(position == null ? '위도·경도: 미확인'
                        : '위도 ${lat!.toStringAsFixed(6)} / 경도 ${lon!.toStringAsFixed(6)}'),
                    const SizedBox(height: 6),
                    Text(updatedAt == null ? '보고 시각: 미확인'
                        : '보고 시각: ${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')} '
                          '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}'),
                    const SizedBox(height: 12),
                    const Text('실시간 추적이 아닌 마지막 보고 위치입니다. '
                        'GPS 수신 환경과 기기 연결 상태에 따라 정확도와 갱신 시간이 달라집니다.',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}
