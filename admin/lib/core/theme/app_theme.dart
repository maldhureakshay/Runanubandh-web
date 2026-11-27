import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same branding and structure as the mobile app
/// (`runanubandh/lib/app_theme.dart`). Poppins is loaded via [google_fonts] for
/// Flutter Web without bundling TTF assets.
class AppTheme {
  // ---------------------------------------------------------------------------
  // Responsive text scaling (same as mobile)
  // ---------------------------------------------------------------------------
  static const double refWidth = 393.0;
  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.15;

  static double textScaleFactor(Size size) {
    final scale = size.width / refWidth;
    return scale.clamp(minTextScale, maxTextScale);
  }

  static TextTheme scaledTextTheme(TextTheme base, double scale) {
    TextStyle scaleStyle(TextStyle? s) {
      if (s == null) return const TextStyle();
      return s.copyWith(fontSize: (s.fontSize ?? 14) * scale);
    }
    return TextTheme(
      displayLarge: scaleStyle(base.displayLarge),
      displayMedium: scaleStyle(base.displayMedium),
      displaySmall: scaleStyle(base.displaySmall),
      headlineLarge: scaleStyle(base.headlineLarge),
      headlineMedium: scaleStyle(base.headlineMedium),
      headlineSmall: scaleStyle(base.headlineSmall),
      titleLarge: scaleStyle(base.titleLarge),
      titleMedium: scaleStyle(base.titleMedium),
      titleSmall: scaleStyle(base.titleSmall),
      bodyLarge: scaleStyle(base.bodyLarge),
      bodyMedium: scaleStyle(base.bodyMedium),
      bodySmall: scaleStyle(base.bodySmall),
      labelLarge: scaleStyle(base.labelLarge),
      labelMedium: scaleStyle(base.labelMedium),
      labelSmall: scaleStyle(base.labelSmall),
    );
  }

  static TextStyle scaleStyle(TextStyle style, BuildContext context) {
    final scale = textScaleFactor(MediaQuery.sizeOf(context));
    return style.copyWith(fontSize: (style.fontSize ?? 14) * scale);
  }

  static TextStyle headlineLargeCtx(BuildContext context) =>
      Theme.of(context).textTheme.displayLarge!;
  static TextStyle headlineMediumCtx(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!;
  static TextStyle headlineSmallCtx(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!;
  static TextStyle titleLargeCtx(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;
  static TextStyle titleMediumCtx(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!;
  static TextStyle titleSmallCtx(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!;
  static TextStyle bodyLargeCtx(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!;
  static TextStyle bodyMediumCtx(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;
  static TextStyle bodySmallCtx(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;
  static TextStyle labelLargeCtx(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!;
  static TextStyle labelMediumCtx(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!;
  static TextStyle labelSmallCtx(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!;

  // Primary Brand Colors
  static const Color primaryColor = Color(0xFFAA336A);
  static const Color primaryDarkColor = Color(0xFF5D1E3C);
  static const Color accentColor = Color(0xFFDFAE45);

  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textTertiaryColor = Color(0xFF888888);

  static const Color freshMarriageColor = Colors.green;
  static const Color remarriageColor = Colors.blue;
  static const Color unspecifiedColor = Colors.grey;

  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color iconColor = Colors.grey;
  static const Color errorColor = Color(0xFFE53935);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryColor, primaryDarkColor],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF7D58B), Color(0xFFDFAE45)],
  );

  static const String fontFamily = 'Poppins';
  static const String marathiFontFamily = 'Arial';

  static TextStyle _p({
    required double fontSize,
    FontWeight? weight,
    Color color = textPrimaryColor,
  }) =>
      GoogleFonts.poppins(fontSize: fontSize, fontWeight: weight, color: color);

  static TextTheme _poppinsTextTheme() {
    return TextTheme(
      displayLarge: _p(fontSize: 28, weight: FontWeight.bold),
      displayMedium: _p(fontSize: 22, weight: FontWeight.bold),
      displaySmall: _p(fontSize: 18, weight: FontWeight.bold),
      titleLarge: _p(fontSize: 20, weight: FontWeight.w600),
      titleMedium: _p(fontSize: 16, weight: FontWeight.w600),
      titleSmall: _p(fontSize: 14, weight: FontWeight.w600),
      bodyLarge: _p(fontSize: 16),
      bodyMedium: _p(fontSize: 14),
      bodySmall: _p(fontSize: 12, color: textSecondaryColor),
      labelLarge: _p(fontSize: 14, weight: FontWeight.w500),
      labelMedium: _p(fontSize: 12, weight: FontWeight.w500),
      labelSmall: _p(
        fontSize: 11,
        weight: FontWeight.w500,
        color: textSecondaryColor,
      ),
    );
  }

  static const TextStyle tagline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Colors.white,
    letterSpacing: 1.0,
  );

  static const TextStyle marathi = TextStyle(
    fontFamily: marathiFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.white,
        blurRadius: 5,
        offset: Offset(0, 0),
      ),
    ],
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.1),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
    border: Border.all(
      color: Colors.grey.shade200,
      width: 1,
    ),
  );

  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      fillColor: Colors.grey.shade50,
      filled: true,
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: primaryColor,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: errorColor.withValues(alpha: 0.7),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: errorColor.withValues(alpha: 0.7),
        ),
      ),
      errorStyle: TextStyle(
        color: errorColor.withValues(alpha: 0.8),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
    );
  }

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 2,
    shadowColor: primaryColor.withValues(alpha: 0.5),
    minimumSize: const Size(double.infinity, 50),
  );

  /// Light theme — matches mobile [getThemeData] (Material 2 style).
  ///
  /// NOTE: we intentionally do **not** set `fontFamily` on [ThemeData]. On
  /// Flutter Web, using a `google_fonts` dynamic family name as
  /// `ThemeData.fontFamily` confuses Material Icons rendering (icons fall
  /// back to Noto and disappear). The [textTheme] below already uses Poppins
  /// for every TextStyle, so all text picks it up correctly.
  static ThemeData getThemeData() {
    final headlineSmall = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: textPrimaryColor,
    );

    return ThemeData(
      useMaterial3: false,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      textTheme: _poppinsTextTheme(),
      iconTheme: const IconThemeData(color: textPrimaryColor, size: 24),
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headlineSmall,
        iconTheme: const IconThemeData(color: textPrimaryColor, size: 24),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: primaryColor,
              width: 3.0,
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
    );
  }

  /// Alias for [getThemeData] (used by [AdminRootApp]).
  static ThemeData light() => getThemeData();

  /// Dark variant for system dark mode — same brand primaries as mobile light.
  /// (See note on [getThemeData] for why we omit `fontFamily` on web.)
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: Color(0xFF1E1E1E),
        error: errorColor,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: Colors.white24,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
    return base;
  }
}
