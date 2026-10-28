import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/firestore_service.dart';

/// 보호자가 선택한 AI 음성 종류를 Firebase에 저장합니다.
/// 서버의 /tts가 이후 요청부터 이 설정을 사용합니다.
class DeviceVoiceCard extends StatefulWidget {
  const DeviceVoiceCard({super.key});

  @override
  State<DeviceVoiceCard> createState() => _DeviceVoiceCardState();
}

class _DeviceVoiceCardState extends State<DeviceVoiceCard> {
  bool saving = false;
  static const voices = <String, String>{
    'alloy': '기본 목소리',
    'nova': '밝고 부드러운 목소리',
    'shimmer': '차분한 목소리',
  };

  Future<void> _save(String value) async {
    setState(() => saving = true);
    try {
      await FirestoreService().saveTTSVoice(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 목소리 설정을 저장했습니다. 다음 음성 생성부터 적용됩니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().voiceSettings(),
      builder: (context, snapshot) {
        final stored = snapshot.data?.data()?['voice'];
        final selected = stored is String && voices.containsKey(stored)
            ? stored : 'alloy';
        return Card(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.record_voice_over_outlined, color: AppTheme.primary),
                SizedBox(width: 10),
                Text('AI 목소리 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '효자손 응답 목소리'),
                items: voices.entries.map((item) => DropdownMenuItem(
                  value: item.key, child: Text(item.value),
                )).toList(),
                onChanged: saving || snapshot.hasError ? null : (value) {
                  if (value != null && value != selected) _save(value);
                },
              ),
              if (saving) const LinearProgressIndicator(),
              if (snapshot.hasError)
                const Text('설정 데이터 조회 실패. Firebase 권한 규칙을 확인해 주세요.',
                    style: TextStyle(color: AppTheme.danger)),
              const SizedBox(height: 10),
              const Text('OpenAI의 기본 제공 음색 중 선택합니다. '
                  '어르신 또는 가족의 실제 목소리를 복제하는 기능은 아닙니다.',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ],
          ),
        ));
      },
    );
  }
}
