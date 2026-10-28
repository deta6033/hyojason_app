import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart'; // flutterfire configure 생성
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'screens/auth_screen.dart';
import 'services/push_service.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/local_storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 각 Android/Web 앱 ID와 API 옵션은 FlutterFire CLI가 자동 생성한다.
  // Android에서 네이티브 Firebase가 이미 등록된 경우 중복 초기화를 방지합니다.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // Firebase 기본 앱이 이미 존재하는 상태라면 기존 인스턴스를 사용합니다.
    Firebase.app();
    debugPrint('[Firebase] 기본 앱이 이미 초기화되어 기존 앱을 사용합니다.');
  }
  final state = AppState(storage: LocalStorageService());
  await state.initialize();
  // Android에서만 FCM 토큰을 등록하고 갱신합니다.
  await PushService.instance.initialize();
  runApp(AppScope(notifier: state, child: const HyojaSonApp()));
}

class HyojaSonApp extends StatelessWidget {
  const HyojaSonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) return const AuthScreen();
          return const _GuardianGate();
        },
      ),
    );
  }
}

// 로그인 이후 등록된 UID만 Firestore의 실제 대화 기록을 읽도록 허용
class _GuardianGate extends StatefulWidget {
  const _GuardianGate();
  @override
  State<_GuardianGate> createState() => _GuardianGateState();
}
class _GuardianGateState extends State<_GuardianGate> {
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    // 첫 프레임 빌드 중 notifyListeners()가 호출되지 않도록 지연합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.of(context).startLive();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('효자손 연결 확인')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: state.startLive, child: const Text('다시 연결')),
            TextButton(onPressed: () async {
              await state.stopLive();
              await FirebaseAuth.instance.signOut();
            }, child: const Text('로그아웃')),
          ]),
        )),
      );
    }
    if (!state.liveReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return state.onboardingComplete ? const MainShell() : const OnboardingScreen();
  }
}
