import 'package:flutter/material.dart';

import '../utils/responsive.dart';

abstract final class AppColors {
  static const ink = Color(0xff101828);
  static const text = Color(0xff203044);
  static const muted = Color(0xff667085);
  static const primary = Color(0xff087d66);
  static const primaryDark = Color(0xff075b4b);
  static const primarySoft = Color(0xffedf8f4);
  static const primaryBorder = Color(0xffcde9df);
  static const accent = Color(0xffd79b43);
  static const page = Color(0xfff7f9f8);
  static const border = Color(0xffe1e8e4);
  static const purpleSoft = Color(0xffe9e7ff);
  static const error = Color(0xffb3261e);
}

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.page,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        surface: Colors.white,
        onSurface: AppColors.text,
        error: AppColors.error,
      ),
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.text, fontSize: 14, height: 1.45),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          height: 1.4,
        ),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.page,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: Color(0xff526170), fontSize: 12),
        hintStyle: const TextStyle(color: Color(0xff9aa5b1), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: Color(0xffcbd7d2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        height: 68,
        indicatorColor: AppColors.purpleSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.muted,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.white;
        }),
        side: const BorderSide(color: AppColors.muted),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xffe7ece9),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// สร้าง AppBar แบบ Safa สม่ำเสมอทุกหน้า
  /// [title] - ชื่อหน้า (optional)
  /// [showBackButton] - แสดงปุ่มย้อนกลับ (default: true เมื่อ navigator มี route ก่อนหน้า)
  static AppBar buildSafaAppBar(
    BuildContext context, {
    String? title,
    bool? showBackButton,
    List<Widget> actions = const [],
  }) {
    final canPop = Navigator.of(context).canPop();
    final showBack = showBackButton ?? canPop;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFFE4E7EC), height: 1.0),
      ),
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              tooltip: 'ย้อนกลับ',
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.ink, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      leadingWidth: showBack ? 48 : 56,
      title: title != null
          ? Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            )
          : null,
      actions: [
        ...actions,
        if (!showBack) ...[
          const SizedBox(width: 12),
        ],
      ],
    );
  }

  /// Returns a responsive version of the light theme.
  ///
  /// Scales typography and touch targets based on screen width.
  /// Usage: `theme: AppTheme.responsiveLight(context)`
  static ThemeData responsiveLight(BuildContext context) {
    final base = light;
    final scale = Responsive.fontScale(context);

    // Only apply scaling if scale != 1.0
    if (scale == 1.0) return base;

    final baseTextTheme = base.textTheme;

    return base.copyWith(
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 28 * scale,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 22 * scale,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 18 * scale,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 15 * scale,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 14 * scale,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 13 * scale,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 13 * scale,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          minimumSize: WidgetStatePropertyAll(
            Size.fromHeight(48 * scale),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          minimumSize: WidgetStatePropertyAll(
            Size.fromHeight(48 * scale),
          ),
        ),
      ),
    );
  }
}
