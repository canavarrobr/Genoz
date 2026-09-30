import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../../ui/labels.dart';
import '../../ui/privacy_chip.dart';
import '../analysis/analysis_screen.dart' show analysisTitle;
import '../import/import_controller.dart';
import 'project_dialogs.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final project = ref.watch(projectProvider(projectId)).value;
    final files = ref.watch(projectFilesProvider(projectId));
    final importState = ref.watch(importControllerProvider);
    ref.listen(importControllerProvider, (_, next) => _showOutcome(context, ref, next));

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? ''),
        actions: [
          IconButton(
            tooltip: l.journalTitle,
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/projeto/$projectId/diario'),
          ),
          if (project != null) ProjectMenu(project: project, popAfterDelete: true),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Align(alignment: Alignment.centerLeft, child: PrivacyChip()),
        ),
      ),
      floatingActionButton: importState is ImportRunning
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _pickAndImport(context, ref),
              icon: const Icon(Icons.upload_file),
              label: Text(l.importVcf),
            ),
      bottomSheet: importState is ImportRunning ? _ImportProgressBar(state: importState) : null,
      body: files.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 120),
          children: [
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.description_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(l.filesEmptyTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(l.filesEmptyBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
            for (final f in list) _FileTile(file: f),
            if (list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FilledButton.icon(
                  onPressed: () => context.push('/projeto/$projectId/comparar'),
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(l.compareTitle),
                ),
              ),
            _AnalysesSection(projectId: projectId),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: importState is ImportRunning
                    ? null
                    : () => ref.read(importControllerProvider.notifier).importSyntheticExample(projectId),
                icon: const Icon(Icons.science_outlined),
                label: Text(l.generateExample),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l.generateExampleHint, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImport(BuildContext context, WidgetRef ref) async {
    // FileType.any: muitos seletores não reconhecem .vcf/.gz como tipo próprio.
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;
    final controller = ref.read(importControllerProvider.notifier);
    final path = file.path;
    if (path != null) {
      await controller.importFile(projectId: projectId, sourcePath: path, displayName: file.name);
    } else {
      // Android com `content://`: lemos como fluxo de bytes.
      await controller.importStream(
        projectId: projectId,
        bytes: file.readAsByteStream(),
        displayName: file.name,
        totalBytes: await file.length(),
      );
    }
  }

  void _showOutcome(BuildContext context, WidgetRef ref, ImportState state) {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void done() => ref.read(importControllerProvider.notifier).acknowledge();
    switch (state) {
      case ImportSucceeded(:final fileName):
        messenger.showSnackBar(SnackBar(content: Text(l.importDone(fileName))));
        done();
      case ImportWasCancelled():
        messenger.showSnackBar(SnackBar(content: Text(l.importCancelled)));
        done();
      case ImportDuplicate(:final existingName):
        messenger.showSnackBar(SnackBar(content: Text(l.importDuplicate(existingName))));
        done();
      case ImportError(:final message):
        _alert(context, l.importFailedTitle, message);
        done();
      case ImportRejected(:final report):
        final details = [
          l.importInvalidBody,
          if (report.fatal != null) l.readInterrupted(report.fatal!),
          for (final i in report.issues.take(5)) '• ${i.message}',
        ].join('\n\n');
        _alert(context, l.importInvalidTitle, details);
        done();
      case ImportIdle() || ImportRunning():
        break;
    }
  }

  void _alert(BuildContext context, String title, String body) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline),
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).ok))],
        ),
      );
}

class _ImportProgressBar extends ConsumerWidget {
  const _ImportProgressBar({required this.state});
  final ImportRunning state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = state.progress;
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.importing(state.fileName), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      p == null ? '' : (p.validating ? l.importValidating : l.importCopying),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: p?.fraction),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => ref.read(importControllerProvider.notifier).cancel(),
                child: Text(l.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({required this.file});
  final ProjectFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final v = file.verdictValue;
    return Card(
      child: ListTile(
        leading: Icon(verdictIcon(v), color: verdictColor(v, context)),
        title: Text(file.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text([
          l.verdict(v),
          l.buildName(file.build),
          l.samplesCount(file.sampleNames.length),
          l.variantsCount(file.recordsOk),
          formatBytes(file.bytes),
        ].join(' · ')),
        isThreeLine: true,
        onTap: () => context.push('/projeto/${file.projectId}/arquivo/${file.id}'),
        trailing: IconButton(
          tooltip: l.delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await confirmDelete(
              context,
              title: l.deleteFileTitle,
              body: l.deleteFileBody(file.displayName),
            );
            if (!ok) return;
            await ref.read(projectRepositoryProvider).deleteFile(file);
            await ref.read(analysisRepositoryProvider).log(file.projectId, 'delete_file', l.logDeleteFile(file.displayName));
          },
        ),
      ),
    );
  }
}

class _AnalysesSection extends ConsumerWidget {
  const _AnalysesSection({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final analyses = ref.watch(analysesProvider(projectId)).value ?? const <Analysis>[];
    if (analyses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text(l.analysesTitle, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final a in analyses)
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.analytics_outlined)),
              title: Text(analysisTitle(l, a), overflow: TextOverflow.ellipsis),
              subtitle: Text(l.rowsCount(a.summary.rows)),
              onTap: () => context.push('/projeto/$projectId/analise/${a.id}'),
              trailing: IconButton(
                tooltip: l.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmDelete(context, title: l.deleteAnalysisTitle, body: l.deleteAnalysisBody);
                  if (!ok) return;
                  final repo = ref.read(analysisRepositoryProvider);
                  ref.read(genozCoreProvider).forgetResult(ref.read(appStorageProvider).absolute(a.resultDir));
                  await repo.deleteAnalysis(a);
                  await repo.log(projectId, 'delete_analysis', l.logDeleteAnalysis(analysisTitle(l, a)));
                },
              ),
            ),
          ),
      ],
    );
  }
}
