import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../platform/picker_cache.dart';
import '../../ui/brand.dart';
import '../../ui/theme.dart';
import 'content.dart';
import 'glossary_screen.dart';
import 'lesson_package.dart';
import 'lesson_screen.dart';
import 'progress.dart';

/// Menu ☰ → Aprender: trilhas guiadas, glossário e aulas de professores.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(learnContentProvider);
    final progress = ref.watch(learnProgressProvider).value ?? const LearnProgress();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.learnTitle)),
      drawer: const GenozDrawer(current: '/aprender'),
      body: content.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (c) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_outlined, color: context.palette.info),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.learnIntro)),
                ],
              ),
            ),
            for (final lesson in c.lessons)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  leading: Icon(lesson.imported ? Icons.co_present_outlined : Icons.route_outlined),
                  title: Text(lesson.title.of(context), style: t.titleMedium),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lesson.summary.of(context).isNotEmpty)
                        Text(lesson.summary.of(context), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        l.learnProgress(progress.correct(lesson.id), lesson.exercises.length),
                        style: t.labelMedium?.copyWith(color: context.palette.success),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lessonId: lesson.id))),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(l.glossaryTitle),
                    subtitle: Text(l.glossarySubtitle(c.glossary.length)),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GlossaryScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_open_outlined),
                    title: Text(l.packageImport),
                    subtitle: Text(l.packageImportHint),
                    onTap: () => _importPackage(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importPackage(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;
    Uint8List bytes;
    try {
      final b = BytesBuilder(copy: false);
      await for (final chunk in file.readAsByteStream()) {
        b.add(chunk);
      }
      bytes = b.takeBytes();
    } finally {
      await clearPickerCache();
    }
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(l.packageImporting)),
            ],
          ),
        ),
      ),
    );
    final navigator = Navigator.of(context);
    try {
      final pkg = LessonPackage.decode(bytes);
      final lesson = await importLessonPackage(
        ref,
        pkg,
        projectDescription: l.packageProjectDescription,
        openStepText: LText(l.packageOpenStep, l.packageOpenStep),
        journalMessage: l.logCompare,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.packageImported(lesson.title.pt))));
      navigator.push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lessonId: lesson.id)));
    } on LessonPackageError catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.packageError(e.name))));
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
