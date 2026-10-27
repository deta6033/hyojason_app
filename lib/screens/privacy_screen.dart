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
            text: '현재 ESP32는 2초 녹음 데이터를 Cloud Run으로 전송합니다. 녹음 파일의 보관 정책은 서버에서 별도 검증이 필요합니다.',
          ),
          SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.summarize_rounded,
            title: '필요한 요약만 보호자에게',
            text: '현재 앱은 실제 질문과 AI 답변만 Firestore에서 읽습니다. 생활 데이터 요약은 아직 구현되지 않았습니다.',
          ),
          SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.notifications_active_outlined,
            title: '녹음 안내',
            text: '현재 ESP32에서는 버튼으로 2초 녹음을 시작합니다. 안내음과 녹음 취소는 아직 구현되지 않았습니다.',
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
            text: '대화 기록은 실제 Cloud Run과 Firebase에서 불러옵니다. 기기 상태·배터리·GPS·긴급호출은 서버 연동 전까지 확인할 수 없습니다.',
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
