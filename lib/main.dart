import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/local_storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState(storage: LocalStorageService());
  await appState.initialize();

  runApp(
    AppScope(
      notifier: appState,
      child: const HyojaSonApp(),
    ),
  );
}

class HyojaSonApp extends StatelessWidget {
  const HyojaSonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.theme,
      home: state.onboardingComplete ? const MainShell() : const OnboardingScreen(),
    );
  }
}
