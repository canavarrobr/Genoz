// Contraste WCAG 2.x calculado a partir do tema real (claro e escuro).
// Texto normal ≥ 4,5:1; ícones, bordas e texto grande ≥ 3:1.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/ui/theme.dart';

double _channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double luminance(Color c) => 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrast(Color a, Color b) {
  final (la, lb) = (luminance(a), luminance(b));
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('fórmula confere com valores conhecidos', () {
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrast(const Color(0xFF777777), Colors.white), closeTo(4.48, 0.02));
  });

  for (final brightness in Brightness.values) {
    group('tema ${brightness.name}', () {
      final theme = genozTheme(brightness);
      final c = theme.colorScheme;
      final p = theme.extension<GenozPalette>()!;
      final bg = theme.scaffoldBackgroundColor;

      final texto = <String, (Color, Color)>{
        'texto sobre superfície': (c.onSurface, c.surface),
        'texto sobre fundo': (c.onSurface, bg),
        'texto secundário sobre superfície': (c.onSurfaceVariant, c.surface),
        'texto secundário sobre fundo': (c.onSurfaceVariant, bg),
        'botão (texto sobre primária)': (c.onPrimary, c.primary),
        'texto sobre container primário': (c.onPrimaryContainer, c.primaryContainer),
        'link/destaque (primária) sobre superfície': (c.primary, c.surface),
        'link/destaque (primária) sobre fundo': (c.primary, bg),
      };
      for (final MapEntry(key: nome, value: (fg, fundo)) in texto.entries) {
        test('$nome ≥ 4,5:1', () => expect(contrast(fg, fundo), greaterThanOrEqualTo(4.5)));
      }

      final icones = <String, Color>{
        'sucesso': p.success,
        'alerta': p.warning,
        'erro': p.error,
        'info': p.info,
        'neutro': p.muted,
        for (final cat in ['shared', 'genotype_difference', 'only_a', 'only_b', 'missing_uncertain'])
          'categoria $cat': p.category(cat, c),
      };
      for (final MapEntry(key: nome, value: cor) in icones.entries) {
        test('ícone $nome sobre superfície ≥ 3:1', () => expect(contrast(cor, c.surface), greaterThanOrEqualTo(3)));
      }
    });
  }

  test('texto branco no cabeçalho: ≥ 4,5:1 até o fim da área de texto (petróleo)', () {
    expect(contrast(Colors.white, GenozColors.deep), greaterThanOrEqualTo(4.5));
    expect(contrast(Colors.white, GenozColors.petroleum), greaterThanOrEqualTo(4.5));
    // Por isso o ciano só aparece na borda direita do cabeçalho:
    expect(contrast(Colors.white, GenozColors.cyan), lessThan(4.5));
  });

  test('menu lateral: texto branco sobre azul profundo e sobre o item ativo', () {
    expect(contrast(Colors.white, GenozColors.deep), greaterThanOrEqualTo(4.5));
    expect(contrast(Colors.white, GenozColors.petroleum), greaterThanOrEqualTo(4.5));
  });
}
