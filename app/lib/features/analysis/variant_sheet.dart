import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compare_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/database.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import '../annotation/sources_section.dart';

Future<void> showVariantSheet(BuildContext context, Analysis analysis, ComparisonRow row) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VariantSheet(analysis: analysis, row: row),
    );

class _VariantSheet extends ConsumerStatefulWidget {
  const _VariantSheet({required this.analysis, required this.row});
  final Analysis analysis;
  final ComparisonRow row;

  @override
  ConsumerState<_VariantSheet> createState() => _VariantSheetState();
}

class _VariantSheetState extends ConsumerState<_VariantSheet> {
  final _note = TextEditingController();
  final _tags = TextEditingController();
  bool _favorite = false;
  bool _loaded = false;

  @override
  void dispose() {
    _note.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    await ref.read(analysisRepositoryProvider).saveNote(
          widget.analysis.projectId,
          widget.row.key,
          note: _note.text,
          tags: _tags.text.split(','),
          favorite: _favorite,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.noteSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = widget.row;
    final summary = widget.analysis.summary;
    final note = ref.watch(noteProvider((projectId: widget.analysis.projectId, key: r.key)));
    if (!_loaded && note.hasValue) {
      _loaded = true;
      final n = note.value;
      _note.text = n?.note ?? '';
      _tags.text = n?.tags.join(', ') ?? '';
      _favorite = n?.favorite ?? false;
    }
    final color = context.palette.category(r.category, Theme.of(context).colorScheme);

    Widget side(String title, SideView s) => Expanded(
          child: Card(
            margin: const EdgeInsets.all(4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(l.sideState(s.state), style: t.bodySmall),
                  const Divider(),
                  _kv(l.gtLabel, s.gt ?? '—'),
                  _kv(l.qualLabel, s.qual?.toString() ?? '—'),
                  _kv(l.dpLabel, s.dp?.toString() ?? '—'),
                  _kv(l.gqLabel, s.gq?.toString() ?? '—'),
                  _kv(l.filterLabel, s.filter ?? '—'),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    '${r.chrom}:${r.pos}  ${r.reference} > ${r.alt}',
                    style: t.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l.favorite,
                  icon: Icon(_favorite ? Icons.star : Icons.star_border, color: _favorite ? GenozColors.warning : null),
                  onPressed: () => setState(() => _favorite = !_favorite),
                ),
              ],
            ),
            Wrap(spacing: 8, children: [
              Chip(
                avatar: Icon(categoryIcon(r.category), color: color, size: 18),
                label: Text(l.category(r.category)),
              ),
              Chip(label: Text(l.kind(r.kind))),
              if (r.ids.isNotEmpty) Chip(label: Text(r.ids.join(', '))),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                side('A · ${summary.a.sample ?? ''}', r.a),
                side('B · ${summary.b.sample ?? ''}', r.b),
              ],
            ),
            SourcesSection(summary: summary, row: r),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: l.noteLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: InputDecoration(labelText: l.tagsLabel, border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(l.save)),
            ),
            Text(l.notDiagnosis, style: t.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(k, style: Theme.of(context).textTheme.bodySmall)),
          Text(v),
        ]),
      );
}
