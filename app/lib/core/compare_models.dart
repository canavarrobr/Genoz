// Modelos da comparação A × B, lidos do JSON produzido pelo núcleo Rust
// (`genoz_core::compare` e `genoz_core::stats`). Só leitura e serialização:
// nenhuma regra científica é reimplementada aqui.

import 'dart:convert';

/// Categorias na ordem em que aparecem nas telas.
const categoryCodes = [
  'shared',
  'genotype_difference',
  'only_a',
  'only_b',
  'missing_uncertain',
  'not_assessed',
];

const kindCodes = ['snv', 'mnv', 'insertion', 'deletion', 'complex', 'structural', 'other'];

double? _d(Object? v) => (v as num?)?.toDouble();
Map<String, int> _counts(Object? m) =>
    (m as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt()));

class BuildInfo {
  const BuildInfo(this.build, this.confidence, this.evidence);
  final String build;
  final String confidence;
  final List<String> evidence;

  factory BuildInfo.fromJson(Map<String, dynamic> j) =>
      BuildInfo(j['build'] as String, j['confidence'] as String, (j['evidence'] as List).cast<String>());
}

class SideInfo {
  const SideInfo({
    required this.label,
    required this.sample,
    required this.build,
    required this.records,
    required this.rejectedLines,
    required this.duplicateKeys,
    required this.callableRegions,
  });

  final String label;
  final String? sample;
  final BuildInfo build;
  final int records;
  final int rejectedLines;
  final int duplicateKeys;

  /// Um BED de regiões avaliadas foi informado para este lado.
  final bool callableRegions;

  factory SideInfo.fromJson(Map<String, dynamic> j) => SideInfo(
        label: j['label'] as String,
        sample: j['sample'] as String?,
        build: BuildInfo.fromJson(j['build'] as Map<String, dynamic>),
        records: j['records'] as int,
        rejectedLines: j['rejected_lines'] as int,
        duplicateKeys: j['duplicate_keys'] as int,
        callableRegions: j['callable_regions'] as bool? ?? false,
      );
}

class ClassMetrics {
  const ClassMetrics(this.tp, this.fp, this.fn, this.precision, this.recall, this.f1);
  final int tp;
  final int fp;
  final int fn;
  final double? precision;
  final double? recall;
  final double? f1;

  factory ClassMetrics.fromJson(Map<String, dynamic> j) => ClassMetrics(
        j['true_positives'] as int,
        j['false_positives'] as int,
        j['false_negatives'] as int,
        _d(j['precision']),
        _d(j['recall']),
        _d(j['f1']),
      );
}

class Benchmark {
  const Benchmark(this.truth, this.all, this.snv, this.indel);

  /// `a` ou `b`.
  final String truth;
  final ClassMetrics all;
  final ClassMetrics snv;
  final ClassMetrics indel;

  factory Benchmark.fromJson(Map<String, dynamic> j) => Benchmark(
        j['truth'] as String,
        ClassMetrics.fromJson(j['all'] as Map<String, dynamic>),
        ClassMetrics.fromJson(j['snv'] as Map<String, dynamic>),
        ClassMetrics.fromJson(j['indel'] as Map<String, dynamic>),
      );
}

class CompareSummary {
  const CompareSummary({
    required this.mode,
    required this.a,
    required this.b,
    required this.rows,
    required this.counts,
    required this.byKind,
    required this.genotypeConcordance,
    required this.jaccard,
    required this.benchmark,
    required this.warnings,
    this.chip,
  });

  /// `streaming` ou `in_memory`.
  final String mode;
  final SideInfo a;
  final SideInfo b;
  final int rows;
  final Map<String, int> counts;
  final Map<String, Map<String, int>> byKind;
  final double? genotypeConcordance;
  final double? jaccard;
  final Benchmark? benchmark;
  final List<String> warnings;

  /// Só na comparação chip × sequenciamento (A = chip, B = VCF).
  final ChipCompareInfo? chip;

  int count(String category) => counts[category] ?? 0;

  factory CompareSummary.fromJson(Map<String, dynamic> j) => CompareSummary(
        mode: j['mode'] as String,
        a: SideInfo.fromJson(j['a'] as Map<String, dynamic>),
        b: SideInfo.fromJson(j['b'] as Map<String, dynamic>),
        rows: j['rows'] as int,
        counts: _counts(j['counts']),
        byKind: (j['by_kind'] as Map<String, dynamic>).map((k, v) => MapEntry(k, _counts(v))),
        genotypeConcordance: _d(j['genotype_concordance']),
        jaccard: _d(j['jaccard']),
        benchmark: j['benchmark'] == null ? null : Benchmark.fromJson(j['benchmark'] as Map<String, dynamic>),
        warnings: (j['warnings'] as List).cast<String>(),
        chip: j['chip'] == null ? null : ChipCompareInfo.fromJson(j['chip'] as Map<String, dynamic>),
      );

  factory CompareSummary.parse(String json) => CompareSummary.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

/// Números próprios da comparação chip × sequenciamento.
class ChipCompareInfo {
  const ChipCompareInfo({
    required this.sites,
    required this.noCalls,
    required this.indelsSkipped,
    required this.vcfVariantsOffChip,
    required this.unknownReference,
    required this.referenceNotAssessed,
    required this.possibleStrandFlips,
    required this.referenceMismatches,
    required this.referenceUsed,
    required this.nonrefConcordance,
  });

  final int sites;
  final int noCalls;
  final int indelsSkipped;
  final int vcfVariantsOffChip;
  final int unknownReference;
  final int referenceNotAssessed;
  final int possibleStrandFlips;
  final int referenceMismatches;
  final bool referenceUsed;
  final double? nonrefConcordance;

  factory ChipCompareInfo.fromJson(Map<String, dynamic> j) => ChipCompareInfo(
        sites: j['sites'] as int,
        noCalls: j['no_calls'] as int,
        indelsSkipped: j['indels_skipped'] as int,
        vcfVariantsOffChip: j['vcf_variants_off_chip'] as int,
        unknownReference: j['unknown_reference'] as int,
        referenceNotAssessed: j['reference_not_assessed'] as int,
        possibleStrandFlips: j['possible_strand_flips'] as int,
        referenceMismatches: j['reference_mismatches'] as int,
        referenceUsed: j['reference_used'] as bool,
        nonrefConcordance: _d(j['nonref_concordance']),
      );
}

class HistBin {
  const HistBin(this.lo, this.hi, this.count);
  final double lo;
  final double? hi;
  final int count;

  factory HistBin.fromJson(Map<String, dynamic> j) => HistBin(_d(j['lo'])!, _d(j['hi']), j['count'] as int);

  String get label => hi == null ? '≥${lo.toStringAsFixed(0)}' : '${lo.toStringAsFixed(0)}–${hi!.toStringAsFixed(0)}';
}

class SampleStats {
  const SampleStats({
    required this.label,
    required this.callsTotal,
    required this.carriers,
    required this.homRef,
    required this.het,
    required this.homAlt,
    required this.missing,
    required this.lowQuality,
    required this.byKind,
    required this.transitions,
    required this.transversions,
    required this.tiTv,
    required this.hetHomRatio,
    required this.missingRate,
    required this.qualHist,
    required this.dpHist,
    required this.gqHist,
    required this.xHetFraction,
    required this.xParExcluded,
  });

  final String label;
  final int callsTotal;
  final int carriers;
  final int homRef;
  final int het;
  final int homAlt;
  final int missing;
  final int lowQuality;
  final Map<String, int> byKind;
  final int transitions;
  final int transversions;
  final double? tiTv;
  final double? hetHomRatio;
  final double? missingRate;
  final List<HistBin> qualHist;
  final List<HistBin> dpHist;
  final List<HistBin> gqHist;
  final double? xHetFraction;
  final bool xParExcluded;

  static List<HistBin> _hist(Object? l) =>
      (l as List).map((b) => HistBin.fromJson(b as Map<String, dynamic>)).toList();

  factory SampleStats.fromJson(Map<String, dynamic> j) {
    final x = j['x_heterozygosity'] as Map<String, dynamic>;
    return SampleStats(
      label: j['label'] as String,
      callsTotal: j['calls_total'] as int,
      carriers: j['carriers'] as int,
      homRef: j['hom_ref'] as int,
      het: j['het'] as int,
      homAlt: j['hom_alt'] as int,
      missing: j['missing'] as int,
      lowQuality: j['low_quality'] as int,
      byKind: _counts(j['by_kind']),
      transitions: j['transitions'] as int,
      transversions: j['transversions'] as int,
      tiTv: _d(j['ti_tv']),
      hetHomRatio: _d(j['het_hom_ratio']),
      missingRate: _d(j['missing_rate']),
      qualHist: _hist(j['qual_hist']),
      dpHist: _hist(j['dp_hist']),
      gqHist: _hist(j['gq_hist']),
      xHetFraction: _d(x['het_fraction']),
      xParExcluded: x['par_excluded'] as bool,
    );
  }

  factory SampleStats.parse(String json) => SampleStats.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

class SideView {
  const SideView({required this.state, this.gt, this.qual, this.dp, this.gq, this.filter});

  /// `carrier`, `low_quality`, `explicit_ref`, `missing`, `absent_ref_block`,
  /// `absent_callable`, `absent_unknown` ou `not_assessed`.
  final String state;
  final String? gt;
  final double? qual;
  final int? dp;
  final int? gq;
  final String? filter;

  factory SideView.fromJson(Map<String, dynamic> j) => SideView(
        state: j['state'] as String,
        gt: j['gt'] as String?,
        qual: _d(j['qual']),
        dp: j['dp'] as int?,
        gq: j['gq'] as int?,
        filter: j['filter'] as String?,
      );
}

class ComparisonRow {
  const ComparisonRow({
    required this.chrom,
    required this.pos,
    required this.reference,
    required this.alt,
    required this.kind,
    required this.category,
    required this.ids,
    required this.a,
    required this.b,
  });

  final String chrom;
  final int pos;
  final String reference;
  final String alt;
  final String kind;
  final String category;
  final List<String> ids;
  final SideView a;
  final SideView b;

  /// Chave estável da variante (notas e favoritos).
  String get key => '$chrom:$pos:$reference:$alt';

  factory ComparisonRow.fromJson(Map<String, dynamic> j) => ComparisonRow(
        chrom: j['chrom'] as String,
        pos: j['pos'] as int,
        reference: j['reference'] as String,
        alt: j['alt'] as String,
        kind: j['kind'] as String,
        category: j['category'] as String,
        ids: (j['ids'] as List).cast<String>(),
        a: SideView.fromJson(j['a'] as Map<String, dynamic>),
        b: SideView.fromJson(j['b'] as Map<String, dynamic>),
      );

  static List<ComparisonRow> parseList(String json) =>
      (jsonDecode(json) as List).map((r) => ComparisonRow.fromJson(r as Map<String, dynamic>)).toList();
}

/// Região 1-based inclusiva, como o núcleo a interpreta.
class Region {
  const Region(this.chrom, this.start, this.end);
  final String chrom;
  final int start;
  final int end;

  factory Region.fromJson(Map<String, dynamic> j) => Region(j['chrom'] as String, j['start'] as int, j['end'] as int);
  Map<String, dynamic> toJson() => {'chrom': chrom, 'start': start, 'end': end};

  @override
  String toString() => start == end ? '$chrom:$start' : '$chrom:$start-$end';

  @override
  bool operator ==(Object other) => other is Region && other.toString() == toString();
  @override
  int get hashCode => toString().hashCode;
}

/// Espelho do `RowFilter` do núcleo (vai para o Rust como JSON).
class RowFilter {
  const RowFilter({
    this.categories = const {},
    this.kinds = const {},
    this.region,
    this.idContains,
    this.minQual,
    this.minDp,
    this.minGq,
  });

  final Set<String> categories;
  final Set<String> kinds;
  final Region? region;
  final String? idContains;
  final double? minQual;
  final int? minDp;
  final int? minGq;

  bool get isEmpty => toJsonString() == '{}';

  int get activeCount => [
        categories.isNotEmpty,
        kinds.isNotEmpty,
        region != null,
        idContains != null,
        minQual != null,
        minDp != null,
        minGq != null,
      ].where((x) => x).length;

  Map<String, dynamic> toJson() => {
        if (categories.isNotEmpty) 'categories': [for (final c in categoryCodes) if (categories.contains(c)) c],
        if (kinds.isNotEmpty) 'kinds': [for (final k in kindCodes) if (kinds.contains(k)) k],
        if (region != null) 'region': region!.toJson(),
        if (idContains != null) 'id_contains': idContains,
        if (minQual != null) 'min_qual': minQual,
        if (minDp != null) 'min_dp': minDp,
        if (minGq != null) 'min_gq': minGq,
      };

  String toJsonString() => jsonEncode(toJson());

  factory RowFilter.fromJson(Map<String, dynamic> j) => RowFilter(
        categories: {...?(j['categories'] as List?)?.cast<String>()},
        kinds: {...?(j['kinds'] as List?)?.cast<String>()},
        region: j['region'] == null ? null : Region.fromJson(j['region'] as Map<String, dynamic>),
        idContains: j['id_contains'] as String?,
        minQual: _d(j['min_qual']),
        minDp: j['min_dp'] as int?,
        minGq: j['min_gq'] as int?,
      );

  factory RowFilter.parse(String json) => RowFilter.fromJson(jsonDecode(json) as Map<String, dynamic>);

  RowFilter copyWith({
    Set<String>? categories,
    Set<String>? kinds,
    Region? Function()? region,
    String? Function()? idContains,
    double? Function()? minQual,
    int? Function()? minDp,
    int? Function()? minGq,
  }) =>
      RowFilter(
        categories: categories ?? this.categories,
        kinds: kinds ?? this.kinds,
        region: region != null ? region() : this.region,
        idContains: idContains != null ? idContains() : this.idContains,
        minQual: minQual != null ? minQual() : this.minQual,
        minDp: minDp != null ? minDp() : this.minDp,
        minGq: minGq != null ? minGq() : this.minGq,
      );

  @override
  bool operator ==(Object other) => other is RowFilter && other.toJsonString() == toJsonString();
  @override
  int get hashCode => toJsonString().hashCode;
}

/// Espelho de `CompareOptions` (portão de qualidade + verdade).
class CompareOptions {
  const CompareOptions({this.passOnly = false, this.minQual, this.minDp, this.minGq, this.truth});

  final bool passOnly;
  final double? minQual;
  final int? minDp;
  final int? minGq;

  /// `a`, `b` ou `null`.
  final String? truth;

  String toJsonString() => jsonEncode({
        'call_filter': {
          'pass_only': passOnly,
          'min_qual': minQual,
          'min_dp': minDp,
          'min_gq': minGq,
          'conditions': <Object>[],
        },
        'truth': truth,
      });
}
