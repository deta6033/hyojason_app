import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 및 데이터')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: const [
          _NoticeCard(
            icon: Icons.mic_off_rounded,
            title: '음성 원본 장기 저장 안 함',
            text: '제품화 단계에서는 음성 처리가 끝난 뒤 원본 음성을 장기간 보관하지 않는 것을 기본 원칙으로 설계합니다.',
          ),
          SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.summarize_rounded,
            title: '필요한 요약만 보호자에게',
            text: '보호자에게는 식사, 복약, 외출, 기분 등 돌봄에 필요한 정보와 하루 요약을 전달하는 방향입니다.',
          ),
          SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.notifications_active_outlined,
            title: '녹음 안내',
            text: '실제 효자손 기기에서는 녹음이 시작될 때 안내음을 재생하고 사용자가 기록을 중지할 수 있도록 설계할 예정입니다.',
          ),
          SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.health_and_safety_outlined,
            title: '건강 정보 안내',
            text: '효자손의 상태와 AI 요약은 보호자의 돌봄을 돕기 위한 참고 정보이며 의료 진단이나 응급 판단을 대신하지 않습니다.',
          ),
          SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.science_outlined,
            title: '현재는 시제품',
            text: '현재 앱의 AI 대화와 기기 상태는 창업경진대회 시연용 데이터입니다. 실제 하드웨어와 AI 서버는 추후 연결할 수 있도록 구조를 분리했습니다.',
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _NoticeCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppTheme.blueSoft, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 7),
                Text(text, style: const TextStyle(height: 1.55, color: Color(0xFF68717C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
