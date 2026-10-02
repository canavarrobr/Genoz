import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/project_repository.dart';
import '../../ui/brand.dart';
import '../vault/vault_ui.dart';
import 'project_dialogs.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const GenozLogo(size: 22),
        actions: [
          IconButton(
            tooltip: l.vaultImport,
            icon: const Icon(Icons.move_to_inbox_outlined),
            onPressed: () async {
              final id = await importProjectFlow(context, ref);
              if (id != null && context.mounted) context.push('/projeto/$id');
            },
          ),
        ],
      ),
      drawer: const GenozDrawer(current: '/'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.newProject),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const BrandHeader(),
            if (list.isEmpty) EmptyState(title: l.projectsEmptyTitle, body: l.projectsEmptyBody),
            for (final s in list)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      s.project.locked ? Icons.lock_outline : Icons.folder_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(s.project.name),
                  subtitle: Text([
                    if (s.project.description != null) s.project.description!,
                    if (s.project.locked) l.vaultLocked else l.filesCount(s.fileCount),
                  ].join(' · ')),
                  onTap: () async {
                    if (s.project.locked && !await unlockProjectFlow(context, ref, s.project)) return;
                    if (context.mounted) context.push('/projeto/${s.project.id}');
                  },
                  trailing: ProjectMenu(project: s.project),
                ),
              ),
            _Footer(),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showProjectDialog(context);
    if (result == null) return;
    final project = await ref.read(projectRepositoryProvider).createProject(result.name, description: result.description);
    if (context.mounted) context.push('/projeto/${project.id}');
  }
}

class _Footer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '${l.notDiagnosis}\n${l.coreVersion(ref.watch(genozCoreProvider).coreVersion)}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
