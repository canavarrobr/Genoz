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
                Widget label(Offset at, double width, String number) => Positioned(
                  left: at.dx - width / 2,
                  width: width,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(number, style: t.headlineSmall),
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
                    label(Offset(ca.dx - r * 0.5, 0), r * 0.9, fmt.format(onlyA)),
                    label(Offset(w / 2, 0), r * 0.62, fmt.format(same + diff)),
                    label(Offset(cb.dx + r * 0.5, 0), r * 0.9, fmt.format(onlyB)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _LegendLine(color: scheme.primary, number: fmt.format(onlyA), text: l.vennOnly(nameA)),
          _LegendLine(
            color: Color.lerp(scheme.primary, palette.info, 0.5)!,
            number: fmt.format(same + diff),
            text: '${l.vennBoth} (${l.vennBreakdown(same, diff)})',
          ),
          _LegendLine(color: palette.info, number: fmt.format(onlyB), text: l.vennOnly(nameB)),
          const SizedBox(height: 8),
          Text(l.vennOutside(missing, notAssessed), style: t.bodySmall),
          Text(l.vennNotProportional, style: t.bodySmall?.copyWith(color: palette.muted)),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({required this.color, required this.number, required this.text});
  final Color color;
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$number ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    ),
  );
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
