import 'package:flutter/material.dart';

class AppThemeColors {
  final String name;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;

  const AppThemeColors({
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
  });

  static const royalViolet = AppThemeColors(
    name: 'Royal Violet',
    primary: Color(0xFF6366F1), // Indigo
    primaryLight: Color(0xFF818CF8),
    primaryDark: Color(0xFF4F46E5),
    accent: Color(0xFFD946EF), // Fuchsia
  );

  static const emeraldMint = AppThemeColors(
    name: 'Emerald Mint',
    primary: Color(0xFF10B981), // Emerald
    primaryLight: Color(0xFF34D399),
    primaryDark: Color(0xFF059669),
    accent: Color(0xFF06B6D4), // Cyan
  );

  static const oceanBreeze = AppThemeColors(
    name: 'Ocean Breeze',
    primary: Color(0xFF0284C7), // Sky Blue
    primaryLight: Color(0xFF38BDF8),
    primaryDark: Color(0xFF0369A1),
    accent: Color(0xFFF43F5E), // Rose
  );

  static const amberGold = AppThemeColors(
    name: 'Amber Gold',
    primary: Color(0xFFF59E0B), // Amber
    primaryLight: Color(0xFFFBBF24),
    primaryDark: Color(0xFFD97706),
    accent: Color(0xFFE11D48), // Rose
  );

  static const roseCrimson = AppThemeColors(
    name: 'Rose Crimson',
    primary: Color(0xFFE11D48), // Rose Red
    primaryLight: Color(0xFFFB7185),
    primaryDark: Color(0xFFBE123C),
    accent: Color(0xFF7C3AED), // Purple
  );

  static const customGradient = AppThemeColors(
    name: 'Custom Gradient',
    primary: Color(0xFF6366F1),
    primaryLight: Color(0xFF818CF8),
    primaryDark: Color(0xFF4F46E5),
    accent: Color(0xFFD946EF),
  );

  static const List<AppThemeColors> themes = [
    royalViolet,
    emeraldMint,
    oceanBreeze,
    amberGold,
    roseCrimson,
    customGradient,
  ];
}

/// A premium, state-of-the-art Design System & Theme Configuration
/// tailored for a responsive, modern UI experience.
/// Inspired by deep slate and vibrant violet/indigo color palettes.
class AppTheme {
  AppTheme._();

  static AppThemeColors currentThemeColors = AppThemeColors.royalViolet;

  static Color get primary => currentThemeColors.primary;
  static Color get primaryLight => currentThemeColors.primaryLight;
  static Color get primaryDark => currentThemeColors.primaryDark;
  static Color get accent => currentThemeColors.accent;

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF8FAFC); // Very light slate
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle gray border
  
  // Dark Theme Palette
  static const Color darkBg = Color(0xFF0F172A); // Rich slate dark background
  static const Color darkSurface = Color(0xFF1E293B); // Dark slate surface
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155); // Premium dark border
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Rose/Red
  static const Color info = Color(0xFF06B6D4); // Cyan
  
  // Neutral Text Colors (Light Mode)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
  
  // Neutral Text Colors (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);

  // --- DESIGN TOKENS: SHADOWS ---
  static List<BoxShadow> shadowLight = [
    BoxShadow(
      color: const Color(0xFF0F172A).withAlpha(10), // ~4% opacity
      offset: const Offset(0, 4),
      blurRadius: 20,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withAlpha(8), // ~3% opacity
      offset: const Offset(0, 10),
      blurRadius: 10,
      spreadRadius: -3,
    ),
  ];

  static List<BoxShadow> shadowDark = [
    BoxShadow(
      color: Colors.black.withAlpha(51), // ~20% opacity
      offset: const Offset(0, 10),
      blurRadius: 30,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: const Color(0xFF6366F1).withAlpha(13), // ~5% indigo glow
      offset: const Offset(0, 2),
      blurRadius: 10,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> glowAccent = [
    BoxShadow(
      color: accent.withAlpha(76), // ~30% opacity
      offset: const Offset(0, 8),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];

  // --- DESIGN TOKENS: BORDER RADIUS ---
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 9999.0;

  // --- DESIGN TOKENS: SPACING ---
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // --- LIGHT THEME DATA ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      dividerColor: lightBorder,
      fontFamily: 'Inter',
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: lightSurface,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        outline: lightBorder,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textPrimaryLight, letterSpacing: -1.2),
        displayMedium: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textPrimaryLight, letterSpacing: -1.0),
        displaySmall: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textPrimaryLight, letterSpacing: -0.8),
        headlineLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryLight, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryLight),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryLight),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textSecondaryLight),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimaryLight, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondaryLight, height: 1.5),
        bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textMutedLight),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.1),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: lightBorder, width: 1.0),
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primary.withAlpha(26), // 10%
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondaryLight, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: textSecondaryLight, fontSize: 12);
        }),
      ),

      // Input Decoration Theme (Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingMD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: const TextStyle(color: textMutedLight, fontSize: 14),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      
      iconTheme: const IconThemeData(color: textSecondaryLight),
    );
  }

  // --- DARK THEME DATA ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      dividerColor: darkBorder,
      fontFamily: 'Inter',
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: darkSurface,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        outline: darkBorder,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textPrimaryDark, letterSpacing: -1.2),
        displayMedium: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textPrimaryDark, letterSpacing: -1.0),
        displaySmall: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textPrimaryDark, letterSpacing: -0.8),
        headlineLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryDark, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryDark),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textSecondaryDark),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimaryDark, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondaryDark, height: 1.5),
        bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textMutedDark),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryLight, letterSpacing: 0.1),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primary.withAlpha(38), // ~15%
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryLight, size: 24);
          }
          return const IconThemeData(color: textSecondaryDark, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: primaryLight, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: textSecondaryDark, fontSize: 12);
        }),
      ),

      // Input Decoration Theme (Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingMD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: const TextStyle(color: textMutedDark, fontSize: 14),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      
      iconTheme: const IconThemeData(color: textSecondaryDark),
    );
  }
}
