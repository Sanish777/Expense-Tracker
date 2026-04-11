import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colours (reference-matching) ───────────────────────────────────
  static const Color primary = Color(0xFF7B61FF);          // soft purple
  static const Color primaryLight = Color(0xFFEDE9FF);     // lavender bg
  static const Color primaryDark = Color(0xFF5B41FF);
  static const Color accent = Color(0xFF00C896);            // success green
  static const Color danger = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFC542);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF9B9BB4);

  // Surfaces
  static const Color bgLight = Color(0xFFF3F1FF);           // lavender tint bg
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color navBg = Color(0xFFFFFFFF);

  // Dark mode surfaces
  static const Color bgDark = Color(0xFF13121F);
  static const Color cardDark = Color(0xFF1E1C2E);
  static const Color cardDark2 = Color(0xFF272540);

  // ── Light Theme (Primary) ─────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        error: danger,
        surface: cardWhite,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w800, color: textDark, fontSize: 32),
        headlineMedium: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: textDark, fontSize: 20),
        bodyLarge: GoogleFonts.poppins(color: textDark, fontSize: 15),
        bodyMedium: GoogleFonts.poppins(color: textMuted, fontSize: 13),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shadowColor: primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFFBBB9D4),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerColor: const Color(0xFFECEAFF),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        error: danger,
        surface: cardDark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  // ── Shared Gradients ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFF9B89FF), Color(0xFFA67CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [
      Color(0xFF7B61FF), // Primary Purple
      Color(0xFF5B41FF), // Deeper Purple
      Color(0xFF8E44AD), // Amethyst
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Rainbow accent gradient for subtle highlights matching the logo
  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [
      Color(0xFF4ECDC4), // Green/Teal
      Color(0xFFFFC542), // Yellow
      Color(0xFFFF6B6B), // Red/Pink
      Color(0xFF7B61FF), // Purple
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Category colour utility ───────────────────────────────────────────────
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return const Color(0xFFFF6B6B);
      case 'transport': return const Color(0xFF4ECDC4);
      case 'shopping': return const Color(0xFFFFC542);
      case 'bills': return const Color(0xFF7B61FF);
      case 'entertainment': return const Color(0xFFFF8C42);
      default: return const Color(0xFFACB7C0);
    }
  }

  static String categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food': return '🍔';
      case 'transport': return '🚌';
      case 'shopping': return '🛒';
      case 'bills': return '💡';
      case 'entertainment': return '🎬';
      default: return '📦';
    }
  }
}
