import 'package:flutter/material.dart';

/// A production-grade responsive layout manager.
/// Defines standardized breakpoints and exposes static query helpers
/// for writing adaptive and platform-agnostic UIs.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget tabletBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.tabletBody,
    required this.desktopBody,
  });

  // --- BREAKPOINTS ---
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;

  // --- STATIC HELPERS ---
  
  /// Checks if screen width is within mobile breakpoint (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileMax;
  }

  /// Checks if screen width is within tablet breakpoint (>= 600px and < 1024px)
  static bool isTablet(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width < tabletMax;
  }

  /// Checks if screen width is within desktop breakpoint (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletMax;
  }

  /// Gets correct value based on active device screen size
  static T valueFor<T>({
    required BuildContext context,
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return mobile;
    if (width < tabletMax) return tablet;
    return desktop;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletMax) {
          return desktopBody;
        } else if (constraints.maxWidth >= mobileMax) {
          return tabletBody;
        } else {
          return mobileBody;
        }
      },
    );
  }
}
