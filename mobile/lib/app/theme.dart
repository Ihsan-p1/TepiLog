import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Warna dari Foto": no brand colour. A quiet grey ground and near-black
/// ink; places and photos lend their own colour to the UI around them.
class AppTheme {
  // Legacy dark palette, still read by screens not yet redesigned.
  static const Color primary = Color(0xFF1C1C1E); // Near-black
  static const Color accent = Color(0xFFD6D3D1);  // Stone/Warm Gray 200
  static const Color background = Color(0xFF000000); // Pure Black for photo pop
  static const Color surface = Color(0xFF1C1C1E);
  static const Color error = Color(0xFFFF453A); // iOS style red
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color border = Color(0xFF3F3F46); // Zinc 700

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF111214),
    onPrimary: Color(0xFFF2F2F0),
    secondary: Color(0xFF111214),
    onSecondary: Color(0xFFF2F2F0),
    error: Color(0xFFC4321F),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F2F0),
    onSurface: Color(0xFF111214),
    onSurfaceVariant: Color(0xFF5C5E64),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F8F6),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFE9E9E6),
    surfaceContainerHighest: Color(0xFFE2E2DF),
    outline: Color(0xFFCFCFCB),
    outlineVariant: Color(0xFFE2E2DF),
    shadow: Color(0xFF111214),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF111214),
    onInverseSurface: Color(0xFFF2F2F0),
    inversePrimary: Color(0xFFF2F2F0),
    surfaceTint: Colors.transparent,
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF2F2F0),
    onPrimary: Color(0xFF111214),
    secondary: Color(0xFFF2F2F0),
    onSecondary: Color(0xFF111214),
    error: Color(0xFFFF7B6B),
    onError: Color(0xFF111214),
    surface: Color(0xFF0B0B0C),
    onSurface: Color(0xFFF2F2F0),
    onSurfaceVariant: Color(0xFF9C9EA4),
    surfaceContainerLowest: Color(0xFF060607),
    surfaceContainerLow: Color(0xFF131315),
    surfaceContainer: Color(0xFF1A1A1C),
    surfaceContainerHigh: Color(0xFF232326),
    surfaceContainerHighest: Color(0xFF2C2C30),
    outline: Color(0xFF3A3A3F),
    outlineVariant: Color(0xFF2C2C30),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF2F2F0),
    onInverseSurface: Color(0xFF111214),
    inversePrimary: Color(0xFF111214),
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light => _build(lightScheme);
  static ThemeData get dark => _build(darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    // Titles: weight 800, tracking tightened with size (about -0.03em).
    TextStyle title(double size) => GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03 * size,
          height: 1.1,
          color: scheme.onSurface,
        );

    final radius = BorderRadius.circular(16);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.copyWith(
        displaySmall: title(34),
        headlineSmall: title(24),
        titleLarge: title(20),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, letterSpacing: -0.1),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: title(18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerHigh,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide.none,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}
