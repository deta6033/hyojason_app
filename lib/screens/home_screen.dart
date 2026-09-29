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
    final status = _status(state, record, device);
    final lastMessage =
        record.conversations.isEmpty ? null : record.conversations.last;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              guardianName: guardian.guardianName,
              connected: device.connected,
            ),
            const SizedBox(height: 24),
            Text(
              guardian.elderName + ' 어르신의\n오늘은 이래요',
              style: AppTheme.displayStyle,
            ),
            const SizedBox(height: 9),
            Text(
              formatKoreanDate(DateTime.now()),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 22),
            _OverallStatusCard(
              elderName: guardian.elderName,
              statusText: status.$1,
              statusColor: status.$2,
              statusMessage: status.$3,
              statusIcon: status.$4,
            ),
            const SizedBox(height: 30),
            const _SectionHeader(
              title: '오늘의 기록',
              subtitle: '대화에서 정리된 주요 생활 정보예요.',
            ),
            const SizedBox(height: 14),
            _DailyMetrics(record: record),
            const SizedBox(height: 30),
            _SectionHeader(
              title: 'AI 하루 요약',
              subtitle: '오늘의 핵심만 짧게 정리했어요.',
              actionText: '자세히',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailySummaryScreen(record: record),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SummaryCard(
              record: record,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailySummaryScreen(record: record),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _SectionHeader(
              title: '최근 AI 대화',
              subtitle: '보호자는 기록을 확인만 할 수 있어요.',
              actionText: '전체 보기',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiConversationScreen(record: record),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ConversationPreview(
              lastMessage: lastMessage,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiConversationScreen(record: record),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const _SectionHeader(
              title: '효자손 기기',
              subtitle: '연결 상태와 배터리를 확인해요.',
            ),
            const SizedBox(height: 14),
            _DeviceCard(device: device),
          ],
        ),
      ),
    );
  }

  (String, Color, String, IconData) _status(
    AppState state,
    DailyRecord record,
    DeviceStatus device,
  ) {
    if (!device.connected || state.demoScenario == DemoScenario.noConversation) {
      return (
        '주의',
        AppTheme.danger,
        !device.connected
            ? '효자손 기기 연결이 끊겼어요. 연결 상태를 확인해주세요.'
            : '최근 24시간 동안 새로운 대화가 확인되지 않았어요.',
        !device.connected
            ? Icons.link_off_rounded
            : Icons.mark_chat_unread_rounded,
      );
    }
    if (!record.medicine || device.battery <= 15) {
      return (
        '확인 필요',
        AppTheme.warning,
        !record.medicine
            ? '확인이 필요한 복약 기록이 있어요.'
            : '효자손 기기의 배터리가 부족해요.',
        !record.medicine
            ? Icons.medication_rounded
            : Icons.battery_alert_rounded,
      );
    }
    return (
      '안정적',
      AppTheme.success,
      '식사·복약·대화 기록에서 특별한 이상 징후가 없어요.',
      Icons.favorite_rounded,
    );
  }
}

class _TopBar extends StatelessWidget {
  final String guardianName;
  final bool connected;

  const _TopBar({required this.guardianName, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            'assets/app_icon.png',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppConfig.appName,
                style: TextStyle(
                  fontFamily: AppTheme.titleFont,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                guardianName + ' 보호자님',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _ConnectionPill(connected: connected),
      ],
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final bool connected;
  const _ConnectionPill({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppTheme.success : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: connected ? AppTheme.greenSoft : AppTheme.redSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? '기기 연결됨' : '연결 끊김',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallStatusCard extends StatelessWidget {
  final String elderName;
  final String statusText;
  final Color statusColor;
  final String statusMessage;
  final IconData statusIcon;

  const _OverallStatusCard({
    required this.elderName,
    required this.statusText,
    required this.statusColor,
    required this.statusMessage,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF2FF), Color(0xFFF8FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE8FF)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elderName + ' 어르신 오늘 상태',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: AppTheme.titleFont,
                        fontSize: 24,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            statusMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF59677B),
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}

class _DailyMetrics extends StatelessWidget {
  final DailyRecord record;
  const _DailyMetrics({required this.record});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              width: itemWidth,
              icon: Icons.restaurant_rounded,
              color: AppTheme.primary,
              softColor: AppTheme.blueSoft,
              title: '식사',
              value: record.meal ? '완료' : '확인 필요',
            ),
            _MetricCard(
              width: itemWidth,
              icon: Icons.medication_rounded,
              color: const Color(0xFF8066D8),
              softColor: AppTheme.purpleSoft,
              title: '복약',
              value: record.medicine ? '완료' : '미확인',
            ),
            _MetricCard(
              width: itemWidth,
              icon: Icons.directions_walk_rounded,
              color: AppTheme.success,
              softColor: AppTheme.greenSoft,
              title: '외출',
              value: record.outing ? '있음' : '없음',
            ),
            _MetricCard(
              width: itemWidth,
              icon: Icons.sentiment_satisfied_alt_rounded,
              color: AppTheme.warning,
              softColor: AppTheme.orangeSoft,
              title: '기분',
              value: record.mood,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color color;
  final Color softColor;
  final String title;
  final String value;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DailyRecord record;
  final VoidCallback onTap;

  const _SummaryCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.greenSoft,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDCEFE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppTheme.success,
                ),
                SizedBox(width: 7),
                Text(
                  'AI가 정리한 오늘',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4F5D55),
                    height: 1.65,
                  ),
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '자세히 보기',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: AppTheme.primaryDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationPreview extends StatelessWidget {
  final ConversationMessage? lastMessage;
  final VoidCallback onTap;

  const _ConversationPreview({required this.lastMessage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: lastMessage == null
            ? const Row(
                children: [
                  _RoundIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    background: AppTheme.redSoft,
                    color: AppTheme.danger,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '최근 24시간 동안 새로운 대화가 없어요.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RoundIcon(
                    icon: Icons.favorite_rounded,
                    background: AppTheme.blueSoft,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '최근 대화',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              formatKoreanTime(lastMessage!.time),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '“' + lastMessage!.text + '”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: const Color(0xFF5A6472)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.muted,
                  ),
                ],
              ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceStatus device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final lowBattery = device.battery <= 15;
    final stateColor = !device.connected
        ? AppTheme.danger
        : lowBattery
            ? AppTheme.warning
            : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _RoundIcon(
            icon: Icons.memory_rounded,
            background:
                device.connected ? AppTheme.greenSoft : AppTheme.redSoft,
            color: stateColor,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.connected ? '정상 연결' : '연결 끊김',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '배터리 ' +
                      device.battery.toString() +
                      '% · ' +
                      device.networkName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              device.battery.toString() + '%',
              style: TextStyle(
                color: stateColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;

  const _RoundIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.sectionTitleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (actionText != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(actionText!)),
      ],
    );
  }
}
