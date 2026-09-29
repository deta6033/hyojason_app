import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/models.dart';

class DailySummaryScreen extends StatelessWidget {
  final DailyRecord record;

  const DailySummaryScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(formatKoreanDate(record.date))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('하루 요약', style: AppTheme.displayStyle),
            const SizedBox(height: 6),
            const Text('AI가 어르신의 오늘을 돌봄 정보 중심으로 정리했어요.', style: TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.75,
              children: [
                _SummaryStatus(icon: Icons.restaurant_rounded, title: '식사', value: record.meal ? '완료' : '확인 필요'),
                _SummaryStatus(icon: Icons.medication_rounded, title: '복약', value: record.medicine ? '완료' : '확인 필요'),
                _SummaryStatus(icon: Icons.directions_walk_rounded, title: '외출', value: record.outing ? '있음' : '없음'),
                _SummaryStatus(icon: Icons.sentiment_satisfied_alt_rounded, title: '기분', value: record.mood),
              ],
            ),
            const SizedBox(height: 24),
            _TextCard(title: '오늘 하루', text: record.summary, background: AppTheme.blueSoft),
            const SizedBox(height: 14),
            _TextCard(title: 'AI 한마디', text: record.aiComment, background: AppTheme.greenSoft),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('대화 기록', style: AppTheme.sectionTitleStyle),
                Text('${record.conversations.length}개', style: const TextStyle(color: AppTheme.muted)),
              ],
            ),
            const SizedBox(height: 12),
            if (record.conversations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.border)),
                child: const Text('이날 기록된 대화가 없습니다.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
              )
            else
              ...record.conversations.map(
                (message) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: message.isAi ? AppTheme.blueSoft : AppTheme.purpleSoft,
                    child: Icon(message.isAi ? Icons.favorite_rounded : Icons.person_rounded, size: 19),
                  ),
                  title: Text(message.isAi ? '효자손 AI' : '어르신', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(message.text),
                  trailing: Text(formatKoreanTime(message.time), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AiConversationScreen extends StatelessWidget {
  final DailyRecord record;

  const AiConversationScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('AI 대화 기록')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFDCEEFF),
                    child: Icon(Icons.favorite_rounded, color: AppTheme.primary),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('효자손 AI', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('어르신과의 대화를 보호자가 확인하는 화면입니다.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: record.conversations.isEmpty
                ? const Center(child: Text('최근 대화 기록이 없습니다.', style: TextStyle(color: AppTheme.muted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                    itemCount: record.conversations.length,
                    itemBuilder: (context, index) => _ChatBubble(message: record.conversations[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ConversationMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isAi ? Colors.white : AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: message.isAi ? AppTheme.text : Colors.white, height: 1.45),
            ),
            const SizedBox(height: 6),
            Text(
              formatKoreanTime(message.time),
              style: TextStyle(fontSize: 10, color: message.isAi ? Colors.grey : Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryStatus({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String title;
  final String text;
  final Color background;

  const _TextCard({required this.title, required this.text, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          Text(text, style: const TextStyle(height: 1.6, color: Color(0xFF58636D))),
        ],
      ),
    );
  }
}
