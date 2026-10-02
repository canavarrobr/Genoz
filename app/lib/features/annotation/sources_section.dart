// "O que as fontes dizem" (ficha da variante): registros dos pacotes de anotação
// do mesmo build, sempre com fonte, versão e data. O Genoz não classifica.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/annotation_models.dart';
import '../../core/compare_models.dart';
import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/theme.dart';
import 'annotation_store.dart';

/// Build da análise para escolher pacotes (o do VCF; se desconhecido, o do outro lado).
String analysisBuild(CompareSummary s) {
  for (final b in [s.b.build.build, s.a.build.build]) {
    if (b == 'GRCh37' || b == 'GRCh38') return b;
  }
  return 'unknown';
}

/// Uma linha curta para a tabela: genes (intervalos) e o primeiro campo de cada pacote de sítios.
String annotationLine(List<AnnotHit> hits, Map<String, PackageManifest> manifests) {
  final genes = <String>{};
  final parts = <String>[];
  for (final h in hits) {
    final m = manifests[h.packageId];
    if (m == null) continue;
    if (m.isSites) {
      final values = {
        for (final r in h.records)
          if (r.fields.isNotEmpty && r.fields.first.isNotEmpty) sourceText(r.fields.first),
      };
      if (values.isNotEmpty) parts.add('${m.source.split(' ').first}: ${values.join(' / ')}');
    } else {
      genes.addAll(h.records.map((r) => r.name).where((n) => n.isNotEmpty));
    }
  }
  return [if (genes.isNotEmpty) genes.take(3).join(', '), ...parts].join(' · ');
}

/// Licença e aviso das fontes conhecidas no idioma do app (o manifesto guarda o texto em português).
String sourceLicense(String source, String raw, AppLocalizations l) => source.startsWith('ClinVar')
    ? l.clinvarLicense
    : source == 'GENCODE'
    ? l.gencodeLicense
    : raw;

String sourceDisclaimer(String source, String raw, AppLocalizations l) =>
    source.startsWith('ClinVar') && raw.isNotEmpty ? l.clinvarDisclaimer : raw;

class SourcesSection extends ConsumerStatefulWidget {
  const SourcesSection({super.key, required this.summary, required this.row});
  final CompareSummary summary;
  final ComparisonRow row;

  @override
  ConsumerState<SourcesSection> createState() => _SourcesSectionState();
}

class _SourcesSectionState extends ConsumerState<SourcesSection> {
  Future<(List<AnnotHit>, Map<String, PackageManifest>)>? _future;

  Future<(List<AnnotHit>, Map<String, PackageManifest>)> _load() async {
    final packages = await ref.read(packagesForBuildProvider(analysisBuild(widget.summary)).future);
    if (packages.isEmpty) return (const <AnnotHit>[], const <String, PackageManifest>{});
    final hits = await ref
        .read(genozCoreProvider)
        .annotate(packages: [for (final p in packages) p.dir], rows: [widget.row]);
    return (hits.single, {for (final p in packages) p.manifest.id: p.manifest});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    _future ??= _load();
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final (hits, manifests) = snap.data!;
        if (hits.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(l.sourcesTitle, style: t.titleSmall),
            const SizedBox(height: 4),
            for (final h in hits)
              if (manifests[h.packageId] case final m?)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.sourcesSays(m.source, m.version, m.date), style: t.labelLarge),
                        for (final r in h.records.take(5)) ...[
                          const SizedBox(height: 6),
                          Text(m.isSites ? '${r.name} · ${r.reference} > ${r.alt}' : r.name, style: t.bodyMedium),
                          for (final (i, f) in m.fields.indexed)
                            if (i < r.fields.length && r.fields[i].isNotEmpty)
                              Text('${f.label(lang)}: ${sourceText(r.fields[i])}', style: t.bodySmall),
                        ],
                        if (h.records.length > 5) Text(l.sourcesMore(h.records.length - 5), style: t.bodySmall),
                        if (m.disclaimer.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(sourceDisclaimer(m.source, m.disclaimer, l), style: t.bodySmall?.copyWith(color: context.palette.warning)),
                        ],
                      ],
                    ),
                  ),
                ),
            Text(l.sourcesNoClassification, style: t.bodySmall),
          ],
        );
      },
    );
  }
}
