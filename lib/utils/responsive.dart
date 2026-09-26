import 'package:flutter/material.dart';

/// Responsive utility class for Safa Qard app.
///
/// Breakpoints (based on screen width):
/// - Mobile:        320–480px
/// - Large Mobile:  481–768px
/// - Tablet:        769–1024px
/// - Laptop:        1025–1440px
/// - Large Screen:  1441px+
abstract final class Responsive {
  // ============================================================
  // Breakpoints
  // ============================================================

  static const double mobileMax = 480;
  static const double tabletSmallMax = 768;
  static const double tabletMax = 1024;
  static const double laptopMax = 1440;

  // ============================================================
  // Device type detection
  // ============================================================

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMax;

  static bool isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMax && width <= tabletSmallMax;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > tabletSmallMax && width <= tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > tabletMax;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > laptopMax;

  // ============================================================
  // Responsive value selection (mobile-first)
  // ============================================================

  /// Returns a value based on the current screen width.
  ///
  /// [mobile] is the default value (mobile-first).
  /// [largeMobile], [tablet], [desktop] override progressively
  /// for wider screens (like CSS min-width media queries).
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? largeMobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width > tabletMax) return desktop ?? tablet ?? largeMobile ?? mobile;
    if (width > tabletSmallMax) return tablet ?? largeMobile ?? mobile;
    if (width > mobileMax) return largeMobile ?? mobile;
    return mobile;
  }

  // ============================================================
  // Content max width (for centering on large screens)
  // ============================================================

  /// Maximum width for main content areas.
  ///
  /// On mobile, content uses full width.
  /// On larger screens, content is constrained to keep it readable.
  static double contentMaxWidth(BuildContext context) {
    return value<double>(
      context,
      mobile: double.infinity,
      largeMobile: 600,
      tablet: 700,
      desktop: 800,
    );
  }

  /// Maximum width for form content (login, register, etc.).
  static double formMaxWidth(BuildContext context) {
    return value<double>(
      context,
      mobile: double.infinity,
      largeMobile: 480,
      tablet: 520,
      desktop: 520,
    );
  }

  // ============================================================
  // Responsive spacing & padding
  // ============================================================

  /// Horizontal padding for page content.
  static double horizontalPadding(BuildContext context) {
    return value<double>(
      context,
      mobile: 16,
      largeMobile: 24,
      tablet: 32,
      desktop: 40,
    );
  }

  // ============================================================
  // Responsive font scale
  // ============================================================

  /// Returns a scale factor for typography.
  ///
  /// On larger screens, text can be slightly bigger
  /// to maintain readability.
  static double fontScale(BuildContext context) {
    return value<double>(
      context,
      mobile: 1.0,
      largeMobile: 1.0,
      tablet: 1.05,
      desktop: 1.1,
    );
  }

  /// Returns a scaled font size.
  static double fontSize(BuildContext context, double base) {
    return base * fontScale(context);
  }

  // ============================================================
  // Grid columns helper
  // ============================================================

  /// Returns the number of columns for grid layouts.
  static int gridColumns(BuildContext context) {
    return value<int>(
      context,
      mobile: 2,
      largeMobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }
}
