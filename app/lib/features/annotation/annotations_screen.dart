import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../core/annotation_models.dart';
import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/picker_cache.dart';
import '../../ui/brand.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import 'annotation_store.dart';
import 'sources_section.dart';

/// Menu ☰ → Anotações: pacotes instalados, catálogo e pacote próprio.
class AnnotationsScreen extends ConsumerWidget {
  const AnnotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final installed = ref.watch(installedPackagesProvider);
    final catalog = ref.watch(annotationCatalogProvider).value ?? const <CatalogEntry>[];
    final t = Theme.of(context).textTheme;
    final installedIds = {for (final p in installed.value ?? const <InstalledPackage>[]) p.manifest.id};
    return Scaffold(
      appBar: AppBar(title: Text(l.annotTitle)),
      drawer: const GenozDrawer(current: '/anotacoes'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text(l.annotIntro)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wifi_off, size: 18, color: context.palette.info),
                const SizedBox(width: 8),
                Expanded(child: Text(l.annotNoInternet, style: t.bodySmall)),
              ],
            ),
          ),
          _SectionTitle(l.annotInstalled),
          ...installed.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [Padding(padding: const EdgeInsets.all(16), child: Text('$e'))],
            data: (list) => [for (final p in list) _InstalledCard(package: p)],
          ),
          if (catalog.any((e) => !installedIds.contains(e.id))) ...[
            _SectionTitle(l.annotCatalog),
            for (final e in catalog)
              if (!installedIds.contains(e.id)) _CatalogCard(entry: e),
          ],
          _SectionTitle(l.annotCustom),
          Card(
            child: ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(l.annotCustomImport),
              subtitle: Text(l.annotCustomHint),
              onTap: () => _importCustom(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importCustom(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final nameCtl = TextEditingController();
    var build = 'GRCh38';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.annotCustomImport),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: InputDecoration(labelText: l.annotCustomName),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'GRCh37', label: Text('GRCh37')),
                  ButtonSegment(value: 'GRCh38', label: Text('GRCh38')),
                ],
                selected: {build},
                onSelectionChanged: (s) => setState(() => build = s.single),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.annotChooseFile)),
          ],
        ),
      ),
    );
    final name = nameCtl.text.trim();
    nameCtl.dispose();
    if (ok != true || !context.mounted) return;
    final file = await _pick();
    if (file == null || !context.mounted) return;
    await _runInstall(
      context,
      l.annotBuilding,
      () => ref.read(annotationActionsProvider).custom(file, name: name.isEmpty ? file.name : name, build: build),
    );
  }
}

Future<SourceFile?> _pick() async {
  final f = await FilePicker.pickFile(type: FileType.any);
  if (f == null) return null;
  return SourceFile(name: f.name, path: f.path, open: f.readAsByteStream, size: await f.length());
}

/// Mostra o progresso, instala e avisa o resultado. Limpa o cache do seletor no fim.
Future<void> _runInstall(BuildContext context, String message, Future<PackageManifest> Function() action) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
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
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    final m = await action();
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l.annotInstalledOk(m.name, m.records))));
  } on AnnotationInstallError catch (e) {
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(e.code == 'hash' ? l.annotHashMismatch : l.annotBuildFailed(e.detail)),
      ),
    );
  } finally {
    await clearPickerCache();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _InstalledCard extends ConsumerWidget {
  const _InstalledCard({required this.package});
  final InstalledPackage package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final m = package.manifest;
    final fmt = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    return Card(
      child: ExpansionTile(
        leading: Icon(m.isSites ? Icons.place_outlined : Icons.straighten),
        title: Text(m.name),
        subtitle: Text(
          [m.source, m.build, l.annotRecords(fmt.format(m.records)), if (package.embedded) l.annotEmbedded].join(' · '),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(l.annotVersion, '${m.version} (${m.date})'),
          _Line(l.annotLicense, sourceLicense(m.source, m.license, l)),
          if (m.citation.isNotEmpty) _Line(l.annotCitation, m.citation),
          if (m.sourceUrl.isNotEmpty) _Line(l.annotSourceUrl, m.sourceUrl),
          if (m.disclaimer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(sourceDisclaimer(m.source, m.disclaimer, l), style: t.bodySmall?.copyWith(color: context.palette.warning)),
            ),
          if (!package.embedded)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref.read(annotationActionsProvider).remove(package),
                icon: const Icon(Icons.delete_outline),
                label: Text(l.delete),
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

class _CatalogCard extends ConsumerWidget {
  const _CatalogCard({required this.entry});
  final CatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final e = entry;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.name, style: t.titleMedium),
            const SizedBox(height: 4),
            Text('${e.source} · ${e.build} · ${formatBytes(e.bytes)}', style: t.bodySmall),
            const SizedBox(height: 8),
            _Line(l.annotLicense, sourceLicense(e.source, e.license, l)),
            _Line('URL', e.url),
            _Line('SHA-256', e.sha256),
            const SizedBox(height: 8),
            Text(l.annotHowTo, style: t.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => launchUrl(Uri.parse(e.url), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(l.annotOpenBrowser),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: e.url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.annotUrlCopied)));
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l.annotCopyUrl),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final file = await _pick();
                    if (file == null || !context.mounted) return;
                    await _runInstall(
                      context,
                      l.annotChecking,
                      () => ref.read(annotationActionsProvider).fromCatalog(e, file),
                    );
                  },
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(l.annotImportDownloaded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
