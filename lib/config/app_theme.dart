import 'package:flutter/material.dart';

// 효자손의 디자인 토큰을 한곳에서 관리합니다.
// 잘난체 파일을 프로젝트에 추가하면 아래 fontFamily 값이 자동으로 적용됩니다.
class AppTheme {
  static const String titleFont = 'Jalnan';
  static const String bodyFont = 'JalnanGothic';

  static const Color primary = Color(0xFF4A7CF3);
  static const Color primaryDark = Color(0xFF2E5FD2);
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color blueSoft = Color(0xFFEDF4FF);
  static const Color greenSoft = Color(0xFFEDF8F1);
  static const Color purpleSoft = Color(0xFFF3EFFF);
  static const Color orangeSoft = Color(0xFFFFF4E7);
  static const Color redSoft = Color(0xFFFFECEC);
  static const Color success = Color(0xFF45A56A);
  static const Color warning = Color(0xFFE99732);
  static const Color danger = Color(0xFFE45E62);
  static const Color text = Color(0xFF252B37);
  static const Color muted = Color(0xFF7A8494);
  static const Color border = Color(0xFFE8EBF1);

  static const double pagePadding = 20;
  static const double cardRadius = 24;

  static TextStyle get displayStyle => const TextStyle(
        fontFamily: titleFont,
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: text,
      );

  static TextStyle get sectionTitleStyle => const TextStyle(
        fontFamily: titleFont,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        color: text,
      );

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: bodyFont,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        displayLarge: displayStyle.copyWith(fontSize: 34),
        displayMedium: displayStyle,
        headlineLarge: displayStyle.copyWith(fontSize: 28),
        headlineMedium: sectionTitleStyle.copyWith(fontSize: 22),
        titleLarge: const TextStyle(
          fontFamily: titleFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.25,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.2,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          height: 1.55,
          color: text,
          letterSpacing: -0.15,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: text,
          letterSpacing: -0.1,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          height: 1.45,
          color: muted,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: titleFont,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        indicatorColor: blueSoft,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primaryDark : muted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: Color(0xFFAAB1BC)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? blueSoft : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? primaryDark : muted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x0D202A44),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ];
}
