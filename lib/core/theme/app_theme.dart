import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class HkColorTokens extends ThemeExtension<HkColorTokens> {
  const HkColorTokens({
    required this.surface,
    required this.surfaceCard,
    required this.surfaceSubtle,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentMuted,
    required this.brandWarm,
    required this.brandWarmMuted,
    required this.success,
    required this.successMuted,
    required this.warning,
    required this.warningMuted,
    required this.danger,
    required this.dangerMuted,
    required this.onAccent,
  });

  final Color surface;
  final Color surfaceCard;
  final Color surfaceSubtle;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color accentMuted;
  final Color brandWarm;
  final Color brandWarmMuted;
  final Color success;
  final Color successMuted;
  final Color warning;
  final Color warningMuted;
  final Color danger;
  final Color dangerMuted;
  final Color onAccent;

  static const HkColorTokens light = HkColorTokens(
    surface: Color(0xFFF3F6F7),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFE9EFF1),
    border: Color(0xFFD2DFE3),
    textPrimary: Color(0xFF0E2026),
    textMuted: Color(0xFF4D646D),
    accent: Color(0xFF0B5563),
    accentMuted: Color(0xFFDDF0F3),
    brandWarm: Color(0xFFD85B1C),
    brandWarmMuted: Color(0xFFFCE9DF),
    success: Color(0xFF157347),
    successMuted: Color(0xFFDFF3E8),
    warning: Color(0xFFB45309),
    warningMuted: Color(0xFFFEF0D9),
    danger: Color(0xFFB91C1C),
    dangerMuted: Color(0xFFFDE4E4),
    onAccent: Color(0xFFFFFFFF),
  );

  @override
  HkColorTokens copyWith({
    Color? surface,
    Color? surfaceCard,
    Color? surfaceSubtle,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? accent,
    Color? accentMuted,
    Color? brandWarm,
    Color? brandWarmMuted,
    Color? success,
    Color? successMuted,
    Color? warning,
    Color? warningMuted,
    Color? danger,
    Color? dangerMuted,
    Color? onAccent,
  }) {
    return HkColorTokens(
      surface: surface ?? this.surface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      brandWarm: brandWarm ?? this.brandWarm,
      brandWarmMuted: brandWarmMuted ?? this.brandWarmMuted,
      success: success ?? this.success,
      successMuted: successMuted ?? this.successMuted,
      warning: warning ?? this.warning,
      warningMuted: warningMuted ?? this.warningMuted,
      danger: danger ?? this.danger,
      dangerMuted: dangerMuted ?? this.dangerMuted,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  HkColorTokens lerp(ThemeExtension<HkColorTokens>? other, double t) {
    if (other is! HkColorTokens) return this;
    return HkColorTokens(
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t) ?? surfaceCard,
      surfaceSubtle:
          Color.lerp(surfaceSubtle, other.surfaceSubtle, t) ?? surfaceSubtle,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t) ?? accentMuted,
      brandWarm: Color.lerp(brandWarm, other.brandWarm, t) ?? brandWarm,
      brandWarmMuted:
          Color.lerp(brandWarmMuted, other.brandWarmMuted, t) ?? brandWarmMuted,
      success: Color.lerp(success, other.success, t) ?? success,
      successMuted:
          Color.lerp(successMuted, other.successMuted, t) ?? successMuted,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningMuted:
          Color.lerp(warningMuted, other.warningMuted, t) ?? warningMuted,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      dangerMuted: Color.lerp(dangerMuted, other.dangerMuted, t) ?? dangerMuted,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
    );
  }
}

extension HkThemeContext on BuildContext {
  HkColorTokens get colors =>
      Theme.of(this).extension<HkColorTokens>() ?? HkColorTokens.light;

  TextTheme get textStyles => Theme.of(this).textTheme;

  TextStyle get monoStyle => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      );
}

abstract final class AppTheme {
  static ThemeData buildLightTheme() {
    const tokens = HkColorTokens.light;
    final baseText = GoogleFonts.plusJakartaSansTextTheme();

    final textTheme = baseText.copyWith(
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.textMuted,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: tokens.textMuted,
      ),
    );

    final colorScheme = ColorScheme.light(
      primary: tokens.accent,
      onPrimary: tokens.onAccent,
      secondary: tokens.brandWarm,
      onSecondary: tokens.onAccent,
      surface: tokens.surfaceCard,
      onSurface: tokens.textPrimary,
      error: tokens.danger,
      onError: tokens.onAccent,
      outline: tokens.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.surface,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surfaceCard,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.accent, width: 1.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        hintStyle: textTheme.bodySmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size(88, 48),
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surfaceCard,
        indicatorColor: tokens.accentMuted,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.bodySmall?.copyWith(
              color: tokens.accent,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.bodySmall;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
