import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../ui/theme.dart';
import '../analysis/analysis_screen.dart';
import 'content.dart';
import 'glossary_screen.dart';
import 'grading.dart';
import 'progress.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _opening = false;
  String? _error;

  /// Prepara os dados da trilha (só na primeira vez) e devolve o ID da análise.
  Future<String?> _ensureOpen(Lesson lesson, LearnContent content) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      return await openLesson(
        ref,
        lesson,
        content,
        projectName: l.learnProjectName(lesson.title.of(context)),
        projectDescription: l.learnProjectDescription,
        journalMessage: l.logCompare,
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      return null;
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openTab(Lesson lesson, LearnContent content, LessonTab tab) async {
    final id = await _ensureOpen(lesson, content);
    if (id == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisScreen(analysisId: id, initialTab: tab.index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(learnContentProvider).value;
    final lesson = content?.lessons.where((x) => x.id == widget.lessonId).firstOrNull;
    if (content == null || lesson == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final progress = ref.watch(learnProgressProvider).value ?? const LearnProgress();
    final analysisId = lesson.analysisId ?? progress.runs[lesson.id]?.analysisId;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title.of(context), overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (lesson.dataset != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                l.learnDataset(content.datasets[lesson.dataset]?.title.of(context) ?? ''),
                style: t.bodySmall?.copyWith(color: context.palette.muted),
              ),
            ),
          for (final (i, step) in lesson.steps.indexed)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 14, child: Text('${i + 1}', style: t.labelLarge)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(step.text.of(context))),
                      ],
                    ),
                    if (step.terms.isNotEmpty || step.open != null) const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final id in step.terms)
                          if (content.term(id) case final term?)
                            ActionChip(
                              avatar: const Icon(Icons.menu_book_outlined, size: 18),
                              label: Text(term.term.of(context)),
                              onPressed: () => showTermSheet(context, term),
                            ),
                        if (step.open != null)
                          FilledButton.tonalIcon(
                            onPressed: _opening ? null : () => _openTab(lesson, content, step.open!),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(l.learnOpenTab(_tabLabel(l, step.open!))),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (lesson.exercises.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(l.learnExercises, style: t.titleMedium),
            ),
            if (_opening) const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: LinearProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(_error!, style: TextStyle(color: context.palette.error)),
              ),
            if (analysisId == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  onPressed: _opening ? null : () => _ensureOpen(lesson, content),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.learnPrepare),
                ),
              )
            else
              for (final e in lesson.exercises)
                ExerciseCard(
                  key: ValueKey('${lesson.id}/${e.id}'),
                  lessonId: lesson.id,
                  exercise: e,
                  analysisId: analysisId,
                  alreadyCorrect: progress.answers[lesson.id]?[e.id] ?? false,
                ),
          ],
        ],
      ),
    );
  }

  String _tabLabel(AppLocalizations l, LessonTab tab) => switch (tab) {
    LessonTab.summary => l.tabSummary,
    LessonTab.table => l.tabTable,
    LessonTab.map => l.tabMap,
    LessonTab.qc => l.tabQc,
  };
}

class ExerciseCard extends ConsumerStatefulWidget {
  const ExerciseCard({
    super.key,
    required this.lessonId,
    required this.exercise,
    required this.analysisId,
    required this.alreadyCorrect,
  });

  final String lessonId;
  final Exercise exercise;
  final String analysisId;
  final bool alreadyCorrect;

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard> {
  final _text = TextEditingController();
  int? _choice;
  bool? _lastCorrect;
  bool _reveal = false;
  bool _busy = false;
  ExpectedAnswer? _expected;
  bool _unavailable = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final analysis = await ref.read(analysisProvider(widget.analysisId).future);
      if (analysis == null) return;
      _expected ??= await expectedAnswer(widget.exercise, analysis, ref.read(genozCoreProvider));
      final exp = _expected;
      if (exp == null) {
        setState(() => _unavailable = true);
        return;
      }
      final input = widget.exercise.kind == ExerciseKind.choice ? '${_choice ?? -1}' : _text.text;
      final ok = exp.accepts(input);
      setState(() => _lastCorrect = ok);
      await ref.read(learnProgressProvider.notifier).setAnswer(widget.lessonId, widget.exercise.id, ok);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = widget.exercise;
    final t = Theme.of(context).textTheme;
    final palette = context.palette;
    final answered = _lastCorrect ?? (widget.alreadyCorrect ? true : null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(e.prompt.of(context), style: t.titleSmall)),
                if (answered == true)
                  Icon(Icons.check_circle, color: palette.success, semanticLabel: l.exerciseCorrect),
              ],
            ),
            const SizedBox(height: 8),
            if (e.kind == ExerciseKind.choice)
              for (final (i, c) in e.choices.indexed)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_choice == i ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  title: Text(c.of(context)),
                  selected: _choice == i,
                  onTap: () => setState(() => _choice = i),
                )
            else
              TextField(
                controller: _text,
                keyboardType: switch (e.kind) {
                  ExerciseKind.number || ExerciseKind.percent => const TextInputType.numberWithOptions(decimal: true),
                  _ => TextInputType.text,
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.exerciseHint,
                  suffixText: e.kind == ExerciseKind.percent ? '%' : null,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _check(),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(onPressed: _busy ? null : _check, child: Text(l.exerciseCheck)),
                if (_lastCorrect == false && !_reveal)
                  TextButton(onPressed: () => setState(() => _reveal = true), child: Text(l.exerciseReveal)),
              ],
            ),
            if (_unavailable) Text(l.exerciseUnavailable, style: TextStyle(color: palette.warning)),
            if (_lastCorrect != null) ...[
              const SizedBox(height: 8),
              Text(
                _lastCorrect! ? l.exerciseRight : l.exerciseWrong,
                style: TextStyle(color: _lastCorrect! ? palette.success : palette.error, fontWeight: FontWeight.w600),
              ),
              Text(e.explain.of(context), style: t.bodySmall),
            ],
            if (_reveal && _expected != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.exerciseAnswer(
                    e.kind == ExerciseKind.choice && e.answer != null
                        ? e.choices[e.answer!].of(context)
                        : _expected!.display,
                  ),
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
