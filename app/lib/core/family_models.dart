// Espelho Dart de `genoz_core::family` (Módulo 12): opções e resultado (`familia.json`).

import 'dart:convert';

class TrioRoles {
  const TrioRoles({required this.child, required this.father, required this.mother});
  final String child;
  final String father;
  final String mother;

  Map<String, Object?> toJson() => {'child': child, 'father': father, 'mother': mother};

  factory TrioRoles.fromJson(Map<String, dynamic> j) =>
      TrioRoles(child: j['child'] as String, father: j['father'] as String, mother: j['mother'] as String);
}

/// Opções enviadas ao núcleo. A ordem das chaves é a do núcleo (o ID da análise
/// vem do JSON dos parâmetros gravado pelo próprio núcleo, não deste).
class FamilyOptions {
  const FamilyOptions({
    this.samples = const [],
    this.trio,
    this.passOnly = false,
    this.minQual,
    this.minDp,
    this.minGq,
  });

  final List<String> samples;
  final TrioRoles? trio;
  final bool passOnly;
  final double? minQual;
  final int? minDp;
  final int? minGq;

  String toJsonString() => jsonEncode({
        'call_filter': {
          'pass_only': passOnly,
          'min_qual': minQual,
          'min_dp': minDp,
          'min_gq': minGq,
          'conditions': <Object>[],
        },
        'samples': samples,
        'trio': trio?.toJson(),
      });

  factory FamilyOptions.parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    final f = (j['call_filter'] as Map<String, dynamic>?) ?? const {};
    return FamilyOptions(
      samples: [for (final s in (j['samples'] as List? ?? const [])) s as String],
      trio: j['trio'] == null ? null : TrioRoles.fromJson(j['trio'] as Map<String, dynamic>),
      passOnly: f['pass_only'] as bool? ?? false,
      minQual: (f['min_qual'] as num?)?.toDouble(),
      minDp: f['min_dp'] as int?,
      minGq: f['min_gq'] as int?,
    );
  }
}

/// Classes da Tabela 1 do KING (`relation` no JSON).
enum Relation { duplicate, parentOffspring, fullSiblings, firstDegree, secondDegree, thirdDegree, unrelated, insufficient }

Relation _relation(String s) => switch (s) {
      'duplicate' => Relation.duplicate,
      'parent_offspring' => Relation.parentOffspring,
      'full_siblings' => Relation.fullSiblings,
      'first_degree' => Relation.firstDegree,
      'second_degree' => Relation.secondDegree,
      'third_degree' => Relation.thirdDegree,
      'unrelated' => Relation.unrelated,
      _ => Relation.insufficient,
    };

double? _d(Object? v) => (v as num?)?.toDouble();

class PairStats {
  PairStats.fromJson(Map<String, dynamic> j)
      : a = j['a'] as int,
        b = j['b'] as int,
        sites = j['sites'] as int,
        hetA = j['het_a'] as int,
        hetB = j['het_b'] as int,
        hetHet = j['het_het'] as int,
        ibs0 = j['ibs0'] as int,
        identical = j['identical'] as int,
        concordance = _d(j['concordance']),
        kinship = _d(j['kinship']),
        pi0 = _d(j['pi0']),
        relation = _relation(j['relation'] as String);

  final int a, b, sites, hetA, hetB, hetHet, ibs0, identical;
  final double? concordance, kinship, pi0;
  final Relation relation;
}

class Intersection {
  Intersection.fromJson(Map<String, dynamic> j)
      : samples = [for (final s in j['samples'] as List) s as int],
        count = j['count'] as int;
  final List<int> samples;
  final int count;
}

class RohRun {
  RohRun.fromJson(Map<String, dynamic> j)
      : chrom = j['chrom'] as String,
        start = j['start'] as int,
        end = j['end'] as int,
        snps = j['snps'] as int,
        hets = j['hets'] as int;
  final String chrom;
  final int start, end, snps, hets;
  double get megabases => (end - start + 1) / 1e6;
}

class SampleRoh {
  SampleRoh.fromJson(Map<String, dynamic> j)
      : sample = j['sample'] as int,
        genotyped = j['genotyped'] as int,
        heterozygous = j['heterozygous'] as int,
        runs = [for (final r in j['runs'] as List) RohRun.fromJson(r as Map<String, dynamic>)],
        totalKb = j['total_kb'] as int,
        froh = _d(j['froh']);
  final int sample, genotyped, heterozygous, totalKb;
  final List<RohRun> runs;
  final double? froh;
}

class TrioEvent {
  TrioEvent.fromJson(Map<String, dynamic> j)
      : chrom = j['chrom'] as String,
        pos = j['pos'] as int,
        reference = j['reference'] as String,
        alt = j['alt'] as String,
        deNovo = j['kind'] == 'de_novo',
        child = j['child'] as String,
        father = j['father'] as String,
        mother = j['mother'] as String,
        childQual = _d(j['child_qual']),
        childDp = j['child_dp'] as int?,
        childGq = j['child_gq'] as int?;
  final String chrom, reference, alt, child, father, mother;
  final int pos;
  final bool deNovo;
  final double? childQual;
  final int? childDp, childGq;
}

class TrioResult {
  TrioResult.fromJson(Map<String, dynamic> j)
      : child = j['child'] as int,
        father = j['father'] as int,
        mother = j['mother'] as int,
        sites = j['sites'] as int,
        consistent = j['consistent'] as int,
        deNovo = j['de_novo_candidates'] as int,
        otherErrors = j['other_errors'] as int,
        paternal = j['paternal'] as int,
        maternal = j['maternal'] as int,
        ambiguous = j['ambiguous'] as int,
        errorRate = _d(j['error_rate']),
        events = [for (final e in j['events'] as List) TrioEvent.fromJson(e as Map<String, dynamic>)],
        truncated = j['events_truncated'] as bool;
  final int child, father, mother, sites, consistent, deNovo, otherErrors, paternal, maternal, ambiguous;
  final double? errorRate;
  final List<TrioEvent> events;
  final bool truncated;
}

class FamilyResult {
  FamilyResult.fromJson(Map<String, dynamic> j)
      : samples = [for (final s in j['samples'] as List) s as String],
        sitesUsed = (j['sites'] as Map<String, dynamic>)['used'] as int,
        pairs = [for (final p in j['pairs'] as List) PairStats.fromJson(p as Map<String, dynamic>)],
        carriers = [for (final c in j['carriers'] as List) c as int],
        intersections = [for (final i in j['intersections'] as List) Intersection.fromJson(i as Map<String, dynamic>)],
        roh = [for (final r in j['roh'] as List) SampleRoh.fromJson(r as Map<String, dynamic>)],
        rohAvailable = j['roh_available'] as bool,
        trio = j['trio'] == null ? null : TrioResult.fromJson(j['trio'] as Map<String, dynamic>),
        warnings = [for (final w in j['warnings'] as List) w as String];

  factory FamilyResult.parse(String json) => FamilyResult.fromJson(jsonDecode(json) as Map<String, dynamic>);

  final List<String> samples;
  final int sitesUsed;
  final List<PairStats> pairs;
  final List<int> carriers;
  final List<Intersection> intersections;
  final List<SampleRoh> roh;
  final bool rohAvailable;
  final TrioResult? trio;
  final List<String> warnings;

  PairStats? pair(int i, int j) {
    if (i == j) return null;
    final (a, b) = i < j ? (i, j) : (j, i);
    for (final p in pairs) {
      if (p.a == a && p.b == b) return p;
    }
    return null;
  }
}
