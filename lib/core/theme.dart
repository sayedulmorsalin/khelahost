import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Imperial Obsidian & Black Truffle - Ultra-Rich Dark Foundation
  static const Color bgDeep = Color(0xFF05070B);
  static const Color bgCard = Color(0xFF0A0F18);
  static const Color bgSurface = Color(0xFF111726);
  static const Color bgElevated = Color(0xFF182236);

  // Imperial 24K Champagne Gold - Primary Luxury Brand Asset
  static const Color gold = Color(0xFFDFB76C);
  static const Color goldLight = Color(0xFFF7E6C4);
  static const Color goldDark = Color(0xFFB38838);
  static const Color goldMuted = Color(0xFF7A5F26);

  // Brand Primary mapped to Gold for rich luxury feel
  static const Color primary = Color(0xFFDFB76C);
  static const Color primaryLight = Color(0xFFF7E6C4);
  static const Color primaryDark = Color(0xFFB38838);

  // Royal Sapphire & Emerald Jewels
  static const Color sapphire = Color(0xFF2563EB);
  static const Color sapphireLight = Color(0xFF38BDF8);
  static const Color accent = Color(0xFFDFB76C);
  static const Color accentGreen = Color(0xFF10B981); // Emerald Live Pulse
  static const Color accentRed = Color(0xFFEF4444); // Crimson Ruby
  static const Color accentGold = Color(0xFFDFB76C); // Pure Gold
  static const Color accentGoldLight = Color(0xFFF7E6C4);

  // Typography - High Contrast Platinum, Gold & Muted Slate
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFFC0CAD8);
  static const Color textMuted = Color(0xFF6B7A90);
  static const Color textGold = Color(0xFFDFB76C);

  // Borders & Dividers - Metallic Hairlines
  static const Color borderGlow = Color(0xFFDFB76C);
  static const Color divider = Color(0xFF161E2E);
  static const Color cardBorder = Color(0xFF1A2336);
  static const Color cardBorderGold = Color(0x38DFB76C);
  static const Color cardBorderSubtle = Color(0x14FFFFFF);

  // Opulent Luxury Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF8E7C4), Color(0xFFDFB76C), Color(0xFFA87E2C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldButtonGradient = LinearGradient(
    colors: [Color(0xFFF8E8C6), Color(0xFFDFB76C), Color(0xFFB38838)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = goldGradient;
  static const LinearGradient primaryButtonGradient = goldButtonGradient;

  static const LinearGradient luxuryCardGradient = LinearGradient(
    colors: [Color(0xFF0F1626), Color(0xFF080C14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryHeroGradient = LinearGradient(
    colors: [
      Color(0xFF1A2438),
      Color(0xFF0E1422),
      Color(0xFF06090F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sapphireButtonGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF05070B), Color(0xFF0A0F18), Color(0xFF05070B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration glassCard({
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 18,
    List<Color>? gradientColors,
    bool isGold = false,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: bgCard,
        gradient: LinearGradient(
          colors: gradientColors ??
              [
                const Color(0xFF0F1626),
                const Color(0xFF070B13),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isGold
              ? gold.withValues(alpha: 0.35)
              : (borderColor ?? cardBorder).withValues(alpha: 0.9),
          width: isGold ? 1.2 : borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: isGold
                ? gold.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.45),
            blurRadius: isGold ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration luxuryBadge({
    Color? color,
    double borderRadius = 8,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: (color ?? gold).withValues(alpha: 0.14),
        border: Border.all(
          color: (color ?? gold).withValues(alpha: 0.35),
          width: 0.8,
        ),
      );

  static BoxShadow glowShadow(Color color, {double intensity = 0.25}) =>
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 18,
        offset: const Offset(0, 4),
      );

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: goldLight,
          surface: bgCard,
          error: accentRed,
          onPrimary: Color(0xFF0A0D14),
          onSecondary: Color(0xFF0A0D14),
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          displaySmall: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 15,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
          bodySmall: GoogleFonts.inter(
            color: textMuted,
            fontSize: 11,
            height: 1.3,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgSurface,
          labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
          hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E283C), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: gold, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentRed, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentRed, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: const Color(0xFF090C12),
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: goldLight,
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: cardBorderGold, width: 1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        dividerColor: divider,
        appBarTheme: AppBarTheme(
          backgroundColor: bgDeep,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
      );
}
