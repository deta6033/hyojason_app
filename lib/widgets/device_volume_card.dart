import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/firestore_service.dart';

/// 보호자 앱에서 기기의 목표 음량을 저장하는 카드.
/// ESP32가 이 설정을 읽고 적용하는 펌웨어는 별도로 구현해야 합니다.
class DeviceVolumeCard extends StatefulWidget {
  const DeviceVolumeCard({super.key});

  @override
  State<DeviceVolumeCard> createState() => _DeviceVolumeCardState();
}

class _DeviceVolumeCardState extends State<DeviceVolumeCard> {
  double? draft;
  bool saving = false;

  Future<void> _save(int level) async {
    setState(() => saving = true);
    try {
      await FirestoreService().saveTargetVolume(level);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('목표 음량을 저장했습니다. 실제 적용에는 ESP32 연동이 필요합니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음량 저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() { saving = false; draft = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().volumeSettings(),
      builder: (context, snapshot) {
        final stored = snapshot.data?.data()?['volumePercent'];
        final target = stored is num ? stored.toDouble().clamp(0.0, 100.0) : 25.0;
        final value = draft ?? target;
        return Card(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.volume_up_outlined, color: AppTheme.primary),
                SizedBox(width: 10),
                Text('효자손 스피커 목표 음량',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              Text('설정값: ${value.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: value,
                min: 0, max: 100, divisions: 20,
                label: '${value.round()}%',
                onChanged: saving || snapshot.hasError ? null
                    : (next) => setState(() => draft = next),
                onChangeEnd: saving || snapshot.hasError ? null
                    : (next) => _save(next.round()),
              ),
              if (saving) const LinearProgressIndicator(),
              if (snapshot.hasError)
                Text('음량 설정 조회 실패: ${snapshot.error}',
                    style: TextStyle(color: AppTheme.danger)),
              const Text('현재는 서버에 목표 음량을 저장하는 기능입니다. '
                  'ESP32가 설정을 수신하고 적용했다는 확인은 아직 지원하지 않습니다. '
                  '100%는 향후 기기에서 검증할 안전 최대 음량을 의미하며, '
                  '스피커를 무제한 출력하는 설정이 아닙니다.',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ],
          ),
        ));
      },
    );
  }
}
