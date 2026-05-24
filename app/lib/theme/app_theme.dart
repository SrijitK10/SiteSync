import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _lightPrimary = Color(0xFF16324F);
  static const Color _lightAccent = Color(0xFFD79A45);
  static const Color _lightBackground = Color(0xFFF2F5F9);
  static const Color _lightSurface = Color(0xFFFFFEFE);
  static const Color _lightTextPrimary = Color(0xFF162235);
  static const Color _lightTextSecondary = Color(0xFF66758B);

  static const Color _darkPrimary = Color(0xFF8FB8FF);
  static const Color _darkAccent = Color(0xFFFFC978);
  static const Color _darkBackground = Color(0xFF09111F);
  static const Color _darkSurface = Color(0xFF0F1B30);
  static const Color _darkTextPrimary = Color(0xFFF4F7FC);
  static const Color _darkTextSecondary = Color(0xFFA7B5CB);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);

  static bool _isDark = false;

  static bool get _isWindowsDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

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

  static Gradient windowBackdropGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF0A101D), Color(0xFF1B2745), Color(0xFF22163A)]
          : const [Color(0xFFD9E2ED), Color(0xFFF2E6F5), Color(0xFFD3DFEF)],
      stops: const [0.0, 0.52, 1.0],
    );
  }

  static BoxDecoration desktopPaneDecoration(
    BuildContext context, {
    double radius = 28,
    bool emphasized = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? const Color(0xFF0E1B2E).withValues(alpha: emphasized ? 0.94 : 0.9)
        : const Color(0xFFFDFEFF).withValues(alpha: emphasized ? 0.98 : 0.94);
    final accent = Theme.of(context).colorScheme.primary;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          panelColor,
          Color.lerp(panelColor, accent, isDark ? 0.1 : 0.04)!,
        ],
      ),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.1),
          blurRadius: emphasized ? 44 : 28,
          offset: Offset(0, emphasized ? 22 : 14),
        ),
      ],
    );
  }

  static Widget buildGlassContainer(
    BuildContext context, {
    required Widget child,
    double radius = 28,
    bool emphasized = false,
    EdgeInsetsGeometry? padding,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: emphasized ? 40 : 20,
            offset: Offset(0, emphasized ? 20 : 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.06) 
                  : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.12) 
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final isWindows = _isWindowsDesktopPlatform;
    final primary = isDark ? _darkPrimary : _lightPrimary;
    final secondary = isDark ? _darkAccent : _lightAccent;
    final surface = isDark ? _darkSurface : _lightSurface;
    final background = isDark ? _darkBackground : _lightBackground;
    final textPrimary = isDark ? _darkTextPrimary : _lightTextPrimary;
    final textSecondary = isDark ? _darkTextSecondary : _lightTextSecondary;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: isDark ? _darkBackground : _lightSurface,
          secondary: secondary,
          onSecondary: _lightPrimary,
          error: danger,
          onError: _lightSurface,
          surface: surface,
          onSurface: textPrimary,
        );

    final shapeRadius = isWindows ? 18.0 : 12.0;
    final buttonRadius = isWindows ? 18.0 : 14.0;

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
      visualDensity: isWindows
          ? const VisualDensity(horizontal: 0, vertical: 0)
          : VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: isWindows ? 0.72 : 1),
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: isWindows ? 72 : null,
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
        fillColor: isDark ? const Color(0xFF152338) : surface,
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
          borderRadius: BorderRadius.circular(shapeRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeRadius),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeRadius),
          borderSide: BorderSide(color: primary, width: isWindows ? 1.6 : 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: primary,
          disabledBackgroundColor: primary.withValues(alpha: 0.45),
          disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.8),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isWindows ? 22 : 18,
            vertical: isWindows ? 18 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: isWindows ? 15 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: textSecondary.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isWindows ? 20 : 16,
            vertical: isWindows ? 18 : 14,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: isWindows ? 15 : 14,
            fontWeight: FontWeight.w600,
          ),
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
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          hoverColor: primary.withValues(alpha: isDark ? 0.18 : 0.08),
          highlightColor: primary.withValues(alpha: isDark ? 0.24 : 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWindows ? 16 : 12),
          ),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWindows ? 18 : 14),
        ),
        textStyle: GoogleFonts.inter(color: textPrimary),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          primary.withValues(alpha: isDark ? 0.44 : 0.32),
        ),
        radius: const Radius.circular(999),
        thickness: WidgetStatePropertyAll(isWindows ? 8 : 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF232836) : _lightPrimary,
        contentTextStyle: GoogleFonts.inter(color: _lightSurface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
