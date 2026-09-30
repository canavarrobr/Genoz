import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../ui/theme.dart';

IconData _kindIcon(String kind) => switch (kind) {
      'import' => Icons.upload_file,
      'compare' => Icons.compare_arrows,
      'export' => Icons.file_download_outlined,
      'filter' => Icons.bookmark_outline,
      'delete_file' || 'delete_analysis' => Icons.delete_outline,
      _ => Icons.notes,
    };

/// `1:1000:A:G` → `1:1000  A > G`.
String _variantLabel(String key) {
  final p = key.split(':');
  return p.length == 4 ? '${p[0]}:${p[1]}  ${p[2]} > ${p[3]}' : key;
}

/// Diário automático do projeto e lista de notas/favoritas.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final fmt = DateFormat.yMd(Localizations.localeOf(context).toString()).add_Hm();
    final journal = ref.watch(journalProvider(projectId)).value ?? const [];
    final notes = ref.watch(notesProvider(projectId)).value ?? const [];
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.journalTitle),
          bottom: TabBar(tabs: [Tab(text: l.journalTitle), Tab(text: l.notesTitle)]),
        ),
        body: TabBarView(
          children: [
            journal.isEmpty
                ? Center(child: Text(l.journalEmpty))
                : ListView(
                    children: [
                      for (final e in journal)
                        ListTile(
                          leading: Icon(_kindIcon(e.kind)),
                          title: Text(e.kind == 'import' ? l.logImport(e.message) : e.message),
                          subtitle: Text(fmt.format(e.createdAt)),
                        ),
                    ],
                  ),
            notes.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l.notesEmpty, textAlign: TextAlign.center)))
                : ListView(
                    children: [
                      for (final n in notes)
                        ListTile(
                          leading: Icon(n.favorite ? Icons.star : Icons.sticky_note_2_outlined,
                              color: n.favorite ? GenozColors.warning : null),
                          title: Text(_variantLabel(n.variantKey)),
                          subtitle: Text([
                            if (n.note.isNotEmpty) n.note,
                            if (n.tags.isNotEmpty) n.tags.map((t) => '#$t').join(' '),
                          ].join('\n')),
                          isThreeLine: n.note.isNotEmpty && n.tags.isNotEmpty,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
