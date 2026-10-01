// Diagrama de interseções A × B (Venn de dois conjuntos).
// As áreas NÃO são proporcionais (círculos iguais): os números dizem as
// quantidades. Variantes ausentes/incertas e não avaliadas ficam fora, à parte,
// porque não pertencem com certeza a nenhum dos lados.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/compare_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/theme.dart';

class IntersectionDiagram extends StatelessWidget {
  const IntersectionDiagram({super.key, required this.summary});
  final CompareSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final fmt = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final s = summary;
    final onlyA = s.count('only_a'), onlyB = s.count('only_b');
    final same = s.count('shared'), diff = s.count('genotype_difference');
    final missing = s.count('missing_uncertain'), notAssessed = s.count('not_assessed');
    final nameA = s.a.sample ?? 'A', nameB = s.b.sample ?? 'B';
    return Semantics(
      container: true,
      label: l.vennSemantics(nameA, nameB, onlyA, same + diff, diff, onlyB),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.vennTitle, style: t.titleMedium),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 2.1,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth, h = box.maxHeight;
                final r = h * 0.46;
                final ca = Offset(w * 0.5 - r * 0.62, h / 2), cb = Offset(w * 0.5 + r * 0.62, h / 2);
                Widget label(Offset at, List<Widget> lines) => Positioned(
                  left: at.dx - r * 0.55,
                  width: r * 1.1,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(mainAxisSize: MainAxisSize.min, children: lines),
                    ),
                  ),
                );
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _VennPainter(
                          a: ca,
                          b: cb,
                          r: r,
                          colorA: scheme.primary,
                          colorB: palette.info,
                          outline: scheme.outline,
                        ),
                      ),
                    ),
                    label(Offset(ca.dx - r * 0.45, 0), [
                      Text(fmt.format(onlyA), style: t.headlineSmall),
                      Text(l.vennOnly(nameA), style: t.bodySmall),
                    ]),
                    label(Offset(w / 2, 0), [
                      Text(fmt.format(same + diff), style: t.headlineSmall),
                      Text(l.vennBoth, style: t.bodySmall),
                      Text(l.vennBreakdown(same, diff), style: t.labelSmall),
                    ]),
                    label(Offset(cb.dx + r * 0.45, 0), [
                      Text(fmt.format(onlyB), style: t.headlineSmall),
                      Text(l.vennOnly(nameB), style: t.bodySmall),
                    ]),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(l.vennOutside(missing, notAssessed), style: t.bodySmall),
          Text(l.vennNotProportional, style: t.bodySmall?.copyWith(color: palette.muted)),
        ],
      ),
    );
  }
}

class _VennPainter extends CustomPainter {
  _VennPainter({
    required this.a,
    required this.b,
    required this.r,
    required this.colorA,
    required this.colorB,
    required this.outline,
  });
  final Offset a, b;
  final double r;
  final Color colorA, colorB, outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(a, r, Paint()..color = colorA.withValues(alpha: 0.16));
    canvas.drawCircle(b, r, Paint()..color = colorB.withValues(alpha: 0.16));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(a, r, stroke..color = colorA);
    canvas.drawCircle(b, r, stroke..color = colorB);
  }

  @override
  bool shouldRepaint(_VennPainter old) => old.a != a || old.b != b || old.r != r || old.colorA != colorA;
}
