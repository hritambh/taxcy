import 'package:flutter/material.dart';

/// Taxcy blue on white: blue app bars and actions, white surfaces, blue-tinted
/// neutrals. Mirrors the admin web's palette (Tailwind blue scale).
abstract final class TaxcyColors {
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue300 = Color(0xFF93C5FD);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue800 = Color(0xFF1E40AF);
  static const blue900 = Color(0xFF1E3A8A);
  static const blue950 = Color(0xFF172554);

  /// App background: white with a hint of blue, so white cards stand out.
  static const background = Color(0xFFF4F8FF);
  static const border = Color(0xFFD9E3F3);
  static const ink = Color(0xFF121B2F);
  static const muted = Color(0xFF637594);
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: TaxcyColors.blue700,
        brightness: Brightness.light,
      ).copyWith(
        primary: TaxcyColors.blue700,
        onPrimary: Colors.white,
        primaryContainer: TaxcyColors.blue100,
        onPrimaryContainer: TaxcyColors.blue950,
        secondary: TaxcyColors.blue600,
        onSecondary: Colors.white,
        secondaryContainer: TaxcyColors.blue100,
        onSecondaryContainer: TaxcyColors.blue900,
        surface: Colors.white,
        onSurface: TaxcyColors.ink,
        onSurfaceVariant: TaxcyColors.muted,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: TaxcyColors.blue50,
        surfaceContainer: TaxcyColors.blue50,
        surfaceContainerHigh: TaxcyColors.blue100,
        outline: TaxcyColors.blue300,
        outlineVariant: TaxcyColors.border,
      );

  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  OutlineInputBorder field(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    // Bundled for the web build; phones use their own Devanagari fonts first.
    fontFamilyFallback: const ['NotoSansDevanagari'],
    colorScheme: scheme,
    scaffoldBackgroundColor: TaxcyColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: TaxcyColors.blue800,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: TaxcyColors.blue100),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: field(TaxcyColors.border),
      enabledBorder: field(TaxcyColors.border),
      focusedBorder: field(TaxcyColors.blue600, 2),
      errorBorder: field(scheme.error),
      focusedErrorBorder: field(scheme.error, 2),
      labelStyle: const TextStyle(color: TaxcyColors.muted),
      floatingLabelStyle: const TextStyle(color: TaxcyColors.blue700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TaxcyColors.blue700,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: rounded,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TaxcyColors.blue700,
        side: const BorderSide(color: TaxcyColors.blue300),
        minimumSize: const Size(64, 44),
        shape: rounded,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: TaxcyColors.blue700),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: TaxcyColors.blue100,
        selectedForegroundColor: TaxcyColors.blue900,
        side: const BorderSide(color: TaxcyColors.blue200),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TaxcyColors.blue700,
      foregroundColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(iconColor: TaxcyColors.blue700),
    dividerTheme: const DividerThemeData(color: TaxcyColors.border),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: TaxcyColors.blue900,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: TaxcyColors.blue50,
      side: BorderSide(color: TaxcyColors.blue100),
      labelStyle: TextStyle(color: TaxcyColors.blue900),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TaxcyColors.blue700,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: TaxcyColors.blue950,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: TaxcyColors.ink,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: TaxcyColors.blue800,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
  );
}
