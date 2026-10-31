import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - Clean, Professional Sports & Tournament Slate
  // No cyberpunk neon, no violet/purple tints; clean neutral slate with classic royal blue
  static const Color bgDeep = Color(0xFF0B0F19);
  static const Color bgCard = Color(0xFF131B2A);
  static const Color bgSurface = Color(0xFF1A2438);
  static const Color bgElevated = Color(0xFF222F47);

  // Brand Primary - Classic Athletic Royal Blue
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Accents
  static const Color accent = Color(0xFF38BDF8); // Crisp Sky Blue
  static const Color accentGreen = Color(0xFF10B981); // Emerald for Live & Active
  static const Color accentRed = Color(0xFFEF4444); // Clean Crimson
  static const Color accentGold = Color(0xFFF59E0B); // Tournament Trophy Gold

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Borders & Dividers
  static const Color borderGlow = Color(0xFF2563EB);
  static const Color divider = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF28364F);

  // Clean, Subtle Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0B0F19), Color(0xFF0F172A), Color(0xFF0B0F19)],
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
        color: bgCard,
        gradient: LinearGradient(
          colors: gradientColors ??
              [
                const Color(0xFF141C2C),
                const Color(0xFF101725),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (borderColor ?? cardBorder).withValues(alpha: 0.8),
          width: borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      );

  static BoxShadow glowShadow(Color color, {double intensity = 0.15}) =>
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 12,
        offset: const Offset(0, 2),
      );

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: bgCard,
          error: accentRed,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
              color: textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
          displayMedium: GoogleFonts.plusJakartaSans(
              color: textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4),
          displaySmall: GoogleFonts.plusJakartaSans(
              color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          headlineLarge: GoogleFonts.plusJakartaSans(
              color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.plusJakartaSans(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.plusJakartaSans(
              color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge:
              GoogleFonts.inter(color: textPrimary, fontSize: 15, height: 1.5),
          bodyMedium: GoogleFonts.inter(
              color: textSecondary, fontSize: 13, height: 1.45),
          bodySmall:
              GoogleFonts.inter(color: textMuted, fontSize: 11, height: 1.3),
          labelLarge: GoogleFonts.plusJakartaSans(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgSurface,
          labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
          hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF28364F), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentRed, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentRed, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: cardBorder, width: 1.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        dividerColor: divider,
        appBarTheme: AppBarTheme(
          backgroundColor: bgDeep,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
      );
}
