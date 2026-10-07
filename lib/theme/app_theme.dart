import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xff007f78);
  static const ink = Color(0xff17283f);
  static const muted = Color(0xff65758c);
  static const canvas = Color(0xfff5f7fa);
  static const line = Color(0xffe4e9ef);
  static const tint = Color(0xffe0f5f1);
  static const sidebar = Color(0xff101c30);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onSurface: AppColors.ink,
      surface: Colors.white,
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: base.textTheme
        .copyWith(
          headlineMedium: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -.7,
            color: AppColors.ink,
          ),
          headlineSmall: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -.4,
            color: AppColors.ink,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 19,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
            color: AppColors.ink,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            height: 1.5,
            color: AppColors.ink,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            height: 1.4,
            color: AppColors.muted,
          ),
        )
        .apply(fontFamily: 'Roboto'),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xfff8fafc),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppColors.muted,
        fontSize: 13,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppColors.muted,
        fontSize: 13,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.line),
        backgroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    chipTheme: ChipThemeData(
      side: const BorderSide(color: AppColors.line),
      backgroundColor: Colors.white,
      selectedColor: AppColors.tint,
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      indicatorColor: AppColors.tint,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.tint,
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 350),
    ),
  );
}
