// Aba "Mapa": ideograma (cromossomos em escala) pintado pela densidade de
// variantes das categorias escolhidas. Toque num cromossomo abre o visualizador
// de região.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/compare_models.dart';
import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/database.dart';
import '../../persistence/analysis_repository.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import 'region_viewer.dart';

/// Densidade de todas as categorias (o filtro por categoria é feito aqui, sem recalcular).
final densityProvider = FutureProvider.family<DensityMap, String>((ref, analysisId) async {
  final a = await ref.watch(analysisProvider(analysisId).future);
  return ref.read(genozCoreProvider).density(resultDirRelative: a!.resultDir, filter: const RowFilter());
});

/// Cromossomo como aparece no ideograma.
class IdeogramChrom {
  const IdeogramChrom({required this.name, required this.length, this.centromere, this.density});
  final String name;
  final int length;
  final int? centromere;
  final ChromDensity? density;
}

/// Cromossomos a desenhar: o cariótipo do build (todos, mesmo sem variantes);
/// com build desconhecido, só os vistos, com a maior posição como comprimento.
List<IdeogramChrom> ideogramChroms(String build, DensityMap map) {
  if (build == 'GRCh37' || build == 'GRCh38') {
    final known = karyotype(build);
    return [
      for (final k in known)
        IdeogramChrom(name: k.name, length: k.length, centromere: k.centromere, density: map.chrom(k.name)),
      // Contigs fora do cariótipo (MT, alternativos) ficam no fim, sem centrômero.
      for (final c in map.chroms)
        if (!known.any((k) => k.name == c.chrom)) IdeogramChrom(name: c.chrom, length: c.maxPos, density: c),
    ];
  }
  return [for (final c in map.chroms) IdeogramChrom(name: c.chrom, length: c.maxPos, density: c)];
}

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key, required this.analysis});
  final Analysis analysis;

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  /// Vazio = todas as categorias.
  Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final density = ref.watch(densityProvider(widget.analysis.id));
    return density.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text('$e')),
      ),
      data: (map) {
        final s = widget.analysis.summary;
        final build = s.a.build.build;
        final chroms = ideogramChroms(build, map);
        final maxLen = chroms.fold<int>(1, (m, c) => math.max(m, c.length));
        final maxBin = chroms.fold<int>(
          1,
          (m, c) => math.max(m, (c.density?.binsFor(_selected) ?? const [0]).fold(0, math.max)),
        );
        final palette = context.palette;
        final scheme = Theme.of(context).colorScheme;
        final color = _selected.length == 1 ? palette.category(_selected.single, scheme) : scheme.primary;
        final fmt = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: Text(l.mapAll),
                    selected: _selected.isEmpty,
                    onSelected: (_) => setState(() => _selected = {}),
                  ),
                  for (final c in categoryCodes)
                    if (s.count(c) > 0)
                      FilterChip(
                        avatar: Icon(categoryIcon(c), size: 18, color: palette.category(c, scheme)),
                        label: Text(l.category(c)),
                        selected: _selected.contains(c),
                        onSelected: (on) =>
                            setState(() => _selected = on ? {..._selected, c} : ({..._selected}..remove(c))),
                      ),
                ],
              ),
            ),
            if (build != 'GRCh37' && build != 'GRCh38')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(l.mapUnknownBuild, style: TextStyle(color: palette.warning)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _Legend(color: color),
            ),
            for (final c in chroms)
              _ChromRow(
                chrom: c,
                maxLen: maxLen,
                maxBin: maxBin,
                binSize: map.binSize,
                color: color,
                categories: _selected,
                count: c.density?.countFor(_selected) ?? 0,
                countText: fmt.format(c.density?.countFor(_selected) ?? 0),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RegionViewerScreen(
                      analysis: widget.analysis,
                      initial: Region(c.name, 1, c.length),
                      categories: _selected,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(l.mapFew, style: t),
        Container(
          width: 96,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color]),
          ),
        ),
        Text(l.mapMany, style: t),
        const SizedBox(width: 8),
        Text('▾ ${l.mapCentromere}', style: t),
      ],
    );
  }
}

class _ChromRow extends StatelessWidget {
  const _ChromRow({
    required this.chrom,
    required this.maxLen,
    required this.maxBin,
    required this.binSize,
    required this.color,
    required this.categories,
    required this.count,
    required this.countText,
    required this.onTap,
  });

  final IdeogramChrom chrom;
  final int maxLen;
  final int maxBin;
  final int binSize;
  final Color color;
  final Set<String> categories;
  final int count;
  final String countText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l.mapChromSemantics(chrom.name, count),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(
            children: [
              SizedBox(width: 32, child: Text(chrom.name, style: Theme.of(context).textTheme.labelLarge)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Align(
                    alignment: Alignment.centerLeft,
                    child: CustomPaint(
                      size: Size(math.max(8, box.maxWidth * chrom.length / maxLen), 16),
                      painter: IdeogramPainter(
                        chrom: chrom,
                        bins: chrom.density?.binsFor(categories) ?? const [],
                        binSize: binSize,
                        maxBin: maxBin,
                        color: color,
                        outline: scheme.outline,
                        background: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(countText, textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desenha um cromossomo: contorno arredondado, faixas pintadas pela densidade e
/// a constrição do centrômero.
class IdeogramPainter extends CustomPainter {
  IdeogramPainter({
    required this.chrom,
    required this.bins,
    required this.binSize,
    required this.maxBin,
    required this.color,
    required this.outline,
    required this.background,
  });

  final IdeogramChrom chrom;
  final List<int> bins;
  final int binSize;
  final int maxBin;
  final Color color;
  final Color outline;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final step = binSize;
    for (var i = 0; i < bins.length; i++) {
      if (bins[i] == 0) continue;
      final x0 = size.width * (i * step) / chrom.length;
      final x1 = size.width * math.min(chrom.length, (i + 1) * step) / chrom.length;
      final alpha = 0.25 + 0.75 * math.sqrt(bins[i] / maxBin);
      canvas.drawRect(
        Rect.fromLTRB(x0, 0, math.max(x1, x0 + 1.5), size.height),
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline,
    );
    final cen = chrom.centromere;
    if (cen != null) {
      final x = size.width * cen / chrom.length;
      final notch = Path()
        ..moveTo(x - 3, 0)
        ..lineTo(x + 3, 0)
        ..lineTo(x, 4)
        ..close()
        ..moveTo(x - 3, size.height)
        ..lineTo(x + 3, size.height)
        ..lineTo(x, size.height - 4)
        ..close();
      canvas.drawPath(notch, Paint()..color = outline);
    }
  }

  @override
  bool shouldRepaint(IdeogramPainter old) =>
      old.bins != bins || old.color != color || old.maxBin != maxBin || old.chrom != chrom;
}
