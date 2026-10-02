// Família e populações: resultado (parentesco, ROH, trio, interseções).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/family_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../ui/theme.dart';
import '../analysis/report_actions.dart' show runReproFlow;
import '../analysis/reproducibility.dart';
import 'family_actions.dart';

String relationLabel(AppLocalizations l, Relation r) => switch (r) {
      Relation.duplicate => l.relDuplicate,
      Relation.parentOffspring => l.relParentOffspring,
      Relation.fullSiblings => l.relFullSiblings,
      Relation.firstDegree => l.relFirstDegree,
      Relation.secondDegree => l.relSecondDegree,
      Relation.thirdDegree => l.relThirdDegree,
      Relation.unrelated => l.relUnrelated,
      Relation.insufficient => l.relInsufficient,
    };

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key, required this.familyId});
  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final analysis = ref.watch(familyAnalysisProvider(familyId)).value;
    final result = ref.watch(familyResultProvider(familyId));
    return result.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('$e'))),
      data: (r) {
        if (r == null || analysis == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(l.analysisNotFound)));
        final tabs = [
          (l.familyTabKinship, _KinshipTab(result: r)),
          (l.familyTabRoh, _RohTab(result: r)),
          if (r.trio != null) (l.familyTabTrio, _TrioTab(result: r)),
          (l.familyTabShared, _SharedTab(result: r)),
        ];
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l.familyTitle),
              actions: [
                IconButton(
                  tooltip: l.reproVerify,
                  icon: const Icon(Icons.verified_outlined),
                  onPressed: () => runReproFlow(
                    context,
                    ref,
                    projectId: analysis.projectId,
                    run: () => ref.read(familyReproducibilityProvider)(analysis),
                  ),
                ),
              ],
              bottom: TabBar(isScrollable: tabs.length > 3, tabs: [for (final t in tabs) Tab(text: t.$1)]),
            ),
            body: TabBarView(children: [for (final t in tabs) t.$2]),
          ),
        );
      },
    );
  }
}

String _fmt(BuildContext context, double v, int digits) =>
    NumberFormat.decimalPatternDigits(locale: Localizations.localeOf(context).toString(), decimalDigits: digits).format(v);

String _int(BuildContext context, int v) => NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(v);

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      color: context.palette.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: context.palette.warning),
            const SizedBox(width: 12),
            Expanded(child: Text(l.familyDisclaimer)),
          ],
        ),
      ),
    );
  }
}

class _KinshipTab extends StatelessWidget {
  const _KinshipTab({required this.result});
  final FamilyResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = result;
    final pairs = [...r.pairs]..sort((a, b) => (b.kinship ?? -9).compareTo(a.kinship ?? -9));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        const _Disclaimer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(l.familySitesUsed(_int(context, r.sitesUsed)), style: t.bodySmall),
        ),
        for (final w in r.warnings)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(w, style: t.bodySmall?.copyWith(color: context.palette.warning)),
          ),
        const SizedBox(height: 8),
        Text(l.familyMatrix, style: t.titleMedium),
        const SizedBox(height: 8),
        _KinshipMatrix(result: r),
        const SizedBox(height: 16),
        Text(l.familyPairs, style: t.titleMedium),
        for (final p in pairs)
          Card(
            child: ListTile(
              title: Text('${r.samples[p.a]} × ${r.samples[p.b]}'),
              subtitle: Text([
                relationLabel(l, p.relation),
                if (p.kinship != null) 'φ ${_fmt(context, p.kinship!, 3)}',
                '${l.ibs0Label} ${_int(context, p.ibs0)}',
                '${l.pairSites} ${_int(context, p.sites)}',
                if (p.concordance != null) '${l.concordanceLabel} ${_fmt(context, p.concordance! * 100, 1)}%',
              ].join(' · ')),
              leading: CircleAvatar(
                backgroundColor: _kinColor(context, p.kinship),
                child: Text(
                  p.kinship == null ? '?' : _fmt(context, math.max(0, p.kinship!), 2),
                  style: TextStyle(fontSize: 11, color: (p.kinship ?? 0) > 0.2 ? Colors.white : null),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(l.kinshipExplain, style: t.bodySmall),
      ],
    );
  }
}

/// Cor pelo φ: 0 → claro, 0,5 → azul-petróleo (negativos ficam claros).
Color _kinColor(BuildContext context, double? k) {
  final base = Theme.of(context).colorScheme.surfaceContainerHighest;
  if (k == null) return base;
  return Color.lerp(base, GenozColors.petroleum, (k / 0.5).clamp(0.0, 1.0))!;
}

class _KinshipMatrix extends StatelessWidget {
  const _KinshipMatrix({required this.result});
  final FamilyResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final n = r.samples.length;
    const cell = 34.0;
    const labelW = 96.0;
    Widget label(String s) => SizedBox(
          width: labelW,
          height: cell,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
            ),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < n; i++)
            Row(
              children: [
                label(r.samples[i]),
                for (var j = 0; j < n; j++)
                  Tooltip(
                    message: i == j ? r.samples[i] : '${r.samples[i]} × ${r.samples[j]}',
                    child: Container(
                      width: cell,
                      height: cell,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: i == j ? Theme.of(context).colorScheme.outlineVariant : _kinColor(context, r.pair(i, j)?.kinship),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: i == j
                          ? null
                          : Text(
                              r.pair(i, j)?.kinship == null ? '·' : _fmt(context, math.max(0, r.pair(i, j)!.kinship!), 2),
                              style: TextStyle(
                                fontSize: 10,
                                color: (r.pair(i, j)?.kinship ?? 0) > 0.2 ? Colors.white : null,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          Row(
            children: [
              const SizedBox(width: labelW),
              for (var j = 0; j < n; j++)
                SizedBox(
                  width: cell + 2,
                  child: Text('${j + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RohTab extends StatelessWidget {
  const _RohTab({required this.result});
  final FamilyResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = result;
    final maxFroh = r.roh.map((s) => s.froh ?? 0).fold<double>(0.05, math.max);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(l.rohIntro, style: t.bodyMedium),
        const SizedBox(height: 4),
        Text(l.rohMethod, style: t.bodySmall),
        const SizedBox(height: 8),
        if (!r.rohAvailable) Text(l.rohUnavailable, style: t.bodyMedium?.copyWith(color: context.palette.warning)),
        if (r.rohAvailable)
          for (final s in r.roh)
            Card(
              child: ExpansionTile(
                title: Text(r.samples[s.sample]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.runs.isEmpty
                        ? l.rohNone
                        : l.rohSummary(s.runs.length, _fmt(context, s.totalKb / 1000, 1), _fmt(context, s.froh ?? 0, 3))),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: ((s.froh ?? 0) / maxFroh).clamp(0.0, 1.0)),
                  ],
                ),
                children: [
                  for (final run in s.runs)
                    ListTile(
                      dense: true,
                      title: Text('chr${run.chrom}:${_int(context, run.start)}–${_int(context, run.end)}'),
                      subtitle: Text('${_fmt(context, run.megabases, 2)} Mb · ${run.snps} SNPs'),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _TrioTab extends StatelessWidget {
  const _TrioTab({required this.result});
  final FamilyResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = result;
    final trio = r.trio!;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [Expanded(child: Text(label)), Text(value, style: t.titleSmall)]),
        );
    final inherited = trio.paternal + trio.maternal;
    final events = [...trio.events]..sort((a, b) => (a.deNovo == b.deNovo) ? 0 : (a.deNovo ? -1 : 1));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        const _Disclaimer(),
        Text(l.trioRoles(r.samples[trio.child], r.samples[trio.father], r.samples[trio.mother]), style: t.titleSmall),
        Text(l.trioSites(_int(context, trio.sites)), style: t.bodySmall),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                row(l.trioConsistent, _int(context, trio.consistent)),
                row(l.trioDeNovo, _int(context, trio.deNovo)),
                row(l.trioOtherErrors, _int(context, trio.otherErrors)),
                if (trio.errorRate != null) row(l.trioErrorRate, '${_fmt(context, trio.errorRate! * 100, 2)}%'),
              ],
            ),
          ),
        ),
        if (inherited > 0) ...[
          const SizedBox(height: 8),
          Text(l.trioInherited, style: t.titleSmall),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: math.max(1, trio.paternal),
                  child: Container(height: 14, color: context.palette.info),
                ),
                Expanded(
                  flex: math.max(1, trio.maternal),
                  child: Container(height: 14, color: GenozColors.petroleum),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text('${_int(context, trio.paternal)} ${l.trioPaternal}')),
              Text('${_int(context, trio.maternal)} ${l.trioMaternal}'),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(l.trioDeNovoExplain, style: t.bodySmall),
        const SizedBox(height: 12),
        if (events.isNotEmpty) Text(l.trioEvents, style: t.titleMedium),
        if (trio.truncated) Text(l.trioTruncated(events.length), style: t.bodySmall),
        for (final e in events)
          Card(
            child: ListTile(
              leading: Icon(
                e.deNovo ? Icons.fiber_new_outlined : Icons.error_outline,
                color: e.deNovo ? context.palette.info : context.palette.warning,
              ),
              title: Text('chr${e.chrom}:${_int(context, e.pos)}  ${e.reference} > ${e.alt}'),
              subtitle: Text([
                e.deNovo ? l.trioEventDeNovo : l.trioEventError,
                l.trioGenotypes(e.child, e.father, e.mother),
                if (e.childQual != null) 'QUAL ${_fmt(context, e.childQual!, 0)}',
                if (e.childDp != null) 'DP ${e.childDp}',
                if (e.childGq != null) 'GQ ${e.childGq}',
              ].join(' · ')),
            ),
          ),
      ],
    );
  }
}

class _SharedTab extends StatelessWidget {
  const _SharedTab({required this.result});
  final FamilyResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = result;
    final maxCarriers = r.carriers.fold<int>(1, math.max);
    final maxCombo = r.intersections.fold<int>(1, (m, i) => math.max(m, i.count));
    Widget bar(double frac, Color color) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: frac, minHeight: 10, color: color),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(l.sharedIntro, style: t.bodyMedium),
        const SizedBox(height: 12),
        Text(l.sharedCarriers, style: t.titleMedium),
        for (var i = 0; i < r.samples.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 120, child: Text(r.samples[i], overflow: TextOverflow.ellipsis)),
                Expanded(child: bar(r.carriers[i] / maxCarriers, GenozColors.petroleum)),
                SizedBox(width: 64, child: Text(_int(context, r.carriers[i]), textAlign: TextAlign.end)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(l.sharedCombos, style: t.titleMedium),
        for (final c in r.intersections)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text([for (final s in c.samples) r.samples[s]].join(' + '), style: t.bodySmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: bar(c.count / maxCombo, context.palette.info)),
                    SizedBox(width: 64, child: Text(_int(context, c.count), textAlign: TextAlign.end)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
