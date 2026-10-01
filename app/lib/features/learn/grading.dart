// Correção automática: a resposta certa é CALCULADA do resultado real da
// análise (contagens, concordância, densidade, genótipo numa posição), nunca
// copiada de um gabarito fixo. Assim a mesma pergunta serve para qualquer par
// de arquivos (inclusive nos pacotes de aula do professor).

import 'dart:math' as math;

import '../../core/compare_models.dart';
import '../../core/genoz_core.dart';
import '../../persistence/database.dart';
import '../../persistence/analysis_repository.dart';
import 'content.dart';

class ExpectedAnswer {
  const ExpectedAnswer(this.display, this._accepts);

  /// Resposta certa como texto (mostrada depois de responder).
  final String display;
  final bool Function(String input) _accepts;

  bool accepts(String input) => _accepts(input.trim());
}

/// Calcula a resposta de um exercício para esta análise. `null` se não houver
/// como calcular (ex.: concordância sem variantes em comum).
Future<ExpectedAnswer?> expectedAnswer(Exercise e, Analysis analysis, GenozCore core) async {
  if (e.kind == ExerciseKind.choice) {
    final i = e.answer;
    if (i == null || i < 0 || i >= e.choices.length) return null;
    return ExpectedAnswer(e.choices[i].pt, (input) => input == '$i');
  }
  final compute = e.compute;
  if (compute == null) return null;
  final parts = compute.split(':');
  final s = analysis.summary;
  switch (parts.first) {
    case 'count':
      final n = parts[1].split('+').fold<int>(0, (sum, c) => sum + s.count(c));
      return ExpectedAnswer('$n', (input) => parseCount(input) == n);
    case 'percent':
      final v = switch (parts[1]) {
        'concordance' => s.genotypeConcordance,
        'jaccard' => s.jaccard,
        _ => null,
      };
      if (v == null) return null;
      final pct = v * 100;
      return ExpectedAnswer('${pct.toStringAsFixed(1)}%', (input) {
        final x = parsePercent(input);
        return x != null && (x - pct).abs() <= 0.051;
      });
    case 'top_chrom':
      final cats = parts[1].split('+').toSet();
      final map = await core.density(resultDirRelative: analysis.resultDir, filter: const RowFilter());
      final best = map.chroms.fold<int>(0, (m, c) => math.max(m, c.countFor(cats)));
      if (best == 0) return null;
      final winners = [
        for (final c in map.chroms)
          if (c.countFor(cats) == best) c.chrom,
      ];
      return ExpectedAnswer(winners.join(' / '), (input) => winners.contains(normalizeChrom(input)));
    case 'gt':
      final side = parts[1];
      final chrom = parts[2];
      final pos = int.parse(parts[3]);
      final page = await core.page(
        resultDirRelative: analysis.resultDir,
        filter: RowFilter(region: Region(chrom, pos, pos)),
        start: 0,
        count: 20,
      );
      final gts = {
        for (final r in page.rows.where((r) => r.pos == pos)) normalizeGenotype((side == 'a' ? r.a.gt : r.b.gt) ?? '—'),
      };
      if (gts.isEmpty) return null;
      return ExpectedAnswer(gts.join(' / '), (input) => gts.contains(normalizeGenotype(input)));
  }
  return null;
}

/// "1.234", "1 234", "1,234" → 1234.
int? parseCount(String input) => int.tryParse(input.replaceAll(RegExp(r'[\s.,]'), ''));

/// "83,3", "83.3%", " 83.3 % " → 83.3.
double? parsePercent(String input) =>
    double.tryParse(input.replaceAll('%', '').replaceAll(',', '.').replaceAll(RegExp(r'\s'), ''));

/// "chr7" → "7"; "x" → "X"; "chrM" → "MT".
String normalizeChrom(String input) {
  var c = input.trim();
  if (c.toLowerCase().startsWith('chr')) c = c.substring(3);
  c = c.toUpperCase();
  return c == 'M' ? 'MT' : c;
}

/// "1|0", "0/1", "1 / 0" → "0/1" (a ordem e a fase não mudam quais alelos a pessoa tem).
String normalizeGenotype(String input) {
  final t = input.replaceAll(RegExp(r'\s'), '');
  if (t == '—' || t.isEmpty) return '—';
  final alleles = t.split(RegExp(r'[/|]'));
  if (alleles.any((a) => a != '.' && int.tryParse(a) == null)) return t;
  alleles.sort((a, b) => (int.tryParse(a) ?? -1).compareTo(int.tryParse(b) ?? -1));
  return alleles.join('/');
}
