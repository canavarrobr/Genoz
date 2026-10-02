// Família e populações: escolher o VCF multiamostra, as amostras e o trio.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/family_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../../ui/theme.dart';
import '../vault/vault_ui.dart' show withProgress;
import 'family_actions.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  ProjectFile? _file;
  final _selected = <String>{};
  String? _child, _father, _mother;
  bool _passOnly = false;
  final _minGq = TextEditingController();
  final _minDp = TextEditingController();

  @override
  void dispose() {
    _minGq.dispose();
    _minDp.dispose();
    super.dispose();
  }

  void _choose(ProjectFile f) {
    setState(() {
      _file = f;
      _selected
        ..clear()
        ..addAll(f.sampleNames.take(familyMaxSamples));
      _child = _father = _mother = null;
    });
  }

  String? get _problem {
    final l = AppLocalizations.of(context);
    if (_selected.length < 2 || _selected.length > familyMaxSamples) return l.familyTooMany(familyMaxSamples);
    final trio = [_child, _father, _mother];
    if (trio.any((x) => x != null)) {
      if (trio.any((x) => x == null) || trio.toSet().length < 3) return l.familyTrioDistinct;
    }
    return null;
  }

  Future<void> _run() async {
    final l = AppLocalizations.of(context);
    final f = _file!;
    final samples = [for (final s in f.sampleNames) if (_selected.contains(s)) s];
    final options = FamilyOptions(
      // Todas escolhidas = lista vazia (o núcleo usa todas): mesmo ID que a CLI sem --samples.
      samples: samples.length == f.sampleNames.length ? const [] : samples,
      trio: _child == null ? null : TrioRoles(child: _child!, father: _father!, mother: _mother!),
      passOnly: _passOnly,
      minGq: int.tryParse(_minGq.text.trim()),
      minDp: int.tryParse(_minDp.text.trim()),
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await withProgress(
        context,
        l.familyRunning,
        () => ref.read(familyActionsProvider).run(
              projectId: widget.projectId,
              file: f,
              options: options,
              journalMessage: l.logFamily(samples.length),
            ),
      );
      if (mounted) context.pushReplacement('/projeto/${widget.projectId}/familia/$id');
    } catch (e) {
      messenger.showSnackBar(SnackBar(duration: const Duration(seconds: 8), content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final files = (ref.watch(projectFilesProvider(widget.projectId)).value ?? const <ProjectFile>[])
        .where(isMultiSampleVcf)
        .toList();
    if (_file == null && files.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _choose(files.first));
    final chosen = [for (final s in _file?.sampleNames ?? const <String>[]) if (_selected.contains(s)) s];
    Widget roleMenu(String label, String? value, void Function(String?) set) => DropdownButtonFormField<String?>(
          initialValue: value,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: [
            const DropdownMenuItem(value: null, child: Text('—')),
            for (final s in chosen) DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => set(v)),
        );
    final problem = _file == null ? null : _problem;
    return Scaffold(
      appBar: AppBar(title: Text(l.familyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Text(l.familyIntro, style: t.bodyMedium),
          const SizedBox(height: 4),
          Text(l.familyNeedsJoint, style: t.bodySmall),
          const SizedBox(height: 12),
          if (files.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(l.familyNoMultiSample)))
          else ...[
            DropdownButtonFormField<ProjectFile>(
              initialValue: _file,
              decoration: InputDecoration(labelText: l.familyFile),
              items: [
                for (final f in files)
                  DropdownMenuItem(value: f, child: Text('${f.displayName} · ${f.sampleNames.length}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (f) => f == null ? null : _choose(f),
            ),
            const SizedBox(height: 16),
            Text(l.familySamples(_selected.length, familyMaxSamples), style: t.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final s in _file?.sampleNames ?? const <String>[])
                  FilterChip(
                    label: Text(s),
                    selected: _selected.contains(s),
                    onSelected: (v) => setState(() {
                      v ? _selected.add(s) : _selected.remove(s);
                      if (!v) {
                        if (_child == s) _child = null;
                        if (_father == s) _father = null;
                        if (_mother == s) _mother = null;
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l.familyTrioOptional, style: t.titleSmall),
            roleMenu(l.familyChild, _child, (v) => _child = v),
            roleMenu(l.familyFather, _father, (v) => _father = v),
            roleMenu(l.familyMother, _mother, (v) => _mother = v),
            const SizedBox(height: 16),
            Text(l.familyQuality, style: t.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.passOnly),
              value: _passOnly,
              onChanged: (v) => setState(() => _passOnly = v),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minGq,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'GQ ≥', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _minDp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'DP ≥', isDense: true),
                  ),
                ),
              ],
            ),
            if (problem != null) ...[
              const SizedBox(height: 12),
              Text(problem, style: t.bodySmall?.copyWith(color: context.palette.error)),
            ],
            const SizedBox(height: 16),
            Text(l.familyDisclaimer, style: t.bodySmall?.copyWith(color: context.palette.warning)),
          ],
        ],
      ),
      floatingActionButton: files.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _file == null || problem != null ? null : _run,
              icon: const Icon(Icons.family_restroom),
              label: Text(l.familyRun),
            ),
    );
  }
}
