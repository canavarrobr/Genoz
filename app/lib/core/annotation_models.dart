// Modelos dos pacotes de anotação (Módulo 10), no formato do `genoz_core::annotation`.

import 'dart:convert';

class AnnotField {
  const AnnotField(this.key, this.labelPt, this.labelEn);
  final String key;
  final String labelPt;
  final String labelEn;

  factory AnnotField.fromJson(Map<String, dynamic> j) => AnnotField(
    j['key'] as String,
    j['label_pt'] as String? ?? j['key'] as String,
    j['label_en'] as String? ?? j['key'] as String,
  );

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelPt;
}

/// `manifest.json` de um pacote.
class PackageManifest {
  const PackageManifest({
    required this.id,
    required this.name,
    required this.kind,
    required this.build,
    required this.source,
    required this.sourceUrl,
    required this.version,
    required this.date,
    required this.license,
    required this.licenseUrl,
    required this.citation,
    required this.disclaimer,
    required this.fields,
    required this.records,
    required this.inputSha256,
  });

  final String id;
  final String name;

  /// `sites` ou `intervals`.
  final String kind;
  final String build;
  final String source;
  final String sourceUrl;
  final String version;
  final String date;
  final String license;
  final String licenseUrl;
  final String citation;
  final String disclaimer;
  final List<AnnotField> fields;
  final int records;
  final String inputSha256;

  bool get isSites => kind == 'sites';

  factory PackageManifest.fromJson(Map<String, dynamic> j) => PackageManifest(
    id: j['id'] as String,
    name: j['name'] as String,
    kind: j['kind'] as String,
    build: j['build'] as String,
    source: j['source'] as String? ?? '',
    sourceUrl: j['source_url'] as String? ?? '',
    version: j['version'] as String? ?? '',
    date: j['date'] as String? ?? '',
    license: j['license'] as String? ?? '',
    licenseUrl: j['license_url'] as String? ?? '',
    citation: j['citation'] as String? ?? '',
    disclaimer: j['disclaimer'] as String? ?? '',
    fields: [for (final f in j['fields'] as List? ?? const []) AnnotField.fromJson(f as Map<String, dynamic>)],
    records: j['records'] as int? ?? 0,
    inputSha256: j['input_sha256'] as String? ?? '',
  );

  factory PackageManifest.parse(String json) => PackageManifest.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

class AnnotRecord {
  const AnnotRecord({
    required this.chrom,
    required this.start,
    required this.end,
    required this.reference,
    required this.alt,
    required this.name,
    required this.fields,
  });

  final String chrom;
  final int start;
  final int end;
  final String reference;
  final String alt;
  final String name;
  final List<String> fields;

  factory AnnotRecord.fromJson(Map<String, dynamic> j) => AnnotRecord(
    chrom: j['chrom'] as String,
    start: j['start'] as int,
    end: j['end'] as int,
    reference: j['ref'] as String? ?? '',
    alt: j['alt'] as String? ?? '',
    name: j['name'] as String? ?? '',
    fields: (j['fields'] as List).cast<String>(),
  );

  static List<AnnotRecord> parseList(String json) => [
    for (final r in jsonDecode(json) as List) AnnotRecord.fromJson(r as Map<String, dynamic>),
  ];
}

/// Registros de um pacote que anotam uma linha.
class AnnotHit {
  const AnnotHit(this.packageId, this.records);
  final String packageId;
  final List<AnnotRecord> records;

  /// `[[hit, hit], [], ...]` — uma lista por linha pedida.
  static List<List<AnnotHit>> parseRows(String json) => [
    for (final row in jsonDecode(json) as List)
      [
        for (final h in row as List)
          AnnotHit((h as Map<String, dynamic>)['package'] as String, [
            for (final r in h['records'] as List) AnnotRecord.fromJson(r as Map<String, dynamic>),
          ]),
      ],
  ];
}

/// Texto da fonte para exibição: ClinVar usa `_` no lugar de espaço e `|` entre itens.
String sourceText(String raw) => raw.replaceAll('_', ' ').replaceAll('|', '; ');

/// Item do catálogo de pacotes que podem ser baixados (pelo navegador do sistema).
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.build,
    required this.url,
    required this.bytes,
    required this.sha256,
    required this.meta,
  });

  final String id;
  final String name;

  /// Construtor no núcleo: `clinvar`, `gtf` ou `custom`.
  final String kind;
  final String build;
  final String url;
  final int bytes;
  final String sha256;

  /// Metadados passados ao construtor (fonte, versão, licença, citação…).
  final Map<String, dynamic> meta;

  String get license => meta['license'] as String? ?? '';
  String get source => meta['source'] as String? ?? '';
  String get version => meta['version'] as String? ?? '';

  factory CatalogEntry.fromJson(Map<String, dynamic> j) => CatalogEntry(
    id: j['id'] as String,
    name: j['name'] as String,
    kind: j['kind'] as String,
    build: j['build'] as String,
    url: j['url'] as String,
    bytes: j['bytes'] as int,
    sha256: j['sha256'] as String,
    meta: j['meta'] as Map<String, dynamic>,
  );
}
