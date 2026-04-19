import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Brand Colors (theme independent) ────────────────────────────────────────
class AppColors {
  static const primary     = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF8B84FF);
  static const primaryDark  = Color(0xFF4A42CC);
  static const accent       = Color(0xFFFF6584);
  static const success      = Color(0xFF00D9A3);
  static const warning      = Color(0xFFFFB347);
  static const error        = Color(0xFFFF5252);

  // Dark theme
  static const darkBgDeep      = Color(0xFF0A0A0F);
  static const darkBgCard      = Color(0xFF13121A);
  static const darkBgElevated  = Color(0xFF1A1825);
  static const darkBgHighlight = Color(0xFF221F30);
  static const darkTextPrimary   = Color(0xFFF0EEF6);
  static const darkTextSecondary = Color(0xFF8B879E);
  static const darkTextMuted     = Color(0xFF6B6880);
  static const darkBorder        = Color(0xFF2A2838);
  static const darkBorderLight   = Color(0xFF3D3A4A);

  // Light theme
  static const lightBgDeep      = Color(0xFFF5F4FF);
  static const lightBgCard      = Color(0xFFFFFFFF);
  static const lightBgElevated  = Color(0xFFF0EEF8);
  static const lightBgHighlight = Color(0xFFE8E6F5);
  static const lightTextPrimary   = Color(0xFF0A0A0F);
  static const lightTextSecondary = Color(0xFF5A5670);
  static const lightTextMuted     = Color(0xFF8B879E);
  static const lightBorder        = Color(0xFFDDDAF0);
  static const lightBorderLight   = Color(0xFFCAC7E0);

  static const surfaceWhite = Color(0xFFF0EEF6);

  // Shortcuts — theme aware (static getters, use via context extension instead)
  static const bgDeep       = darkBgDeep;
  static const bgCard       = darkBgCard;
  static const bgElevated   = darkBgElevated;
  static const bgHighlight  = darkBgHighlight;
  static const textPrimary   = darkTextPrimary;
  static const textSecondary = darkTextSecondary;
  static const textMuted     = darkTextMuted;
  static const textDisabled  = Color(0xFF3D3A4A);
  static const border        = darkBorder;
  static const borderLight   = darkBorderLight;

  static const primaryGlow   = Color(0x336C63FF);
  static const primaryBorder = Color(0x556C63FF);
  static const accentGlow    = Color(0x33FF6584);
  static const accentBorder  = Color(0x55FF6584);
  static const successGlow   = Color(0x3300D9A3);
  static const successBorder = Color(0x5500D9A3);
  static const warningGlow   = Color(0x33FFB347);
  static const warningBorder = Color(0x55FFB347);
}

// ─── Theme Provider ────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark;
    _updateSystemUI();
    notifyListeners();
  }

  void setDark(bool value) {
    _isDark = value;
    _updateSystemUI();
    notifyListeners();
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          _isDark ? AppColors.darkBgCard : AppColors.lightBgCard,
      systemNavigationBarIconBrightness:
          _isDark ? Brightness.light : Brightness.dark,
    ));
  }
}

// ─── Theme Definitions ────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark => _build(isDark: true);
  static ThemeData get light => _build(isDark: false);

  static ThemeData _build({required bool isDark}) {
    final bg       = isDark ? AppColors.darkBgDeep      : AppColors.lightBgDeep;
    final card     = isDark ? AppColors.darkBgCard      : AppColors.lightBgCard;
    final elevated = isDark ? AppColors.darkBgElevated  : AppColors.lightBgElevated;
    final txtPri   = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final txtSec   = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final txtMut   = isDark ? AppColors.darkTextMuted   : AppColors.lightTextMuted;
    final brd      = isDark ? AppColors.darkBorder      : AppColors.lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: card,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: txtPri,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: txtPri),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: txtPri),
        headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: txtPri),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: txtPri),
        bodyLarge:     TextStyle(fontSize: 15, color: txtPri,  height: 1.6),
        bodyMedium:    TextStyle(fontSize: 13, color: txtSec, height: 1.5),
        bodySmall:     TextStyle(fontSize: 11, color: txtMut, height: 1.4),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txtPri),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: txtSec),
        labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: txtMut, letterSpacing: 1.0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPri),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: txtPri),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: brd, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brd, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brd, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: txtMut),
        labelStyle: TextStyle(color: txtSec),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(color: brd, thickness: 0.5, space: 0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(color: txtPri),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: brd, width: 0.5),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Theme-aware color extension ──────────────────────────────────────────────
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgDeep      => isDark ? AppColors.darkBgDeep      : AppColors.lightBgDeep;
  Color get bgCard      => isDark ? AppColors.darkBgCard      : AppColors.lightBgCard;
  Color get bgElevated  => isDark ? AppColors.darkBgElevated  : AppColors.lightBgElevated;
  Color get bgHighlight => isDark ? AppColors.darkBgHighlight : AppColors.lightBgHighlight;
  Color get txtPrimary  => isDark ? AppColors.darkTextPrimary   : AppColors.lightTextPrimary;
  Color get txtSecondary=> isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get txtMuted    => isDark ? AppColors.darkTextMuted     : AppColors.lightTextMuted;
  Color get borderColor => isDark ? AppColors.darkBorder        : AppColors.lightBorder;
}