import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final guardianController = TextEditingController();
  final elderController = TextEditingController();
  final relationshipController = TextEditingController(text: '자녀');
  bool saving = false;

  @override
  void dispose() {
    guardianController.dispose();
    elderController.dispose();
    relationshipController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final guardian = guardianController.text.trim();
    final elder = elderController.text.trim();
    final relationship = relationshipController.text.trim();
    if (guardian.isEmpty || elder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보호자 이름과 어르신 이름을 입력해주세요.')),
      );
      return;
    }
    setState(() => saving = true);
    await AppScope.of(context).completeOnboarding(
      guardianName: guardian,
      elderName: elder,
      relationship: relationship.isEmpty ? '보호자' : relationship,
    );
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset('assets/app_icon.png', width: 104, height: 104),
                  ),
                  const SizedBox(height: 20),
                  const Text(AppConfig.appName, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  const Text(AppConfig.appSubtitle, style: TextStyle(color: AppTheme.muted, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text(
                    '부모님의 하루를 한눈에 확인하고\n복약과 안부를 더 편하게 챙겨보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.5, color: Color(0xFF596675)),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('보호자 정보 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text('설정 화면에서 언제든 수정할 수 있어요.', style: TextStyle(color: AppTheme.muted)),
                        const SizedBox(height: 22),
                        TextField(controller: guardianController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: '보호자 이름', hintText: '예: 김민수')),
                        const SizedBox(height: 13),
                        TextField(controller: elderController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: '어르신 이름', hintText: '예: 김영자')),
                        const SizedBox(height: 13),
                        TextField(controller: relationshipController, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: '관계', hintText: '예: 자녀')),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: saving ? null : _start,
                            child: saving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('효자손 시작하기', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.muted),
                      SizedBox(width: 5),
                      Text('시제품에서는 입력한 정보를 기기 내부에만 저장합니다.', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
