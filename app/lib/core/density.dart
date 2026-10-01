// Densidade de variantes ao longo do genoma (dados do ideograma) e cariótipo
// de referência para desenhá-lo.

import 'dart:convert';

/// Saída de `genoz_core::density` (mesma estrutura do `genoz-cli density --json`).
class DensityMap {
  const DensityMap({required this.binSize, required this.total, required this.chroms});

  final int binSize;
  final int total;
  final List<ChromDensity> chroms;

  factory DensityMap.parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    return DensityMap(
      binSize: j['bin_size'] as int,
      total: j['total'] as int,
      chroms: [for (final c in j['chroms'] as List) ChromDensity.fromJson(c as Map<String, dynamic>)],
    );
  }

  ChromDensity? chrom(String name) => chroms.where((c) => c.chrom == name).firstOrNull;
}

class ChromDensity {
  const ChromDensity({required this.chrom, required this.maxPos, required this.total, required this.counts});

  final String chrom;
  final int maxPos;
  final int total;

  /// Categoria (`shared`, `only_a`...) → contagem por faixa.
  final Map<String, List<int>> counts;

  factory ChromDensity.fromJson(Map<String, dynamic> j) => ChromDensity(
    chrom: j['chrom'] as String,
    maxPos: j['max_pos'] as int,
    total: j['total'] as int,
    counts: {for (final e in (j['counts'] as Map<String, dynamic>).entries) e.key: (e.value as List).cast<int>()},
  );

  int get bins => counts.values.firstOrNull?.length ?? 0;

  /// Contagem por faixa somando as categorias pedidas (todas se vazio).
  List<int> binsFor(Set<String> categories) {
    final out = List<int>.filled(bins, 0);
    for (final e in counts.entries) {
      if (categories.isNotEmpty && !categories.contains(e.key)) continue;
      for (var i = 0; i < e.value.length; i++) {
        out[i] += e.value[i];
      }
    }
    return out;
  }

  int countFor(Set<String> categories) => binsFor(categories).fold(0, (a, b) => a + b);
}

/// Cromossomo humano para o ideograma.
class KaryotypeChrom {
  const KaryotypeChrom(this.name, this.length, this.centromere);
  final String name;
  final int length;

  /// Posição aproximada do centrômero (meio da banda `acen`), só para orientação visual.
  final int centromere;
}

/// Cromossomos 1–22, X e Y. Comprimentos: GRC (os mesmos de `genoz_core::build`);
/// centrômeros: aproximados, a partir das bandas citogenéticas do UCSC.
List<KaryotypeChrom> karyotype(String build) {
  final grch37 = build.startsWith('GRCh37');
  final data = grch37 ? _grch37 : _grch38;
  return [for (final (n, len, cen) in data) KaryotypeChrom(n, len, cen)];
}

const _grch38 = [
  ('1', 248956422, 123400000),
  ('2', 242193529, 93900000),
  ('3', 198295559, 90900000),
  ('4', 190214555, 50000000),
  ('5', 181538259, 48800000),
  ('6', 170805979, 59800000),
  ('7', 159345973, 60100000),
  ('8', 145138636, 45200000),
  ('9', 138394717, 43000000),
  ('10', 133797422, 39800000),
  ('11', 135086622, 53400000),
  ('12', 133275309, 35500000),
  ('13', 114364328, 17700000),
  ('14', 107043718, 17200000),
  ('15', 101991189, 19000000),
  ('16', 90338345, 36800000),
  ('17', 83257441, 25100000),
  ('18', 80373285, 18500000),
  ('19', 58617616, 26200000),
  ('20', 64444167, 28100000),
  ('21', 46709983, 12000000),
  ('22', 50818468, 15000000),
  ('X', 156040895, 60600000),
  ('Y', 57227415, 10400000),
];

const _grch37 = [
  ('1', 249250621, 125000000),
  ('2', 243199373, 93300000),
  ('3', 198022430, 91000000),
  ('4', 191154276, 50400000),
  ('5', 180915260, 48400000),
  ('6', 171115067, 61000000),
  ('7', 159138663, 59900000),
  ('8', 146364022, 45600000),
  ('9', 141213431, 49000000),
  ('10', 135534747, 40200000),
  ('11', 135006516, 53700000),
  ('12', 133851895, 35800000),
  ('13', 115169878, 17900000),
  ('14', 107349540, 17600000),
  ('15', 102531392, 19000000),
  ('16', 90354753, 36600000),
  ('17', 81195210, 24000000),
  ('18', 78077248, 17200000),
  ('19', 59128983, 26500000),
  ('20', 63025520, 27500000),
  ('21', 48129895, 13200000),
  ('22', 51304566, 14700000),
  ('X', 155270560, 60600000),
  ('Y', 59373566, 12500000),
];
