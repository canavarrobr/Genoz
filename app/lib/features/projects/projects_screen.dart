import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/project_repository.dart';
import '../../ui/privacy_chip.dart';
import 'project_dialogs.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Align(alignment: Alignment.centerLeft, child: PrivacyChip()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.newProject),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? _Empty(title: l.projectsEmptyTitle, body: l.projectsEmptyBody)
            : ListView(
                padding: const EdgeInsets.only(bottom: 96, top: 8),
                children: [
                  for (final s in list)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.folder_outlined)),
                        title: Text(s.project.name),
                        subtitle: Text([
                          if (s.project.description != null) s.project.description!,
                          l.filesCount(s.fileCount),
                        ].join(' · ')),
                        onTap: () => context.push('/projeto/${s.project.id}'),
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
    final project = await ref
        .read(projectRepositoryProvider)
        .createProject(result.name, description: result.description);
    if (context.mounted) context.push('/projeto/${project.id}');
  }
}

class _Footer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '${l.notDiagnosis}\n${l.coreVersion(ref.watch(genozCoreProvider).coreVersion)}',
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: t.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, style: t.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
