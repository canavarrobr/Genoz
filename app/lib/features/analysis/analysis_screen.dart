import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compare_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import 'export_sheet.dart';
import 'intersection_diagram.dart';
import 'map_tab.dart';
import 'table_tab.dart';

/// Estatísticas de QC de A e B, lidas dos arquivos da análise.
final analysisStatsProvider = FutureProvider.family<(SampleStats, SampleStats), String>((ref, analysisId) async {
  final a = await ref.watch(analysisProvider(analysisId).future);
  final blobs = ref.read(appStorageProvider).blobs;
  final sa = SampleStats.parse(await blobs.readString('${a!.resultDir}/stats_a.json'));
  final sb = SampleStats.parse(await blobs.readString('${a.resultDir}/stats_b.json'));
  return (sa, sb);
});

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key, required this.analysisId});
  final String analysisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final analysis = ref.watch(analysisProvider(analysisId));
    return analysis.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (a) {
        if (a == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(l.analysisNotFound)));
        final s = a.summary;
        final title = l.analysisVs(s.a.sample ?? 'A', s.b.sample ?? 'B');
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: l.export,
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () => showExportSheet(context, ref, a),
                ),
              ],
              bottom: TabBar(tabs: [Tab(text: l.tabSummary), Tab(text: l.tabTable), Tab(text: l.tabMap), Tab(text: l.tabQc)]),
            ),
            body: TabBarView(
              children: [
                _SummaryTab(summary: s),
                TableTab(analysis: a),
                MapTab(analysis: a),
                _QcTab(analysisId: analysisId),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.summary});
  final CompareSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final s = summary;
    final max = s.counts.values.fold<int>(1, (m, v) => v > m ? v : m);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.rowsCount(s.rows), style: t.titleMedium),
                const SizedBox(height: 12),
                for (final c in categoryCodes)
                  _CategoryBar(code: c, label: l.category(c), value: s.count(c), max: max),
              ],
            ),
          ),
        ),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: IntersectionDiagram(summary: s))),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _Metric(label: l.concordance, value: percent(s.genotypeConcordance))),
                Expanded(child: _Metric(label: l.jaccard, value: percent(s.jaccard))),
              ],
            ),
          ),
        ),
        if (s.benchmark != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.benchmarkTitle(s.benchmark!.truth.toUpperCase()), style: t.titleSmall),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {0: FlexColumnWidth(1.2)},
                    children: [
                      TableRow(children: [
                        const SizedBox(),
                        Text(l.precision, style: t.labelMedium),
                        Text(l.recall, style: t.labelMedium),
                        Text(l.f1, style: t.labelMedium),
                      ]),
                      for (final (name, m) in [
                        (l.classAll, s.benchmark!.all),
                        ('SNV', s.benchmark!.snv),
                        ('indel', s.benchmark!.indel),
                      ])
                        TableRow(children: [
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(name)),
                          Text(percent(m.precision)),
                          Text(percent(m.recall)),
                          Text(percent(m.f1)),
                        ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (s.warnings.isNotEmpty || s.mode == 'in_memory' || !_hasCoverage(s))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.warningsTitle, style: t.titleSmall),
                  const SizedBox(height: 8),
                  for (final w in s.warnings) _Bullet(w),
                  if (!_hasCoverage(s)) _Bullet(l.absenceHint),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l.notDiagnosis, textAlign: TextAlign.center, style: t.bodySmall),
        ),
      ],
    );
  }

  /// "Somente em A/B" é confiável quando os dois lados informam cobertura (BED),
  /// ou quando não há nenhuma linha nessas categorias.
  bool _hasCoverage(CompareSummary s) =>
      (s.a.callableRegions && s.b.callableRegions) || s.count('only_a') + s.count('only_b') == 0;
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: context.palette.info),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.code, required this.label, required this.value, required this.max});
  final String code;
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.category(code, Theme.of(context).colorScheme);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(categoryIcon(code), size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: value / max, minHeight: 10, color: color),
            ),
          ),
          SizedBox(width: 64, child: Text('$value', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: t.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
        Text(label, style: t.bodySmall),
      ],
    );
  }
}

class _QcTab extends ConsumerWidget {
  const _QcTab({required this.analysisId});
  final String analysisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stats = ref.watch(analysisStatsProvider(analysisId));
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (pair) {
        final (a, b) = pair;
        String ratio(double? v) => v == null ? '—' : v.toStringAsFixed(2);
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _CompareTable(rows: [
              (l.carriers, '${a.carriers}', '${b.carriers}'),
              ('Ti/Tv', ratio(a.tiTv), ratio(b.tiTv)),
              (l.hetHom, ratio(a.hetHomRatio), ratio(b.hetHomRatio)),
              (l.missingRate, percent(a.missingRate), percent(b.missingRate)),
              (l.lowQualityCount, '${a.lowQuality}', '${b.lowQuality}'),
              for (final k in kindCodes)
                if ((a.byKind[k] ?? 0) + (b.byKind[k] ?? 0) > 0) (l.kind(k), '${a.byKind[k] ?? 0}', '${b.byKind[k] ?? 0}'),
            ], footnote: l.tiTvHint),
            _Histogram(title: l.dpDistribution, a: a.dpHist, b: b.dpHist),
            _Histogram(title: l.gqDistribution, a: a.gqHist, b: b.gqHist),
            _Histogram(title: l.qualDistribution, a: a.qualHist, b: b.qualHist),
            if (a.xHetFraction != null || b.xHetFraction != null)
              _CompareTable(
                rows: [(l.xHet, percent(a.xHetFraction), percent(b.xHetFraction))],
                footnote: l.xHetHint,
              ),
          ],
        );
      },
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.rows, this.footnote});
  final List<(String, String, String)> rows;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              columnWidths: const {0: FlexColumnWidth(2)},
              children: [
                TableRow(children: [
                  const SizedBox(),
                  Text('A', style: t.labelLarge, textAlign: TextAlign.end),
                  Text('B', style: t.labelLarge, textAlign: TextAlign.end),
                ]),
                for (final (label, va, vb) in rows)
                  TableRow(children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(label)),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(va, textAlign: TextAlign.end)),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(vb, textAlign: TextAlign.end)),
                  ]),
              ],
            ),
            if (footnote != null) ...[const SizedBox(height: 8), Text(footnote!, style: t.bodySmall)],
          ],
        ),
      ),
    );
  }
}

/// Histograma A × B em barras horizontais (estilo "barras de frequência" do guia).
class _Histogram extends StatelessWidget {
  const _Histogram({required this.title, required this.a, required this.b});
  final String title;
  final List<HistBin> a;
  final List<HistBin> b;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final totalA = a.fold<int>(0, (s, x) => s + x.count);
    final totalB = b.fold<int>(0, (s, x) => s + x.count);
    if (totalA + totalB == 0) return const SizedBox.shrink();
    double frac(int v, int total) => total == 0 ? 0 : v / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleSmall),
            const SizedBox(height: 4),
            Row(children: [
              _Legend(color: c.primary, label: 'A'),
              const SizedBox(width: 16),
              _Legend(color: GenozColors.cyan, label: 'B'),
            ]),
            const SizedBox(height: 8),
            for (var i = 0; i < a.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(width: 64, child: Text(a[i].label, style: t.bodySmall)),
                    Expanded(
                      child: Column(
                        children: [
                          LinearProgressIndicator(value: frac(a[i].count, totalA), minHeight: 6, color: c.primary),
                          const SizedBox(height: 2),
                          LinearProgressIndicator(
                            value: frac(i < b.length ? b[i].count : 0, totalB),
                            minHeight: 6,
                            color: GenozColors.cyan,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        '${a[i].count} / ${i < b.length ? b[i].count : 0}',
                        style: t.bodySmall,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label),
      ]);
}

/// Usado pela lista de análises do projeto.
String analysisTitle(AppLocalizations l, Analysis a) {
  final s = a.summary;
  return l.analysisVs(s.a.sample ?? 'A', s.b.sample ?? 'B');
}
