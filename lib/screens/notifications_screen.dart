import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final notifications = [...state.notifications]..sort((a, b) => b.time.compareTo(a.time));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('알림', style: AppTheme.displayStyle),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                if (state.unreadNotificationCount > 0)
                  TextButton(onPressed: state.markAllNotificationsRead, child: const Text('모두 읽음')),
              ],
            ),
            Text(
              state.unreadNotificationCount == 0 ? '새로운 알림이 없습니다.' : '읽지 않은 알림 ${state.unreadNotificationCount}개',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(child: Text('알림이 없습니다.', style: TextStyle(color: AppTheme.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => state.markNotificationRead(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: item.read ? Colors.white : AppTheme.blueSoft,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: item.read ? AppTheme.border : const Color(0xFFDDE8FF)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _NotificationIcon(type: item.type),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(fontWeight: item.read ? FontWeight.w700 : FontWeight.w900),
                                            ),
                                          ),
                                          if (!item.read)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(item.message, style: const TextStyle(height: 1.4, color: Color(0xFF666D76))),
                                      const SizedBox(height: 8),
                                      Text(_relativeTime(item.time), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return formatKoreanDate(time);
  }
}

class _NotificationIcon extends StatelessWidget {
  final AppNotificationType type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground) = switch (type) {
      AppNotificationType.medicine => (Icons.medication_rounded, AppTheme.purpleSoft, const Color(0xFF755FD5)),
      AppNotificationType.warning => (Icons.warning_rounded, AppTheme.orangeSoft, AppTheme.warning),
      AppNotificationType.device => (Icons.memory_rounded, AppTheme.greenSoft, AppTheme.success),
      AppNotificationType.summary => (Icons.auto_awesome_rounded, AppTheme.blueSoft, AppTheme.primary),
    };
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: foreground),
    );
  }
}
