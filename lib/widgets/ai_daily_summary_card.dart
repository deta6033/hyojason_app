import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_theme.dart';
import '../services/firestore_service.dart';

/// 대화 내용을 근거로 서버에서 생성한 AI 하루 요약을 표시합니다.
/// Firebase ID 토큰으로 서버 요청을 인증합니다. 기기 비밀 토큰은 앱에 넣지 않습니다.
class AiDailySummaryCard extends StatefulWidget {
  const AiDailySummaryCard({super.key});

  @override
  State<AiDailySummaryCard> createState() => _AiDailySummaryCardState();
}

class _AiDailySummaryCardState extends State<AiDailySummaryCard> {
  bool generating = false;
  String? error;

  String get today {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _generate() async {
    setState(() { generating = true; error = null; });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('로그인이 필요합니다.');
      final response = await http.post(
        Uri.parse('https://hyojason-api-230429142822.asia-northeast3.run.app/summary'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'date': today}),
      ).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        String reason = '서버 요청 실패';
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map) {
            reason = (decoded['error'] ?? decoded['message'] ?? reason).toString();
          }
        } on FormatException {
          reason = '서버가 올바른 오류 응답을 보내지 않았습니다.';
        }
        throw StateError('$reason (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().dailySummary(today),
      builder: (context, snapshot) {
        final value = snapshot.data?.data();
        final summary = value?['summary'] as String?;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.greenSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCEFE3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: AppTheme.success),
                SizedBox(width: 10),
                Text('AI가 정리한 오늘',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: AppTheme.success)),
              ]),
              const SizedBox(height: 12),
              Text(summary == null || summary.isEmpty
                  ? '오늘 대화를 바탕으로 AI 요약을 생성할 수 있습니다. '
                      '대화가 없다면 생성되지 않습니다.'
                  : summary),
              if (snapshot.connectionState == ConnectionState.waiting) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (snapshot.hasError) ...[
                const SizedBox(height: 8),
                Text('요약 데이터 조회 실패: ${snapshot.error}',
                    style: TextStyle(color: AppTheme.danger)),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppTheme.danger)),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: generating ? null : _generate,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(generating ? '요약 생성 중...' :
                    (summary == null ? 'AI 하루 요약 만들기' : '요약 다시 만들기')),
              ),
              const SizedBox(height: 9),
              const Text('대화에 근거한 AI 생성 요약이며 실제 건강 상태나 복약 여부를 '
                  '보증하지 않습니다. 다시 만들기를 누르면 API 비용이 발생할 수 있습니다.',
                  style: TextStyle(fontSize: 11, color: AppTheme.muted)),
            ],
          ),
        );
      },
    );
  }
}
