import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';

abstract class AppTheme {
  // ─── 라이트 테마 ──────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.primaryHover,
          surface: AppColors.surfaceDefault,
          surfaceContainerHighest: AppColors.surfaceSubtle,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.bgDefault,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgTinted,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColors.borderSubtle,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgTinted,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textDisabled,
          type: BottomNavigationBarType.fixed,
          elevation: 1,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceSubtle,
          hintStyle: const TextStyle(color: AppColors.textDisabled),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primarySurface,
          selectedColor: AppColors.primary,
          labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderSubtle,
          thickness: 1,
          space: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDefault,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: AppColors.bgTinted,
          iconColor: AppColors.textSecondary,
          titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          subtitleTextStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        textTheme: const TextTheme(
          displayLarge:   TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
          bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
          bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
          labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
      );

  // ─── 다크 테마 ──────────────────────────────────────────────────────────────
  //  라이트의 라벤더 세계관을 "딥 퍼플 블랙"으로 반전
  //  Primary·Semantic 색상 불변, 배경·Surface·Text·Border만 재정의
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.primary,
          primary: AppColorsDark.primary,
          onPrimary: AppColorsDark.textOnPrimary,
          secondary: AppColorsDark.primaryHover,
          surface: AppColorsDark.surfaceDefault,
          surfaceContainerHighest: AppColorsDark.surfaceSubtle,
          error: AppColorsDark.error,
        ),
        scaffoldBackgroundColor: AppColorsDark.bgDefault,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColorsDark.bgTinted,
          foregroundColor: AppColorsDark.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColorsDark.borderSubtle,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColorsDark.textPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColorsDark.bgTinted,
          selectedItemColor: AppColorsDark.primary,
          unselectedItemColor: AppColorsDark.textDisabled,
          type: BottomNavigationBarType.fixed,
          elevation: 1,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColorsDark.surfaceSubtle,
          hintStyle: const TextStyle(color: AppColorsDark.textDisabled),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColorsDark.borderDefault, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColorsDark.borderDefault, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColorsDark.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsDark.primary,
            foregroundColor: AppColorsDark.textOnPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            elevation: 4,
            shadowColor: AppColorsDark.primary.withValues(alpha: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColorsDark.primaryHover,
            side: const BorderSide(color: AppColorsDark.primaryHover, width: 1.5),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColorsDark.primaryHover),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColorsDark.primarySurface,
          selectedColor: AppColorsDark.primary,
          labelStyle: const TextStyle(color: AppColorsDark.textPrimary, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppColorsDark.borderDefault),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColorsDark.borderSubtle,
          thickness: 1,
          space: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColorsDark.surfaceDefault,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColorsDark.borderSubtle),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: AppColorsDark.bgTinted,
          iconColor: AppColorsDark.textSecondary,
          titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColorsDark.textPrimary),
          subtitleTextStyle: TextStyle(fontSize: 12, color: AppColorsDark.textSecondary),
        ),
        textTheme: const TextTheme(
          displayLarge:   TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColorsDark.textPrimary),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColorsDark.textPrimary),
          titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
          bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColorsDark.textPrimary),
          bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColorsDark.textPrimary),
          bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColorsDark.textSecondary),
          labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
          labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColorsDark.textSecondary),
        ),
      );
}
