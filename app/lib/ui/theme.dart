// Tema do Genoz a partir do guia de estilo (docs/estilo/GUIA_DE_ESTILO.md).
// Todas as cores do app vêm daqui; o Módulo 5 refina tipografia e componentes.

import 'package:flutter/material.dart';

/// Tokens de cor do guia de estilo.
abstract final class GenozColors {
  static const petroleum = Color(0xFF0B7285); // Azul-petróleo / Genoz Médio — primária
  static const deep = Color(0xFF073B4C); // Azul profundo / Genoz Escuro — logo e fundos
  static const cyan = Color(0xFF22B8CF); // Ciano / Genoz Claro — destaques
  static const background = Color(0xFFF6FAFB); // Fundo geral
  static const surface = Color(0xFFFFFFFF); // Cards e diálogos
  static const textPrimary = Color(0xFF17212B);
  static const textSecondary = Color(0xFF64748B);
  static const success = Color(0xFF2F9E44);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFD94841);
  static const info = Color(0xFF6366F1);

  static const gradient = LinearGradient(colors: [deep, cyan]);
  static const gradientAlt = LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF38BDF8)]);
}

/// Cores de estado e de categoria acessíveis pelo tema (`Theme.of(context).extension`).
@immutable
class GenozPalette extends ThemeExtension<GenozPalette> {
  const GenozPalette({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.muted,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color muted;

  /// Cor de cada categoria da comparação (sempre acompanhada de ícone e texto).
  Color category(String code, ColorScheme scheme) => switch (code) {
        'shared' => success,
        'genotype_difference' => warning,
        'only_a' => scheme.primary,
        'only_b' => info,
        'missing_uncertain' => muted,
        _ => scheme.outline,
      };

  @override
  GenozPalette copyWith({Color? success, Color? warning, Color? error, Color? info, Color? muted}) => GenozPalette(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        error: error ?? this.error,
        info: info ?? this.info,
        muted: muted ?? this.muted,
      );

  @override
  GenozPalette lerp(GenozPalette? other, double t) => other == null
      ? this
      : GenozPalette(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          error: Color.lerp(error, other.error, t)!,
          info: Color.lerp(info, other.info, t)!,
          muted: Color.lerp(muted, other.muted, t)!,
        );
}

extension GenozThemeX on BuildContext {
  GenozPalette get palette => Theme.of(this).extension<GenozPalette>()!;
}

ThemeData genozTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = light
      ? ColorScheme.fromSeed(seedColor: GenozColors.petroleum).copyWith(
          primary: GenozColors.petroleum,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFD3EEF3),
          onPrimaryContainer: GenozColors.deep,
          secondary: GenozColors.cyan,
          onSecondary: GenozColors.deep,
          tertiary: GenozColors.deep,
          error: GenozColors.error,
          surface: GenozColors.surface,
          onSurface: GenozColors.textPrimary,
          onSurfaceVariant: GenozColors.textSecondary,
          surfaceContainerLowest: GenozColors.surface,
          surfaceContainerLow: GenozColors.background,
        )
      : ColorScheme.fromSeed(seedColor: GenozColors.petroleum, brightness: Brightness.dark).copyWith(
          primary: GenozColors.cyan,
          onPrimary: GenozColors.deep,
          primaryContainer: GenozColors.petroleum,
          onPrimaryContainer: Colors.white,
          secondary: GenozColors.cyan,
          tertiary: GenozColors.cyan,
          error: const Color(0xFFF08A84),
          surface: const Color(0xFF0B2F3C),
          onSurface: const Color(0xFFE6F1F4),
          onSurfaceVariant: const Color(0xFFA7B7C4),
        );
  final palette = light
      ? const GenozPalette(
          success: GenozColors.success,
          warning: Color(0xFFB45309), // âmbar escurecido: contraste de texto sobre fundo claro
          error: GenozColors.error,
          info: GenozColors.info,
          muted: GenozColors.textSecondary,
        )
      : const GenozPalette(
          success: Color(0xFF69DB7C),
          warning: GenozColors.warning,
          error: Color(0xFFF08A84),
          info: Color(0xFFA5B4FC),
          muted: Color(0xFFA7B7C4),
        );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: light ? GenozColors.background : GenozColors.deep,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: light ? GenozColors.background : GenozColors.deep,
      foregroundColor: light ? GenozColors.deep : Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: light ? GenozColors.deep : Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: light ? 1 : 0,
      shadowColor: GenozColors.deep.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: light ? GenozColors.petroleum : GenozColors.cyan,
      linearTrackColor: light ? const Color(0xFFE2EEF1) : GenozColors.petroleum.withValues(alpha: 0.4),
    ),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
  );
}
