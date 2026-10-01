// Visualizador de região: trilha com as variantes de um trecho (uma faixa por
// categoria, cor E forma diferentes), zoom, arraste e lista do trecho.

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
import 'variant_sheet.dart';

/// Máximo de linhas buscadas por trecho (acima disso, o usuário aproxima).
const regionRowLimit = 5000;

class RegionViewerScreen extends ConsumerStatefulWidget {
  const RegionViewerScreen({super.key, required this.analysis, required this.initial, this.categories = const {}});
  final Analysis analysis;
  final Region initial;

  /// Categorias mostradas (vazio = todas).
  final Set<String> categories;

  @override
  ConsumerState<RegionViewerScreen> createState() => _RegionViewerScreenState();
}

class _RegionViewerScreenState extends ConsumerState<RegionViewerScreen> {
  late Region _region = widget.initial;
  late final _field = TextEditingController(text: widget.initial.toString());
  List<ComparisonRow> _rows = const [];
  int _total = 0;
  bool _loading = true;
  String? _error;
  int _request = 0;

  /// Deslocamento provisório durante o arraste (em pares de bases).
  double _dragBp = 0;

  /// Limite do zoom-out: o comprimento inicial (o cromossomo inteiro).
  int get _maxSpan => widget.initial.end - widget.initial.start + 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final req = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(genozCoreProvider)
          .page(
            resultDirRelative: widget.analysis.resultDir,
            filter: RowFilter(categories: widget.categories, region: _region),
            start: 0,
            count: regionRowLimit,
          );
      if (!mounted || req != _request) return;
      setState(() {
        _rows = page.rows;
        _total = page.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || req != _request) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _go(Region r) {
    setState(() {
      _region = r;
      _field.text = r.toString();
    });
    _load();
  }

  /// Novo trecho com o mesmo centro e outro tamanho (respeitando os limites do cromossomo).
  void _zoom(double factor, {double? centerFrac}) {
    final span = _region.end - _region.start + 1;
    final center = _region.start + span * (centerFrac ?? 0.5);
    final newSpan = (span * factor).round().clamp(50, _maxSpan);
    _go(_clamp((center - newSpan / 2).round(), newSpan));
  }

  Region _clamp(int start, int span) {
    final lo = widget.initial.start;
    final hi = widget.initial.end;
    final s = math.min(math.max(start, lo), math.max(lo, hi - span + 1));
    return Region(_region.chrom, s, math.min(hi, s + span - 1));
  }

  /// Só é possível navegar dentro do cromossomo aberto (é ele o limite do zoom).
  void _submitText(String text) {
    final r = ref.read(genozCoreProvider).parseRegion(text);
    if (r == null || r.chrom != widget.initial.chrom) {
      setState(() => _error = AppLocalizations.of(context).regionOutside(widget.initial.chrom));
      return;
    }
    // Uma posição só vira uma janela de 1 kb em volta dela.
    final span = r.start == r.end ? 1000 : math.min(_maxSpan, r.end - r.start + 1);
    _go(_clamp(r.start == r.end ? r.start - span ~/ 2 : r.start, span));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final lanes = [
      for (final c in categoryCodes)
        if ((widget.categories.isEmpty || widget.categories.contains(c)) && widget.analysis.summary.count(c) > 0) c,
    ];
    final span = _region.end - _region.start + 1;
    return Scaffold(
      appBar: AppBar(title: Text(l.regionTitle(_region.chrom))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _field,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l.regionField,
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                    onSubmitted: _submitText,
                  ),
                ),
                IconButton(
                  tooltip: l.regionZoomOut,
                  onPressed: span >= _maxSpan ? null : () => _zoom(4),
                  icon: const Icon(Icons.zoom_out),
                ),
                IconButton(
                  tooltip: l.regionZoomIn,
                  onPressed: span <= 50 ? null : () => _zoom(0.25),
                  icon: const Icon(Icons.zoom_in),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: LayoutBuilder(
              builder: (context, box) {
                final laneH = 26.0;
                final height = math.max(1, lanes.length) * laneH + 24;
                return GestureDetector(
                  onHorizontalDragUpdate: (d) => setState(() => _dragBp -= d.delta.dx / box.maxWidth * span),
                  onHorizontalDragEnd: (_) {
                    final shift = _dragBp.round();
                    _dragBp = 0;
                    _go(_clamp(_region.start + shift, span));
                  },
                  onDoubleTapDown: (d) => _zoom(0.25, centerFrac: d.localPosition.dx / box.maxWidth),
                  onTapUp: (d) => _tapTrack(d.localPosition, box.maxWidth, laneH, lanes),
                  child: Semantics(
                    label: l.regionTrackSemantics(_region.toString(), _total),
                    child: CustomPaint(
                      size: Size(box.maxWidth, height),
                      painter: RegionTrackPainter(
                        region: _region,
                        offsetBp: _dragBp,
                        rows: _rows,
                        lanes: lanes,
                        laneHeight: laneH,
                        colors: {for (final c in lanes) c: context.palette.category(c, Theme.of(context).colorScheme)},
                        grid: Theme.of(context).colorScheme.outlineVariant,
                        text: Theme.of(context).textTheme.bodySmall!,
                        format: fmt.format,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final c in lanes)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(12, 12),
                        painter: _MarkerPainter(c, context.palette.category(c, Theme.of(context).colorScheme)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(child: Text(l.category(c), style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _error ??
                  (_loading
                      ? l.regionLoading
                      : _total > _rows.length
                      ? l.regionShowing(_rows.length, _total)
                      : l.regionCount(_total)),
              style: TextStyle(color: _error != null ? context.palette.error : null),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                ? Center(child: Text(l.regionNoVariants))
                : ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          categoryIcon(r.category),
                          color: context.palette.category(r.category, Theme.of(context).colorScheme),
                          semanticLabel: l.category(r.category),
                        ),
                        title: Text(
                          '${r.chrom}:${fmt.format(r.pos)}  ${r.reference} > ${r.alt}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('A ${r.a.gt ?? '·'} · B ${r.b.gt ?? '·'}'),
                        onTap: () => showVariantSheet(context, widget.analysis, r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _tapTrack(Offset p, double width, double laneH, List<String> lanes) {
    final lane = (p.dy / laneH).floor();
    if (lane < 0 || lane >= lanes.length) return;
    final span = _region.end - _region.start + 1;
    ComparisonRow? best;
    var bestDx = 14.0; // tolerância em pixels
    for (final r in _rows) {
      if (r.category != lanes[lane]) continue;
      final x = (r.pos - _region.start + 0.5) / span * width;
      final dx = (x - p.dx).abs();
      if (dx < bestDx) {
        bestDx = dx;
        best = r;
      }
    }
    if (best != null) showVariantSheet(context, widget.analysis, best);
  }
}

/// Uma faixa (lane) por categoria; marcadores com forma própria; régua embaixo.
class RegionTrackPainter extends CustomPainter {
  RegionTrackPainter({
    required this.region,
    required this.offsetBp,
    required this.rows,
    required this.lanes,
    required this.laneHeight,
    required this.colors,
    required this.grid,
    required this.text,
    required this.format,
  });

  final Region region;
  final double offsetBp;
  final List<ComparisonRow> rows;
  final List<String> lanes;
  final double laneHeight;
  final Map<String, Color> colors;
  final Color grid;
  final TextStyle text;
  final String Function(num) format;

  @override
  void paint(Canvas canvas, Size size) {
    final span = region.end - region.start + 1;
    final start = region.start + offsetBp;
    double x(int pos) => (pos - start + 0.5) / span * size.width;
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < lanes.length; i++) {
      final y = i * laneHeight + laneHeight / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (final r in rows) {
      final lane = lanes.indexOf(r.category);
      if (lane < 0) continue;
      final px = x(r.pos);
      if (px < -6 || px > size.width + 6) continue;
      paintMarker(canvas, r.category, Offset(px, lane * laneHeight + laneHeight / 2), 6, colors[r.category]!);
    }
    // Régua: 5 marcas com a posição.
    final rulerY = lanes.length * laneHeight + 2;
    canvas.drawLine(Offset(0, rulerY), Offset(size.width, rulerY), line);
    for (var i = 0; i <= 4; i++) {
      final fx = size.width * i / 4;
      canvas.drawLine(Offset(fx, rulerY), Offset(fx, rulerY + 4), line);
      final label = TextPainter(
        text: TextSpan(text: format((start + span * i / 4).round()), style: text),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (fx - label.width / 2).clamp(0.0, size.width - label.width);
      label.paint(canvas, Offset(lx, rulerY + 5));
    }
  }

  @override
  bool shouldRepaint(RegionTrackPainter old) =>
      old.region != region || old.offsetBp != offsetBp || old.rows != rows || old.lanes != lanes;
}

/// Forma de cada categoria (a cor nunca é a única pista).
void paintMarker(Canvas canvas, String category, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  switch (category) {
    case 'shared':
      canvas.drawCircle(c, r, fill);
    case 'genotype_difference':
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r, c.dy)
          ..close(),
        fill,
      );
    case 'only_a':
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy + r)
          ..lineTo(c.dx - r, c.dy + r)
          ..close(),
        fill,
      );
    case 'only_b':
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - r, c.dy - r)
          ..lineTo(c.dx + r, c.dy - r)
          ..lineTo(c.dx, c.dy + r)
          ..close(),
        fill,
      );
    case 'missing_uncertain':
      canvas.drawCircle(c, r - 1, stroke);
    default:
      canvas.drawLine(c + Offset(-r, -r), c + Offset(r, r), stroke);
      canvas.drawLine(c + Offset(-r, r), c + Offset(r, -r), stroke);
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter(this.category, this.color);
  final String category;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      paintMarker(canvas, category, size.center(Offset.zero), size.width / 2, color);

  @override
  bool shouldRepaint(_MarkerPainter old) => old.category != category || old.color != color;
}
