import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Geist', 'GeistMono'], license);
  });
}

@immutable
class GrovsColors extends ThemeExtension<GrovsColors> {
  const GrovsColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.divider,
    required this.chipFill,
    required this.accent,
    required this.accentSoft,
    required this.ok,
    required this.okSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.neutralDot,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color border;
  final Color divider;
  final Color chipFill;
  final Color accent;
  final Color accentSoft;
  final Color ok;
  final Color okSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color neutralDot;

  static const light = GrovsColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    text: Color(0xFF020617),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFEBEBEB),
    chipFill: Color(0xFFF1F5F9),
    accent: Color(0xFF2A86FF),
    accentSoft: Color(0x142A86FF),
    ok: Color(0xFF1BA34B),
    okSoft: Color(0xFFDDFBE7),
    warning: Color(0xFFD97706),
    warningSoft: Color(0xFFFEF3C7),
    error: Color(0xFFDC2626),
    errorSoft: Color(0xFFFBE8E9),
    neutralDot: Color(0xFFCBD5E1),
  );

  static const dark = GrovsColors(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF171717),
    text: Color(0xFFFAFAFA),
    textMuted: Color(0xFFA1A1A1),
    textFaint: Color(0xFF737373),
    border: Color(0x26FFFFFF),
    divider: Color(0x1AFFFFFF),
    chipFill: Color(0xFF262626),
    accent: Color(0xFF50A0FF),
    accentSoft: Color(0x1F50A0FF),
    ok: Color(0xFF34C46A),
    okSoft: Color(0xFF1C5C31),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0x33F59E0B),
    error: Color(0xFFF87171),
    errorSoft: Color(0x33F87171),
    neutralDot: Color(0xFF525252),
  );

  static GrovsColors of(BuildContext context) =>
      Theme.of(context).extension<GrovsColors>()!;

  @override
  GrovsColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? border,
    Color? divider,
    Color? chipFill,
    Color? accent,
    Color? accentSoft,
    Color? ok,
    Color? okSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? neutralDot,
  }) {
    return GrovsColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      chipFill: chipFill ?? this.chipFill,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      ok: ok ?? this.ok,
      okSoft: okSoft ?? this.okSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      neutralDot: neutralDot ?? this.neutralDot,
    );
  }

  @override
  GrovsColors lerp(ThemeExtension<GrovsColors>? other, double t) {
    if (other is! GrovsColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GrovsColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      chipFill: mix(chipFill, other.chipFill),
      accent: mix(accent, other.accent),
      accentSoft: mix(accentSoft, other.accentSoft),
      ok: mix(ok, other.ok),
      okSoft: mix(okSoft, other.okSoft),
      warning: mix(warning, other.warning),
      warningSoft: mix(warningSoft, other.warningSoft),
      error: mix(error, other.error),
      errorSoft: mix(errorSoft, other.errorSoft),
      neutralDot: mix(neutralDot, other.neutralDot),
    );
  }
}

abstract final class AppType {
  static const _geist = 'Geist';
  static const _geistMono = 'GeistMono';

  static const title = TextStyle(
    fontFamily: _geist,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: -0.2,
  );
  static const heading = TextStyle(
    fontFamily: _geist,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
  static const body = TextStyle(
    fontFamily: _geist,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
  );
  static final bodyStrong = body.copyWith(fontWeight: FontWeight.w500);
  static const label = TextStyle(
    fontFamily: _geist,
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );
  static const caption = TextStyle(
    fontFamily: _geist,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
  );
  static const mono = TextStyle(
    fontFamily: _geistMono,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 17 / 12,
  );
  static const monoSmall = TextStyle(
    fontFamily: _geistMono,
    fontWeight: FontWeight.w500,
    fontSize: 10,
  );
  static const amount = TextStyle(
    fontFamily: _geist,
    fontWeight: FontWeight.w600,
    fontSize: 22,
  );
}

ThemeData buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? GrovsColors.dark
      : GrovsColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: colors.accent,
    brightness: brightness,
  ).copyWith(
    primary: colors.accent,
    onPrimary: Colors.white,
    surface: colors.background,
    onSurface: colors.text,
    surfaceContainerHighest: colors.surface,
    outline: colors.border,
    error: colors.error,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    fontFamily: 'Geist',
    extensions: [colors],
  );
}
