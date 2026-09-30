import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';

typedef ProjectForm = ({String name, String? description});

Future<ProjectForm?> showProjectDialog(BuildContext context, {Project? editing}) {
  final l = AppLocalizations.of(context);
  final name = TextEditingController(text: editing?.name);
  final description = TextEditingController(text: editing?.description);
  final formKey = GlobalKey<FormState>();
  return showDialog<ProjectForm>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(editing == null ? l.newProject : l.rename),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.projectName),
              validator: (v) => (v == null || v.trim().isEmpty) ? l.projectNameRequired : null,
            ),
            if (editing == null)
              TextFormField(
                controller: description,
                decoration: InputDecoration(labelText: l.projectDescription),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, (name: name.text, description: description.text));
            }
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, {required String title, required String body}) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_outline),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
      ],
    ),
  );
  return ok ?? false;
}

enum _Action { rename, delete }

/// Menu "⋮" de um projeto: renomear e apagar.
class ProjectMenu extends ConsumerWidget {
  const ProjectMenu({super.key, required this.project, this.popAfterDelete = false});

  final Project project;
  final bool popAfterDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(projectRepositoryProvider);
    return PopupMenuButton<_Action>(
      onSelected: (a) async {
        switch (a) {
          case _Action.rename:
            final r = await showProjectDialog(context, editing: project);
            if (r != null) await repo.renameProject(project.id, r.name);
          case _Action.delete:
            final ok = await confirmDelete(
              context,
              title: l.deleteProjectTitle,
              body: l.deleteProjectBody(project.name),
            );
            if (!ok) return;
            if (popAfterDelete && context.mounted) context.pop();
            await repo.deleteProject(project.id);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: _Action.rename, child: Text(l.rename)),
        PopupMenuItem(value: _Action.delete, child: Text(l.delete)),
      ],
    );
  }
}
