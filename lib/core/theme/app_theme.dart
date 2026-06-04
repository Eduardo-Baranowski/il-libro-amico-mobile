import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta e tipografia do Stitch «Bibliotheca Aesthetic».
class AppTheme {
  static const Color background = Color(0xFFFBF9F4);
  static const Color surface = Color(0xFFFBF9F4);
  static const Color surfaceLow = Color(0xFFF5F3EE);
  static const Color surfaceContainer = Color(0xFFF0EEE9);
  static const Color surfaceHighest = Color(0xFFE4E2DD);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF93452D);
  static const Color primaryContainer = Color(0xFFB25D43);
  static const Color primarySoft = Color(0xFFFFDBD1);

  static const Color secondary = Color(0xFF4F6354);
  static const Color secondaryContainer = Color(0xFFCCE3CF);
  static const Color onSecondaryContainer = Color(0xFF516656);

  static const Color onSurface = Color(0xFF1B1C19);
  static const Color onSurfaceVariant = Color(0xFF55433E);
  static const Color outline = Color(0xFF88726D);
  static const Color outlineVariant = Color(0xFFDAC1BA);

  static const Color inputFill = Color(0xFFF0EDE4);
  static const Color muted = onSurfaceVariant;
  static const Color error = Color(0xFFBA1A1A);

  static const double marginMobile = 20;
  static const double gutterMobile = 12;
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(16));

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A202C).withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle get displaySerif => GoogleFonts.literata(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
        color: onSurface,
      );

  static TextStyle get headlineSerif => GoogleFonts.literata(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: onSurface,
      );

  static TextStyle get titleSerif => GoogleFonts.literata(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      );

  static TextStyle get bodySans => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      );

  static TextStyle get labelSans => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.01,
        color: onSurface,
      );

  static TextStyle get captionSans => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.03,
        color: onSurfaceVariant,
      );

  static ThemeData light() {
    final literata = GoogleFonts.literataTextTheme();
    final jakarta = GoogleFonts.plusJakartaSansTextTheme();

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        surface: surface,
        onSurface: onSurface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: jakarta.copyWith(
        headlineSmall: literata.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: literata.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: primary,
        titleTextStyle: GoogleFonts.literata(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radiusXl,
          side: BorderSide(color: outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: bodySans.copyWith(color: onSurfaceVariant),
        labelStyle: captionSans,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusLg),
          textStyle: labelSans.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: const BorderSide(color: secondary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusLg),
          textStyle: labelSans.copyWith(color: secondary),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return captionSans.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? onSecondaryContainer : onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? onSecondaryContainer : onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: outlineVariant.withValues(alpha: 0.25),
        thickness: 1,
      ),
    );
  }
}
