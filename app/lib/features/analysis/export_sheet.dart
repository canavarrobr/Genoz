import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import 'table_tab.dart';

/// Exporta as linhas do filtro atual da tabela. O núcleo grava o arquivo e o
/// manifesto na pasta do projeto; depois o usuário escolhe onde salvar.
Future<void> showExportSheet(BuildContext context, WidgetRef ref, Analysis analysis) async {
  final l = AppLocalizations.of(context);
  final format = await showModalBottomSheet<ExportFormat>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.export, style: Theme.of(ctx).textTheme.titleLarge),
          ),
          for (final (f, label, icon) in [
            (ExportFormat.csv, 'CSV', Icons.table_chart_outlined),
            (ExportFormat.tsv, 'TSV', Icons.table_rows_outlined),
            (ExportFormat.json, 'JSON', Icons.data_object),
            (ExportFormat.vcf, l.exportVcf, Icons.biotech_outlined),
          ])
            ListTile(leading: Icon(icon), title: Text(label), onTap: () => Navigator.pop(ctx, f)),
        ],
      ),
    ),
  );
  if (format == null || !context.mounted) return;

  final storage = ref.read(appStorageProvider);
  final core = ref.read(genozCoreProvider);
  final filter = ref.read(tableFilterProvider(analysis.id));
  final s = analysis.summary;
  final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-').substring(0, 19);
  final name = 'genoz_${analysis.contentId.substring(0, 8)}_$stamp.${format.name}';
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await core.export(
      resultDirRelative: analysis.resultDir,
      filter: filter,
      format: format,
      sampleA: s.a.sample ?? 'A',
      sampleB: s.b.sample ?? 'B',
    );
    final n = result.rows;
    await ref.read(analysisRepositoryProvider).log(analysis.projectId, 'export', l.logExport(format.name.toUpperCase(), n));
    // No celular abre o "Salvar como" do sistema; no navegador vira um download.
    await FilePicker.saveFile(fileName: name, bytes: result.bytes);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l.exportDone(n))));
    final manifestRelative = '${analysis.resultDir}/manifest.json';
    if (await storage.blobs.exists(manifestRelative) && context.mounted) {
      final also = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.exportSaveManifest),
          content: Text(l.exportSaveManifestBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.notNow)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        ),
      );
      if (also == true) {
        await FilePicker.saveFile(fileName: '$name.manifest.json', bytes: await storage.blobs.readBytes(manifestRelative));
      }
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
  }
}
