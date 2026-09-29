import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'demo_mode_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final guardian = state.guardian;
    final device = state.device;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('설정', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            const _SectionTitle('보호자 정보'),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.blueSoft,
                      child: Icon(Icons.person_rounded, color: AppTheme.primary),
                    ),
                    title: Text(guardian.guardianName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${guardian.elderName} 어르신 · ${guardian.relationship}'),
                    trailing: IconButton(
                      tooltip: '보호자 정보 수정',
                      onPressed: () => _editGuardian(context),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('보호자 알림', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('복약 및 중요 알림 받기'),
                    value: guardian.notificationEnabled,
                    onChanged: (value) => state.updateGuardian(guardian.copyWith(notificationEnabled: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const _SectionTitle('효자손 기기'),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.blueSoft, borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  _SettingRow(title: '연결 상태', value: device.connected ? '정상' : '연결 끊김'),
                  _SettingRow(title: '배터리', value: '${device.battery}%'),
                  _SettingRow(title: '네트워크', value: device.networkName),
                  _SettingRow(title: '기기 ID', value: device.deviceId),
                  _SettingRow(title: '마지막 동기화', value: formatKoreanTime(device.lastSync)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const _SectionTitle('서비스'),
            const SizedBox(height: 11),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary),
                    title: const Text('개인정보 및 데이터', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.science_outlined, color: AppTheme.primary),
                    title: const Text('시연 모드', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(state.demoScenario.displayName),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DemoModeScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const _SectionTitle('앱 정보'),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: const Column(
                children: [
                  _SettingRow(title: '앱 이름', value: AppConfig.appName),
                  _SettingRow(title: '버전', value: AppConfig.version),
                  _SettingRow(title: '데이터', value: '시연용 데이터'),
                  _SettingRow(title: '기기 연동', value: '시뮬레이션'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _resetApp(context),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('시제품 데이터 초기화'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGuardian(BuildContext context) async {
    final state = AppScope.of(context);
    final current = state.guardian;
    final guardianController = TextEditingController(text: current.guardianName);
    final elderController = TextEditingController(text: current.elderName);
    final relationController = TextEditingController(text: current.relationship);
    final phoneController = TextEditingController(text: current.phone);

    final result = await showDialog<GuardianSettings>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보호자 정보 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: guardianController, decoration: const InputDecoration(labelText: '보호자 이름')),
              const SizedBox(height: 11),
              TextField(controller: elderController, decoration: const InputDecoration(labelText: '어르신 이름')),
              const SizedBox(height: 11),
              TextField(controller: relationController, decoration: const InputDecoration(labelText: '관계')),
              const SizedBox(height: 11),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '보호자 연락처 (선택)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              current.copyWith(
                guardianName: guardianController.text.trim().isEmpty ? current.guardianName : guardianController.text.trim(),
                elderName: elderController.text.trim().isEmpty ? current.elderName : elderController.text.trim(),
                relationship: relationController.text.trim().isEmpty ? current.relationship : relationController.text.trim(),
                phone: phoneController.text.trim(),
              ),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    guardianController.dispose();
    elderController.dispose();
    relationController.dispose();
    phoneController.dispose();
    if (result != null) await state.updateGuardian(result);
  }

  Future<void> _resetApp(BuildContext context) async {
    final state = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시제품 데이터 초기화'),
        content: const Text('보호자 설정과 복약 일정, 알림 기록을 초기 상태로 되돌립니다. 계속할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('초기화')),
        ],
      ),
    );
    if (confirmed == true) await state.resetPrototype();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String value;

  const _SettingRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: AppTheme.muted))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
