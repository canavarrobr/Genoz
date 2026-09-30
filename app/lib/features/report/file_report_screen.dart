import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/inspect_report.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/project_repository.dart';
import '../../ui/labels.dart';

/// Relatório de validação de um arquivo importado.
class FileReportScreen extends ConsumerWidget {
  const FileReportScreen({super.key, required this.fileId});
  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final file = ref.watch(projectFileProvider(fileId));
    return Scaffold(
      appBar: AppBar(title: Text(file.value?.displayName ?? '')),
      body: file.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (f) => f == null ? Center(child: Text(l.fileNotFound)) : _ReportBody(report: f.report),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});
  final InspectReport report;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final r = report;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Card(
          color: verdictColor(r.verdict, c).withValues(alpha: 0.12),
          child: ListTile(
            leading: Icon(verdictIcon(r.verdict), color: verdictColor(r.verdict, c), size: 32),
            title: Text(l.verdict(r.verdict), style: t.titleMedium),
            subtitle: Text(l.problemsCount(r.errors, r.warnings)),
          ),
        ),
        _Section(title: l.sectionFile, children: [
          _Field(l.fieldSha256, r.sha256, mono: true, copyable: true),
          _Field(l.fieldSize, formatBytes(r.bytes)),
          _Field(l.fieldCompression, l.compression(r.compression)),
          _Field(l.fieldFormat, r.fileFormat ?? '—'),
          _Field(l.fieldRecords, l.recordsSummary(r.recordsOk, r.recordsRead, r.recordsRejected)),
          _Field(l.fieldMultiallelic, l.multiallelicSummary(r.multiallelic, r.biallelicAfterSplit)),
          _Field(l.fieldFilter, l.filterSummary(r.filterPass, r.filterFailed, r.filterMissing)),
          _Field(l.fieldSorted, r.sorted ? l.yes : l.no),
          _Field(l.fieldChromStyle, l.chromStyle(r.chromStyle)),
        ]),
        _Section(title: l.sectionBuild, children: [
          _Field(l.buildName(r.build), l.buildConfidence(r.buildConfidence)),
          for (final e in r.buildEvidence)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
              child: Text('• $e', style: t.bodySmall),
            ),
        ]),
        if (r.samples.isNotEmpty)
          _Section(title: l.sectionSamples, children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  const DataColumn(label: Text('')),
                  DataColumn(label: Text(l.colHomRef), numeric: true),
                  DataColumn(label: Text(l.colHet), numeric: true),
                  DataColumn(label: Text(l.colHomAlt), numeric: true),
                  DataColumn(label: Text(l.colMissing), numeric: true),
                ],
                rows: [
                  for (final s in r.samples)
                    DataRow(cells: [
                      DataCell(Text(s.name)),
                      DataCell(Text('${s.homRef}')),
                      DataCell(Text('${s.het}')),
                      DataCell(Text('${s.homAlt}')),
                      DataCell(Text('${s.missing}')),
                    ]),
                ],
              ),
            ),
          ]),
        _Section(title: l.sectionKinds, children: [
          for (final e in r.byKind.entries) _Field(l.kind(e.key), '${e.value}'),
        ]),
        _Section(title: l.sectionChromosomes, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final ch in r.byChrom) Chip(label: Text('${ch.raw}: ${ch.records}'))],
            ),
          ),
        ]),
        _Section(title: l.sectionProblems, children: [
          if (r.fatal != null)
            ListTile(
              leading: Icon(Icons.error, color: c.error),
              title: Text(l.readInterrupted(r.fatal!)),
            ),
          if (r.issues.isEmpty && r.fatal == null) ListTile(title: Text(l.problemsNone)),
          for (final i in r.issues)
            ListTile(
              dense: true,
              leading: Icon(i.isError ? Icons.error_outline : Icons.warning_amber,
                  color: i.isError ? c.error : Colors.orange.shade700),
              title: Text(i.message),
              subtitle: Text(i.line == 0 ? l.lineHeader : l.lineNumber(i.line)),
            ),
          if (r.issuesTruncated)
            Padding(padding: const EdgeInsets.all(16), child: Text(l.problemsTruncated, style: t.bodySmall)),
        ]),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l.notDiagnosis}\n${l.coreVersion(r.coreVersion)}',
              textAlign: TextAlign.center, style: t.bodySmall),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
              ...children,
            ],
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.mono = false, this.copyable = false});
  final String label;
  final String value;
  final bool mono;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onLongPress: copyable ? () => Clipboard.setData(ClipboardData(text: value)) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(label, style: t.bodyMedium)),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: mono ? t.bodySmall?.copyWith(fontFamily: 'monospace') : t.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
