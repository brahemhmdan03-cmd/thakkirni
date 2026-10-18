import 'package:flutter/material.dart';

import '../core/strings.dart';

class Brand {
  static const violet = Color(0xFF5B4CF5);
  static const teal = Color(0xFF14C8B4);
  static const amber = Color(0xFFFFB547);
  static const coral = Color(0xFFFF6B6B);
  static const night1 = Color(0xFF17113D);
  static const night2 = Color(0xFF0B2B3A);

  static const gradient = LinearGradient(colors: [violet, teal], begin: Alignment.topLeft, end: Alignment.bottomRight);

  static ThemeData theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: violet, brightness: b);
    final dark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0F0D1C) : const Color(0xFFF6F5FB),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? const Color(0xFF1C1930) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

extension Ctx on BuildContext {
  S get s => Localizations.localeOf(this).languageCode == 'ar' ? S.arabic : S.english;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
