import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _lightPrimary = Color(0xFF1A1A2E);
  static const Color _lightAccent = Color(0xFFF5A623);
  static const Color _lightBackground = Color(0xFFF7F8FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1A1A2E);
  static const Color _lightTextSecondary = Color(0xFF707070);

  static const Color _darkPrimary = Color(0xFF9BB0FF);
  static const Color _darkAccent = Color(0xFFFFC861);
  static const Color _darkBackground = Color(0xFF0F1117);
  static const Color _darkSurface = Color(0xFF171A22);
  static const Color _darkTextPrimary = Color(0xFFF4F6FB);
  static const Color _darkTextSecondary = Color(0xFFABB4C4);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);

  static bool _isDark = false;

  static void syncWithContext(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
  }

  static Color get primary => _isDark ? _darkPrimary : _lightPrimary;
  static Color get accent => _isDark ? _darkAccent : _lightAccent;
  static Color get background => _isDark ? _darkBackground : _lightBackground;
  static Color get surface => _isDark ? _darkSurface : _lightSurface;
  static Color get textPrimary =>
      _isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;

  static TextStyle get heading => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: textSecondary,
  );

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? _darkPrimary : _lightPrimary;
    final secondary = isDark ? _darkAccent : _lightAccent;
    final surface = isDark ? _darkSurface : _lightSurface;
    final background = isDark ? _darkBackground : _lightBackground;
    final textPrimary = isDark ? _darkTextPrimary : _lightTextPrimary;
    final textSecondary = isDark ? _darkTextSecondary : _lightTextSecondary;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? _darkBackground : _lightSurface,
      secondary: secondary,
      onSecondary: _lightPrimary,
      error: danger,
      onError: _lightSurface,
      surface: surface,
      onSurface: textPrimary,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness, useMaterial3: true).textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: colorScheme,
      canvasColor: background,
      dividerColor: textSecondary.withValues(alpha: 0.18),
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
      cardColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
          color: textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1D2230) : surface,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondary, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: isDark ? _darkBackground : _lightSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: isDark ? 0.22 : 0.12),
        secondarySelectedColor: secondary.withValues(
          alpha: isDark ? 0.22 : 0.12,
        ),
        disabledColor: textSecondary.withValues(alpha: 0.12),
        side: BorderSide(color: textSecondary.withValues(alpha: 0.18)),
        labelStyle: GoogleFonts.inter(color: textPrimary),
        secondaryLabelStyle: GoogleFonts.inter(color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        brightness: brightness,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        modalBackgroundColor: background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        textStyle: GoogleFonts.inter(color: textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF232836) : _lightPrimary,
        contentTextStyle: GoogleFonts.inter(color: _lightSurface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
