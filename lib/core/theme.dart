import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color bgDeep = Color(0xFF070B14);
  static const Color bgCard = Color(0xFF0F1629);
  static const Color bgSurface = Color(0xFF141B2D);
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9D5FFF);
  static const Color accent = Color(0xFF22D3EE);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color borderGlow = Color(0xFF7C3AED);
  static const Color divider = Color(0xFF1E293B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF070B14), Color(0xFF0F1629), Color(0xFF0A1020)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration glassCard({
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 16,
    List<Color>? gradientColors,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: gradientColors ??
              [
                const Color(0xFF1A2240).withValues(alpha: 0.9),
                const Color(0xFF0F1629).withValues(alpha: 0.95),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (borderColor ?? borderGlow).withValues(alpha: 0.4),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? borderGlow).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      );

  static BoxShadow glowShadow(Color color, {double intensity = 0.4}) =>
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 24,
        spreadRadius: -4,
      );

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: bgCard,
          error: accentRed,
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme().copyWith(
          displayLarge: GoogleFonts.rajdhani(
              color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.rajdhani(
              color: textPrimary, fontSize: 26, fontWeight: FontWeight.w700),
          displaySmall: GoogleFonts.rajdhani(
              color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.rajdhani(
              color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.rajdhani(
              color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.rajdhani(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge:
              GoogleFonts.inter(color: textPrimary, fontSize: 16),
          bodyMedium:
              GoogleFonts.inter(color: textSecondary, fontSize: 14),
          bodySmall:
              GoogleFonts.inter(color: textMuted, fontSize: 12),
          labelLarge: GoogleFonts.inter(
              color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgSurface,
          labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
          hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentRed, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentRed, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.rajdhani(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        dividerColor: divider,
        appBarTheme: AppBarTheme(
          backgroundColor: bgDeep,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.rajdhani(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
      );
}
