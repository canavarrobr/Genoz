import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../../ui/theme.dart';
import 'content.dart';
import 'lesson_package.dart';

/// Professor: transforma esta análise num pacote de aula (`.genozaula`).
class TeacherPackageScreen extends ConsumerStatefulWidget {
  const TeacherPackageScreen({super.key, required this.analysis});
  final Analysis analysis;

  @override
  ConsumerState<TeacherPackageScreen> createState() => _TeacherPackageScreenState();
}

class _TeacherPackageScreenState extends ConsumerState<TeacherPackageScreen> {
  late final _title = TextEditingController(text: _defaultTitle());
  final _instructions = TextEditingController();
  final _selected = <String>{'p_so_a', 'p_nos_dois', 'p_concordancia'};
  bool _busy = false;

  String _defaultTitle() {
    final s = widget.analysis.summary;
    return '${s.a.sample ?? 'A'} × ${s.b.sample ?? 'B'}';
  }

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final pkg = await buildPackageFor(
        widget.analysis,
        repo: ref.read(projectRepositoryProvider),
        storage: ref.read(appStorageProvider),
        title: _title.text.trim(),
        instructions: _instructions.text.trim(),
        exercises: [
          for (final e in teacherExerciseTemplates)
            if (_selected.contains(e.id)) e,
        ],
      );
      final name = '${safeName(_title.text.trim()).replaceAll(RegExp(r'[^\w\-]+'), '_')}.$packageExtension';
      // No celular abre o "Salvar como" do sistema (null = cancelado); no navegador vira download (sempre null).
      final saved = await FilePicker.saveFile(fileName: name.length > 1 ? name : 'aula.$packageExtension', bytes: pkg);
      if (kIsWeb || saved != null) messenger.showSnackBar(SnackBar(content: Text(l.packageSaved)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.packageCreateTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.packageCreateIntro),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l.packageTitleField),
            maxLength: 120,
          ),
          TextField(
            controller: _instructions,
            decoration: InputDecoration(labelText: l.packageInstructionsField),
            minLines: 3,
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          Text(l.packageQuestions, style: Theme.of(context).textTheme.titleSmall),
          for (final e in teacherExerciseTemplates)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _selected.contains(e.id),
              title: Text(e.prompt.of(context)),
              onChanged: (v) => setState(() => v == true ? _selected.add(e.id) : _selected.remove(e.id)),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: context.palette.info),
              const SizedBox(width: 8),
              Expanded(child: Text(l.packagePrivacyNote, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy || _title.text.trim().isEmpty ? null : _export,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_alt),
            label: Text(l.packageSave),
          ),
        ],
      ),
    );
  }
}

/// Monta o pacote com os arquivos desta análise (A e B podem ser o mesmo arquivo, com amostras diferentes).
Future<Uint8List> buildPackageFor(
  Analysis analysis, {
  required ProjectRepository repo,
  required AppStorage storage,
  required String title,
  required String instructions,
  required List<Exercise> exercises,
}) async {
  final fa = (await repo.getFile(analysis.fileAId))!;
  final fb = (await repo.getFile(analysis.fileBId))!;
  final nameA = safeName(fa.displayName);
  var nameB = safeName(fb.displayName);
  if (fa.id != fb.id && nameB == nameA) nameB = 'B_$nameB';
  final files = <PackageFile>[
    PackageFile(nameA, await storage.blobs.readBytes(fa.storedPath)),
    if (fa.id != fb.id) PackageFile(nameB, await storage.blobs.readBytes(fb.storedPath)),
  ];
  return LessonPackage(
    title: title,
    instructions: instructions,
    exercises: exercises,
    a: DatasetSide(nameA, analysis.sampleA),
    b: DatasetSide(fa.id == fb.id ? nameA : nameB, analysis.sampleB),
    files: files,
  ).encode();
}
