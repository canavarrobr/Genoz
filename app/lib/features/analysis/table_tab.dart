import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/annotation_models.dart';
import '../../core/compare_models.dart';
import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/database.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import '../annotation/annotation_store.dart';
import '../annotation/sources_section.dart';
import 'variant_sheet.dart';

/// Filtro atual da tabela de cada análise (também usado pela exportação).
class TableFilterNotifier extends Notifier<RowFilter> {
  TableFilterNotifier(this.analysisId);
  final String analysisId;

  @override
  RowFilter build() => const RowFilter();

  void set(RowFilter f) => state = f;
}

final tableFilterProvider =
    NotifierProvider.family<TableFilterNotifier, RowFilter, String>(TableFilterNotifier.new);

const _pageSize = 100;
const _rowHeight = 64.0;

class TableTab extends ConsumerStatefulWidget {
  const TableTab({super.key, required this.analysis});
  final Analysis analysis;

  @override
  ConsumerState<TableTab> createState() => _TableTabState();
}

class _TableTabState extends ConsumerState<TableTab> with AutomaticKeepAliveClientMixin {
  final _pages = <int, List<ComparisonRow>>{};

  /// Anotação de cada página (uma lista de registros por linha).
  final _annots = <int, List<List<AnnotHit>>>{};
  List<InstalledPackage> _packages = const [];
  bool _packagesLoaded = false;
  final _loading = <int>{};
  int? _total;
  RowFilter? _loadedFor;
  String? _error;
  final _search = TextEditingController();

  @override
  bool get wantKeepAlive => true;


  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset(RowFilter f) {
    _pages.clear();
    _annots.clear();
    _loading.clear();
    _total = null;
    _error = null;
    _loadedFor = f;
    _load(0, f);
  }

  Future<void> _load(int page, RowFilter f) async {
    if (_loading.contains(page)) return;
    _loading.add(page);
    try {
      final r = await ref
          .read(genozCoreProvider)
          .page(resultDirRelative: widget.analysis.resultDir, filter: f, start: page * _pageSize, count: _pageSize);
      if (!mounted || f != _loadedFor) return;
      setState(() {
        _pages[page] = r.rows;
        _total = r.total;
      });
      await _annotate(page, r.rows, f);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _loading.remove(page);
    }
  }

  /// Anota as linhas da página com os pacotes do mesmo build (genes, ClinVar…).
  Future<void> _annotate(int page, List<ComparisonRow> rows, RowFilter f) async {
    // Anotação é extra: se qualquer coisa falhar, a tabela continua funcionando.
    try {
      if (!_packagesLoaded) {
        _packages = await ref.read(packagesForBuildProvider(analysisBuild(widget.analysis.summary)).future);
        _packagesLoaded = true;
        if (mounted) setState(() {});
      }
      if (_packages.isEmpty || rows.isEmpty) return;
      final hits = await ref.read(genozCoreProvider).annotate(packages: [for (final p in _packages) p.dir], rows: rows);
      if (mounted && f == _loadedFor) setState(() => _annots[page] = hits);
    } catch (_) {
      _packagesLoaded = true;
    }
  }

  /// Procura um gene nos pacotes de intervalos do mesmo build.
  Future<Region?> _geneRegion(String name) async {
    final packages = await ref.read(packagesForBuildProvider(analysisBuild(widget.analysis.summary)).future);
    for (final p in packages.where((p) => !p.manifest.isSites)) {
      final found = await ref.read(genozCoreProvider).findName(package: p.dir, name: name);
      if (found.isNotEmpty) {
        final r = found.first;
        return Region(r.chrom, r.start, r.end);
      }
    }
    return null;
  }

  Future<void> _applySearch(String text) async {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(tableFilterProvider(widget.analysis.id).notifier);
    final current = ref.read(tableFilterProvider(widget.analysis.id));
    final q = text.trim();
    if (q.isEmpty) {
      notifier.set(current.copyWith(region: () => null, idContains: () => null));
      return;
    }
    // Nome de gene (ex.: BRCA2, TP53) vira a região do gene, pelos pacotes de anotação.
    // rsIDs e nomes de cromossomo não são procurados como gene.
    final maybeGene = !q.contains(':') &&
        RegExp(r'^[A-Za-z][A-Za-z0-9.-]+$').hasMatch(q) &&
        !RegExp(r'^rs\d+$', caseSensitive: false).hasMatch(q) &&
        !RegExp(r'^(chr)?([0-9]{1,2}|X|Y|MT|M)$', caseSensitive: false).hasMatch(q);
    if (maybeGene) {
      final gene = await _geneRegion(q);
      if (!mounted) return;
      if (gene != null) {
        notifier.set(current.copyWith(region: () => gene, idContains: () => null));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.geneFound(q.toUpperCase(), gene.toString()))));
        return;
      }
    }
    // Sem ":" e começando com letras (rs123, syn4) é ID; com ":" ou só cromossomo é região.
    final looksLikeId = !q.contains(':') && RegExp(r'^[A-Za-z]{2,}\d').hasMatch(q);
    if (looksLikeId) {
      notifier.set(current.copyWith(idContains: () => q, region: () => null));
      return;
    }
    final region = ref.read(genozCoreProvider).parseRegion(q);
    if (region == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.regionInvalid)));
      return;
    }
    notifier.set(current.copyWith(region: () => region, idContains: () => null));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final filter = ref.watch(tableFilterProvider(widget.analysis.id));
    if (filter != _loadedFor) _reset(filter);
    final saved = ref.watch(savedFiltersProvider(widget.analysis.projectId)).value ?? const [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _applySearch,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    hintText: l.searchHint,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              _applySearch('');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: filter.activeCount > 0,
                label: Text('${filter.activeCount}'),
                child: IconButton.filledTonal(
                  tooltip: l.filters,
                  icon: const Icon(Icons.tune),
                  onPressed: () => _openFilters(filter),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in categoryCodes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    avatar: Icon(categoryIcon(c), size: 18, color: context.palette.category(c, Theme.of(context).colorScheme)),
                    label: Text(l.category(c)),
                    selected: filter.categories.contains(c),
                    onSelected: (on) => ref.read(tableFilterProvider(widget.analysis.id).notifier).set(
                          filter.copyWith(categories: on ? {...filter.categories, c} : ({...filter.categories}..remove(c))),
                        ),
                  ),
                ),
              for (final s in saved)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    avatar: const Icon(Icons.bookmark_outline, size: 18),
                    label: Text(s.name),
                    onPressed: () =>
                        ref.read(tableFilterProvider(widget.analysis.id).notifier).set(RowFilter.parse(s.filterJson)),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(_total == null ? '…' : l.rowsCount(_total!), style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              if (!filter.isEmpty)
                TextButton(
                  onPressed: () {
                    _search.clear();
                    ref.read(tableFilterProvider(widget.analysis.id).notifier).set(const RowFilter());
                  },
                  child: Text(l.clearFilters),
                ),
            ],
          ),
        ),
        Expanded(child: _buildList(l)),
      ],
    );
  }

  Widget _buildList(AppLocalizations l) {
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    final total = _total;
    if (total == null) return const Center(child: CircularProgressIndicator());
    if (total == 0) return Center(child: Text(l.noRows));
    return Scrollbar(
      child: ListView.builder(
        itemCount: total,
        // Altura fixa (rolagem rápida em milhões de linhas), mas que cresce com a fonte do sistema.
        // Com pacotes de anotação, uma terceira linha (gene, o que a fonte diz).
        itemExtent: max(_rowHeight, 20 + MediaQuery.textScalerOf(context).scale(_packages.isEmpty ? 46 : 64)),
        itemBuilder: (context, i) {
          final page = i ~/ _pageSize;
          final rows = _pages[page];
          if (rows == null) {
            _load(page, _loadedFor!);
            return const _PlaceholderRow();
          }
          final idx = i - page * _pageSize;
          if (idx >= rows.length) return const _PlaceholderRow();
          final hits = _annots[page];
          return _RowTile(
            row: rows[idx],
            annotation: hits == null || idx >= hits.length
                ? null
                : annotationLine(hits[idx], {for (final p in _packages) p.manifest.id: p.manifest}),
            onTap: () => showVariantSheet(context, widget.analysis, rows[idx]),
          );
        },
      ),
    );
  }

  Future<void> _openFilters(RowFilter current) async {
    final result = await showModalBottomSheet<RowFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: current, projectId: widget.analysis.projectId),
    );
    if (result != null) ref.read(tableFilterProvider(widget.analysis.id).notifier).set(result);
  }
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.onTap, this.annotation});
  final ComparisonRow row;
  final VoidCallback onTap;

  /// Gene e o que as fontes dizem, numa linha (ou `null`).
  final String? annotation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final color = context.palette.category(row.category, Theme.of(context).colorScheme);
    String short(String s) => s.length > 12 ? '${s.substring(0, 11)}…' : s;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(categoryIcon(row.category), color: color, semanticLabel: l.category(row.category)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${row.chrom}:${row.pos}  ${short(row.reference)} > ${short(row.alt)}',
                    style: t.bodyLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    [l.category(row.category), l.kind(row.kind), if (row.ids.isNotEmpty) row.ids.join(', ')].join(' · '),
                    style: t.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (annotation != null && annotation!.isNotEmpty)
                    Text(
                      annotation!,
                      style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('A ${row.a.gt ?? '·'}', style: t.bodySmall),
                  Text('B ${row.b.gt ?? '·'}', style: t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial, required this.projectId});
  final RowFilter initial;
  final String projectId;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<String> _categories = {...widget.initial.categories};
  late Set<String> _kinds = {...widget.initial.kinds};
  late final _region = TextEditingController(text: widget.initial.region?.toString() ?? '');
  late final _id = TextEditingController(text: widget.initial.idContains ?? '');
  late final _qual = TextEditingController(text: widget.initial.minQual?.toString() ?? '');
  late final _dp = TextEditingController(text: widget.initial.minDp?.toString() ?? '');
  late final _gq = TextEditingController(text: widget.initial.minGq?.toString() ?? '');
  String? _regionError;

  RowFilter? _build() {
    final l = AppLocalizations.of(context);
    Region? region;
    if (_region.text.trim().isNotEmpty) {
      region = ref.read(genozCoreProvider).parseRegion(_region.text);
      if (region == null) {
        setState(() => _regionError = l.regionInvalid);
        return null;
      }
    }
    String? orNull(String s) => s.trim().isEmpty ? null : s.trim();
    return RowFilter(
      categories: _categories,
      kinds: _kinds,
      region: region,
      idContains: orNull(_id.text),
      minQual: double.tryParse(_qual.text.replaceAll(',', '.')),
      minDp: int.tryParse(_dp.text),
      minGq: int.tryParse(_gq.text),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final f = _build();
    if (f == null) return;
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.saveFilter),
        content: TextField(controller: name, autofocus: true, maxLength: 80, decoration: InputDecoration(labelText: l.filterName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, name.text.trim().isNotEmpty), child: Text(l.save)),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(analysisRepositoryProvider);
    await repo.saveFilter(widget.projectId, name.text, f);
    await repo.log(widget.projectId, 'filter', l.logFilter(name.text.trim()));
    if (mounted) Navigator.pop(context, f);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget number(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
          ),
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.filters, style: t.titleLarge),
            const SizedBox(height: 12),
            Text(l.categoriesLabel, style: t.titleSmall),
            Wrap(spacing: 8, children: [
              for (final c in categoryCodes)
                FilterChip(
                  label: Text(l.category(c)),
                  selected: _categories.contains(c),
                  onSelected: (on) => setState(() => _categories = on ? {..._categories, c} : ({..._categories}..remove(c))),
                ),
            ]),
            const SizedBox(height: 12),
            Text(l.kindsLabel, style: t.titleSmall),
            Wrap(spacing: 8, children: [
              for (final k in kindCodes)
                FilterChip(
                  label: Text(l.kind(k)),
                  selected: _kinds.contains(k),
                  onSelected: (on) => setState(() => _kinds = on ? {..._kinds, k} : ({..._kinds}..remove(k))),
                ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _region,
              decoration: InputDecoration(
                labelText: l.regionLabel,
                hintText: 'chr7:117.5M-117.6M',
                errorText: _regionError,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _id,
              decoration: InputDecoration(labelText: l.idLabel, border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            Row(children: [number(_qual, l.minQualShort), const SizedBox(width: 8), number(_dp, l.minDpShort), const SizedBox(width: 8), number(_gq, l.minGqShort)]),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton.icon(onPressed: _save, icon: const Icon(Icons.bookmark_add_outlined), label: Text(l.saveFilter)),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final f = _build();
                    if (f != null) Navigator.pop(context, f);
                  },
                  child: Text(l.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
