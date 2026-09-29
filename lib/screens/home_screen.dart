import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'detail_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final record = state.todayRecord;
    final device = state.device;
    final guardian = state.guardian;

    final (statusText, statusColor, statusMessage) = _status(state, record, device);
    final lastMessage = record.conversations.isEmpty ? null : record.conversations.last;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/app_icon.png', width: 52, height: 52),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConfig.appName,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(AppConfig.appSubtitle, style: TextStyle(color: AppTheme.muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: device.connected ? AppTheme.greenSoft : const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        device.connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        size: 15,
                        color: device.connected ? AppTheme.success : AppTheme.danger,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        device.connected ? '연결됨' : '연결 끊김',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF4FF), Color(0xFFF5FAFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${guardian.elderName} 어르신',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 7),
                            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(statusMessage, style: const TextStyle(color: Color(0xFF5F6D7A), height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('오늘의 기록', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 13),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.65,
              children: [
                _StatusCard(
                  icon: Icons.restaurant_rounded,
                  title: '식사',
                  value: record.meal ? '완료' : '확인 필요',
                  background: AppTheme.blueSoft,
                ),
                _StatusCard(
                  icon: Icons.medication_rounded,
                  title: '복약',
                  value: record.medicine ? '완료' : '미확인',
                  background: AppTheme.purpleSoft,
                ),
                _StatusCard(
                  icon: Icons.directions_walk_rounded,
                  title: '외출',
                  value: record.outing ? '있음' : '없음',
                  background: AppTheme.greenSoft,
                ),
                _StatusCard(
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  title: '기분',
                  value: record.mood,
                  background: AppTheme.orangeSoft,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: '오늘의 요약',
              actionText: '자세히',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DailySummaryScreen(record: record)),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DailySummaryScreen(record: record)),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.greenSoft, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 19, color: AppTheme.success),
                        SizedBox(width: 8),
                        Text('AI 하루 요약', style: TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(record.summary, style: const TextStyle(height: 1.6, color: Color(0xFF4E5A64))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'AI 대화 기록',
              actionText: '전체 보기',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AiConversationScreen(record: record)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EBF0)),
              ),
              child: lastMessage == null
                  ? const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFFFEFEF),
                          child: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.danger),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('최근 24시간 동안 새로운 대화가 없어요.', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE7F2FF),
                              child: Icon(Icons.favorite_rounded, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('최근 대화', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            Text(formatKoreanTime(lastMessage.time), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('“${lastMessage.text}”', style: const TextStyle(height: 1.5, color: Color(0xFF5D646D))),
                      ],
                    ),
            ),
            const SizedBox(height: 28),
            const Text('효자손 기기', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EBF0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: device.connected ? AppTheme.greenSoft : const Color(0xFFFFEEEE),
                    child: Icon(Icons.memory_rounded, color: device.connected ? AppTheme.success : AppTheme.danger),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.connected ? '정상 연결' : '연결 끊김', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          '배터리 ${device.battery}% · ${device.networkName}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    device.connected ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: device.connected ? AppTheme.success : AppTheme.danger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, String) _status(AppState state, DailyRecord record, DeviceStatus device) {
    if (!device.connected || state.demoScenario == DemoScenario.noConversation) {
      return (
        '주의',
        AppTheme.danger,
        !device.connected ? '효자손 기기 연결 상태를 확인해주세요.' : '최근 24시간 동안 대화가 없어요.',
      );
    }
    if (!record.medicine || device.battery <= 15) {
      return (
        '확인 필요',
        AppTheme.warning,
        !record.medicine ? '확인이 필요한 복약 기록이 있어요.' : '효자손 기기의 배터리가 부족해요.',
      );
    }
    return ('안정적', AppTheme.success, '현재 특별한 이상 징후가 없어요.');
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color background;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: AppTheme.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.actionText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        TextButton(onPressed: onTap, child: Text(actionText)),
      ],
    );
  }
}
