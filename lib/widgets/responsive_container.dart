import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Wraps content with a max-width constraint and centers it.
///
/// On mobile, content takes full width.
/// On tablet/desktop, content is constrained and centered
/// to prevent it from stretching uncomfortably wide.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;

  /// If provided, overrides the default [Responsive.contentMaxWidth].
  final double? maxWidth;

  /// Optional padding to apply inside the container.
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? Responsive.contentMaxWidth(context);

    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    // On mobile (maxWidth == infinity), no constraint is applied
    if (effectiveMaxWidth == double.infinity) {
      return content;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: content,
      ),
    );
  }
}

/// A scaffold body wrapper that adds responsive max-width centering.
///
/// Use this to wrap the body of a Scaffold to make it responsive.
///
/// Example:
/// ```dart
/// Scaffold(
///   body: ResponsiveBody(
///     child: SingleChildScrollView(
///       child: Column(children: [...]),
///     ),
///   ),
/// )
/// ```
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? Responsive.contentMaxWidth(context);

    if (effectiveMaxWidth == double.infinity) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}
