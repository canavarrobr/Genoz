import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/compare_models.dart';
import '../../core/inspect_report.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../../ui/labels.dart';
import 'compare_controller.dart';

class CompareSetupScreen extends ConsumerStatefulWidget {
  const CompareSetupScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<CompareSetupScreen> createState() => _CompareSetupScreenState();
}

class _CompareSetupScreenState extends ConsumerState<CompareSetupScreen> {
  String? _fileA;
  String? _fileB;
  String? _sampleA;
  String? _sampleB;
  bool _passOnly = false;
  final _minQual = TextEditingController();
  final _minDp = TextEditingController();
  final _minGq = TextEditingController();
  String? _truth;

  /// FASTA de referência escolhido (`null` = sem referência).
  String? _reference;

  @override
  void dispose() {
    _minQual.dispose();
    _minDp.dispose();
    _minGq.dispose();
    super.dispose();
  }

  /// No chip × VCF não há "verdade" (o chip define os sítios).
  CompareOptions _options({required bool chip}) => CompareOptions(
        passOnly: _passOnly,
        minQual: double.tryParse(_minQual.text.replaceAll(',', '.')),
        minDp: int.tryParse(_minDp.text),
        minGq: int.tryParse(_minGq.text),
        truth: chip ? null : _truth,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(projectFilesProvider(widget.projectId)).value ?? const <ProjectFile>[];
    // A: VCF ou chip; B: só VCF (o chip define os sítios). FASTA só como referência.
    final files = all.where((f) => f.recordsOk > 0).toList();
    final filesB = files.where((f) => !f.isChip).toList();
    final fastas = all.where((f) => f.isFasta && f.verdictValue != Verdict.invalid).toList();
    final state = ref.watch(compareControllerProvider);
    ref.listen(compareControllerProvider, (_, next) {
      final c = ref.read(compareControllerProvider.notifier);
      switch (next) {
        case CompareSucceeded(:final analysisId):
          c.acknowledge();
          context.pushReplacement('/projeto/${widget.projectId}/analise/$analysisId');
        case CompareError(:final message):
          c.acknowledge();
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.error_outline),
              title: Text(l.compareFailedTitle),
              content: Text(message),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok))],
            ),
          );
        case CompareWasCancelled():
          c.acknowledge();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.compareCancelled)));
        case CompareIdle() || CompareRunning():
          break;
      }
    });

    // Pré-seleção: dois primeiros arquivos (ou o mesmo arquivo com amostras 1 e 2).
    if (_fileA == null && files.isNotEmpty && filesB.isNotEmpty) {
      // Com chip no projeto, o chip vai para A automaticamente.
      final first = files.firstWhere((f) => f.isChip, orElse: () => files.first);
      _fileA = first.id;
      _fileB = filesB.firstWhere((f) => f.id != first.id, orElse: () => filesB.first).id;
      final samples = first.sampleNames;
      if (_fileA == _fileB && samples.length > 1) _sampleB = samples[1];
    }
    ProjectFile? byId(String? id) => files.where((f) => f.id == id).firstOrNull;
    final a = byId(_fileA);
    final b = filesB.where((f) => f.id == _fileB).firstOrNull;
    final chipMode = a?.isChip ?? false;
    final running = state is CompareRunning;
    final same = a != null && a.id == b?.id && (_sampleA ?? a.sampleNames.firstOrNull) == (_sampleB ?? a.sampleNames.firstOrNull);

    return Scaffold(
      appBar: AppBar(title: Text(l.compareTitle)),
      body: files.isEmpty || filesB.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l.compareNeedsFiles)))
          : ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                _SidePicker(
                  title: l.sideA,
                  files: files,
                  fileId: _fileA,
                  sample: _sampleA,
                  onFile: (id) => setState(() {
                    _fileA = id;
                    _sampleA = null;
                  }),
                  onSample: (s) => setState(() => _sampleA = s),
                ),
                if (chipMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(l.chipModeHint, style: Theme.of(context).textTheme.bodySmall),
                  ),
                _SidePicker(
                  title: l.sideB,
                  files: filesB,
                  fileId: _fileB,
                  sample: _sampleB,
                  onFile: (id) => setState(() {
                    _fileB = id;
                    _sampleB = null;
                  }),
                  onSample: (s) => setState(() => _sampleB = s),
                ),
                if (same)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(l.sameSampleWarning, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.qualityGate, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(l.qualityGateHint, style: Theme.of(context).textTheme.bodySmall),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.passOnly),
                          value: _passOnly,
                          onChanged: (v) => setState(() => _passOnly = v),
                        ),
                        Row(
                          children: [
                            Expanded(child: _NumberField(controller: _minQual, label: l.minQualShort, decimal: true)),
                            const SizedBox(width: 8),
                            Expanded(child: _NumberField(controller: _minDp, label: l.minDpShort)),
                            const SizedBox(width: 8),
                            Expanded(child: _NumberField(controller: _minGq, label: l.minGqShort)),
                          ],
                        ),
                        // Precisão/sensibilidade não fazem sentido quando o chip define os sítios.
                        if (!chipMode) ...[
                          const SizedBox(height: 16),
                          Text(l.truthLabel, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          SegmentedButton<String?>(
                            segments: [
                              ButtonSegment(value: null, label: Text(l.truthNone)),
                              const ButtonSegment(value: 'a', label: Text('A')),
                              const ButtonSegment(value: 'b', label: Text('B')),
                            ],
                            selected: {_truth},
                            onSelectionChanged: (s) => setState(() => _truth = s.first),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (fastas.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.referenceTitle, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            chipMode ? l.referenceHintChip : l.referenceHintVcf,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String?>(
                            initialValue: _reference,
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                            items: [
                              DropdownMenuItem(value: null, child: Text(l.referenceNone)),
                              for (final f in fastas)
                                DropdownMenuItem(
                                  value: f.id,
                                  child: Text('${f.displayName} · ${l.buildName(f.build)}', overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: (v) => setState(() => _reference = v),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: files.isEmpty || filesB.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: running
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.comparing),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(value: state.fraction),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.read(compareControllerProvider.notifier).cancel(),
                            child: Text(l.cancel),
                          ),
                        ],
                      )
                    : FilledButton.icon(
                        onPressed: a == null || b == null ? null : () => _run(a, b, fastas),
                        icon: const Icon(Icons.compare_arrows),
                        label: Text(l.runCompare),
                      ),
              ),
            ),
    );
  }

  void _run(ProjectFile a, ProjectFile b, List<ProjectFile> fastas) {
    final l = AppLocalizations.of(context);
    ref.read(compareControllerProvider.notifier).run(
          projectId: widget.projectId,
          a: (file: a, sample: a.isChip ? null : _sampleA),
          b: (file: b, sample: _sampleB),
          options: _options(chip: a.isChip),
          journalMessage: l.logCompare,
          reference: fastas.where((f) => f.id == _reference).firstOrNull,
        );
  }
}

class _SidePicker extends StatelessWidget {
  const _SidePicker({
    required this.title,
    required this.files,
    required this.fileId,
    required this.sample,
    required this.onFile,
    required this.onSample,
  });

  final String title;
  final List<ProjectFile> files;
  final String? fileId;
  final String? sample;
  final ValueChanged<String?> onFile;
  final ValueChanged<String?> onSample;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final file = files.where((f) => f.id == fileId).firstOrNull;
    final samples = file?.sampleNames ?? const <String>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: fileId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.chooseFile, border: const OutlineInputBorder()),
              items: [
                for (final f in files)
                  DropdownMenuItem(
                    value: f.id,
                    child: Text('${f.displayName} · ${l.buildName(f.build)}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onFile,
            ),
            if (samples.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey(fileId),
                initialValue: sample,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.chooseSample, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: null, child: Text('${samples.first} ${l.firstSample}')),
                  for (final s in samples.skip(1)) DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: onSample,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, this.decimal = false});
  final TextEditingController controller;
  final String label;
  final bool decimal;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      );
}
