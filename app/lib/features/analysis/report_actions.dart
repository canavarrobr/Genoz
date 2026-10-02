// Relatório HTML/PDF e verificação de reprodutibilidade de uma análise (Módulo 11).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../../platform/file_saver.dart';
import '../../ui/theme.dart';
import '../vault/vault_ui.dart' show withProgress;
import 'reproducibility.dart';

Future<void> saveAnalysisReport(BuildContext context, WidgetRef ref, Analysis analysis, {required bool pdf}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  try {
    final db = ref.read(databaseProvider);
    final project = await (db.select(db.projects)..where((t) => t.id.equals(analysis.projectId))).getSingleOrNull();
    final bytes = await ref.read(genozCoreProvider).analysisReport(
      resultDirRelative: analysis.resultDir,
      summaryJson: analysis.summaryJson,
      project: project?.name ?? '—',
      generatedAt: generatedAt,
      lang: lang,
      pdf: pdf,
    );
    final name = 'genoz_relatorio_${analysis.contentId.substring(0, 8)}.${pdf ? 'pdf' : 'html'}';
    if (await saveBytes(bytes, name)) {
      await ref.read(analysisRepositoryProvider).log(analysis.projectId, 'export', l.logReport(pdf ? 'PDF' : 'HTML'));
      messenger.showSnackBar(SnackBar(content: Text(l.reportSaved)));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.vaultFailed('$e'))));
  }
}

Future<void> verifyReproducibilityFlow(BuildContext context, WidgetRef ref, Analysis analysis) async {
  final l = AppLocalizations.of(context);
  final ReproResult r;
  try {
    r = await withProgress(context, l.reproRunning, () => ref.read(reproducibilityProvider)(analysis));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.reproFailed('$e'))));
    return;
  }
  final verdict = r.reproduced ? l.reproOk(r.outputs.length) : l.reproPartial(r.identical, r.outputs.length);
  await ref.read(analysisRepositoryProvider).log(analysis.projectId, 'repro', l.logRepro(verdict));
  if (context.mounted) await showDialog<void>(context: context, builder: (_) => _ReproDialog(result: r));
}

class _ReproDialog extends StatelessWidget {
  const _ReproDialog({required this.result});
  final ReproResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final pal = context.palette;
    final r = result;
    Widget line(IconData icon, Color color, String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(a, style: t.bodyMedium)),
              const SizedBox(width: 8),
              Flexible(child: Text(b, style: t.bodySmall, textAlign: TextAlign.end)),
            ],
          ),
        );
    return AlertDialog(
      icon: Icon(r.reproduced ? Icons.verified_outlined : Icons.report_problem_outlined,
          color: r.reproduced ? pal.success : pal.warning),
      title: Text(l.reproTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.reproduced ? l.reproOk(r.outputs.length) : l.reproPartial(r.identical, r.outputs.length),
              style: t.titleSmall,
            ),
            if (!r.inputsOk) Text(l.reproNotRun, style: t.bodySmall?.copyWith(color: pal.warning)),
            if (r.error != null) Text(l.reproFailed(r.error!), style: t.bodySmall?.copyWith(color: pal.error)),
            if (r.sameId == false) Text(l.reproIdDiffers, style: t.bodySmall?.copyWith(color: pal.warning)),
            const SizedBox(height: 12),
            Text(l.reproInputs, style: t.labelLarge),
            for (final i in r.inputs)
              line(
                i.ok ? Icons.check_circle_outline : Icons.error_outline,
                i.ok ? pal.success : pal.error,
                '${i.role.toUpperCase()} · ${i.name}',
                switch (i.problem) {
                  null => l.reproInputOk,
                  'ausente' => l.reproInputMissing,
                  'alterado' => l.reproInputChanged,
                  _ => l.reproInputUnsupported,
                },
              ),
            const SizedBox(height: 12),
            Text(l.reproOutputs, style: t.labelLarge),
            for (final o in r.outputs)
              line(
                o.matches ? Icons.check_circle_outline : Icons.remove_circle_outline,
                o.matches ? pal.success : (o.actual == null ? pal.muted : pal.error),
                o.name,
                o.matches ? l.reproIdentical : (o.actual == null ? l.reproMissing : l.reproDifferent),
              ),
            const SizedBox(height: 12),
            Text(l.reproExplain, style: t.bodySmall),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(MaterialLocalizations.of(context).okButtonLabel))],
    );
  }
}
