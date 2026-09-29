import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class DemoModeScreen extends StatelessWidget {
  const DemoModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('시연 모드')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppTheme.orangeSoft, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.warning),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '현재 라즈베리파이와 AI 서버가 연결되지 않은 상태에서 실제 상황을 가정해 앱의 반응을 보여주는 발표용 기능입니다.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...DemoScenario.values.map((scenario) {
            final selected = state.demoScenario == scenario;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                tileColor: selected ? AppTheme.blueSoft : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: Text(scenario.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(scenario.description),
                ),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                    : const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await state.setDemoScenario(scenario);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${scenario.displayName}으로 변경했습니다.')),
                    );
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await state.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('실제 Android/iPhone에서 테스트 알림을 요청했습니다.')),
                );
              }
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('휴대폰 시스템 알림 테스트'),
          ),
        ],
      ),
    );
  }
}
