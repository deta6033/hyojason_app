import 'package:flutter/material.dart';

// 앱 전체의 색상과 공통 테마를 한곳에서 관리합니다.
class AppTheme {
  static const Color primary = Color(0xFF4D8FF7);
  static const Color background = Color(0xFFF8FAFC);
  static const Color blueSoft = Color(0xFFEEF6FF);
  static const Color greenSoft = Color(0xFFF1F8F2);
  static const Color purpleSoft = Color(0xFFF3EFFF);
  static const Color orangeSoft = Color(0xFFFFF4E8);
  static const Color success = Color(0xFF62A86B);
  static const Color warning = Color(0xFFE89A3D);
  static const Color danger = Color(0xFFE26464);
  static const Color text = Color(0xFF303640);
  static const Color muted = Color(0xFF7D8793);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: const Color(0xFFDDEBFF),
        backgroundColor: Colors.white,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F5F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
