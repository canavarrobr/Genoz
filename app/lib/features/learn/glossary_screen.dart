import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import 'content.dart';

/// Glossário pesquisável (termo ou definição, sem diferenciar acentos/maiúsculas).
class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(learnContentProvider).value;
    final q = foldText(_query);
    final terms = [
      for (final g in content?.glossary ?? const <GlossaryTerm>[])
        if (q.isEmpty || foldText('${g.term.of(context)} ${g.definition.of(context)}').contains(q)) g,
    ]..sort((a, b) => foldText(a.term.of(context)).compareTo(foldText(b.term.of(context))));
    return Scaffold(
      appBar: AppBar(title: Text(l.glossaryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.glossarySearch,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: terms.isEmpty
                ? Center(child: Text(l.glossaryNone))
                : ListView.builder(
                    itemCount: terms.length,
                    itemBuilder: (context, i) => ExpansionTile(
                      title: Text(terms[i].term.of(context)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.centerLeft,
                      children: [Text(terms[i].definition.of(context))],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Definição de um termo numa folha, sem sair da trilha.
Future<void> showTermSheet(BuildContext context, GlossaryTerm term) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term.term.of(context), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(term.definition.of(context)),
        ],
      ),
    ),
  ),
);

/// Minúsculas e sem acentos, para a busca.
String foldText(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}
