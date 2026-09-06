import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

enum AppThemeMode { light, dark, blue, oled }

class AppColors {
  // Static colors (don't change with theme)
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Category colors
  static const Color catRed = Color(0xFFEF4444);
  static const Color catBlue = Color(0xFF3B82F6);
  static const Color catGreen = Color(0xFF10B981);
  static const Color catPurple = Color(0xFF8B5CF6);
  static const Color catPink = Color(0xFFEC4899);
  static const Color catTeal = Color(0xFF14B8A6);
  static const Color catCyan = Color(0xFF06B6D4);
  static const Color catYellow = Color(0xFFF59E0B);

  // Bridges for backward compatibility (defaults to light)
  static const Color primary = Color(0xFF00A651);
  static const Color primaryDark = Color(0xFF008C44);
  static const Color secondary = Color(0xFF33B874);
  static const Color bgDark = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFF9FAFB);
  static const Color bgCardLight = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color blue = Color(0xFF3B82F6);
  static const Color green = Color(0xFF10B981);
  static const Color yellow = Color(0xFFF59E0B);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00A651), Color(0xFF33B874)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ThemePalette {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color bg;
  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final LinearGradient bgGradient;

  ThemePalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.bg,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.bgGradient,
  });

  static ThemePalette get light => ThemePalette(
    primary: const Color(0xFF00A651),
    primaryDark: const Color(0xFF008C44),
    primaryLight: const Color(0xFF39C07A),
    bg: const Color(0xFFF8FAFC),
    card: const Color(0xFFFFFFFF),
    cardBorder: const Color(0xFFE2E8F0),
    textPrimary: const Color(0xFF0F172A),
    textSecondary: const Color(0xFF334155),
    textHint: const Color(0xFF64748B),
    bgGradient: const LinearGradient(
      colors: [Color(0xFFEDF2F7), Color(0xFFF7FAFC)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static ThemePalette get dark => ThemePalette(
    primary: const Color(0xFF39C07A),
    primaryDark: const Color(0xFF00A651),
    primaryLight: const Color(0xFF6ED9A3),
    bg: const Color(0xFF0F172A),
    card: const Color(0xFF1E293B),
    cardBorder: const Color(0xFF334155),
    textPrimary: const Color(0xFFF8FAFC),
    textSecondary: const Color(0xFF94A3B8),
    textHint: const Color(0xFF64748B),
    bgGradient: const LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static ThemePalette get oled => ThemePalette(
    primary: const Color(0xFF00E676),
    primaryDark: const Color(0xFF00A651),
    primaryLight: const Color(0xFF69F0AE),
    bg: const Color(0xFF000000),
    card: const Color(0xFF121212),
    cardBorder: const Color(0xFF1A1A1A),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFAAAAAA),
    textHint: const Color(0xFF666666),
    bgGradient: const LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF000000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static ThemePalette get blue => ThemePalette(
    primary: const Color(0xFF3B82F6),
    primaryDark: const Color(0xFF1D4ED8),
    primaryLight: const Color(0xFF60A5FA),
    bg: const Color(0xFF0B1120),
    card: const Color(0xFF1E293B),
    cardBorder: const Color(0xFF334155),
    textPrimary: const Color(0xFFF8FAFC),
    textSecondary: const Color(0xFF94A3B8),
    textHint: const Color(0xFF64748B),
    bgGradient: const LinearGradient(
      colors: [Color(0xFF0B1120), Color(0xFF1E293B)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}

class AppTheme {
  static ThemePalette currentPalette(BuildContext context) {
    // We can determine the mode by looking at the theme's brightness or other properties
    // But since we have ThemeService, we'll use it.
    return getPalette(ThemeService().themeNotifier.value);
  }

  static LinearGradient currentGradient(BuildContext context) => currentPalette(context).bgGradient;

  static ThemeData getTheme(AppThemeMode mode) {
    final p = getPalette(mode);
    final brightness = (mode == AppThemeMode.light) ? Brightness.light : Brightness.dark;
    final baseTextTheme = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      brightness: brightness,
      primaryColor: p.primary,
      scaffoldBackgroundColor: p.bg,
      dividerColor: p.cardBorder,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: brightness,
        surface: p.bg,
        onSurface: p.textPrimary,
        primary: p.primary,
        secondary: p.primaryLight,
        outline: p.cardBorder,
      ),

      // Integrated Text Theme for "International Standard" readability
      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.outfit(
          color: p.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.outfit(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: p.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: p.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: GoogleFonts.nunito(
          color: p.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: GoogleFonts.nunito(
          color: p.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Card Theme - Fixes the light cards in dark mode
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.cardBorder.withOpacity(0.5), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.cardBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(color: p.textHint, fontWeight: FontWeight.normal),
        labelStyle: GoogleFonts.nunito(color: p.textSecondary),
        contentPadding: const EdgeInsets.all(20),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.card,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textHint,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle: GoogleFonts.nunito(color: p.textPrimary, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.primary.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }

  static ThemePalette getPalette(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light: return ThemePalette.light;
      case AppThemeMode.dark: return ThemePalette.dark;
      case AppThemeMode.oled: return ThemePalette.oled;
      case AppThemeMode.blue: return ThemePalette.blue;
    }
  }
}
