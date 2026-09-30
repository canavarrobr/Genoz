// Relatório de inspeção de um VCF, lido do JSON produzido pelo núcleo Rust
// (`genoz_core::inspect::InspectReport`). Só leitura: a lógica fica no Rust.

import 'dart:convert';

enum Verdict { valid, validWithWarnings, partiallyValid, invalid }

Verdict _verdict(String s) => switch (s) {
      'valid' => Verdict.valid,
      'valid_with_warnings' => Verdict.validWithWarnings,
      'partially_valid' => Verdict.partiallyValid,
      _ => Verdict.invalid,
    };

String verdictCode(Verdict v) => switch (v) {
      Verdict.valid => 'valid',
      Verdict.validWithWarnings => 'valid_with_warnings',
      Verdict.partiallyValid => 'partially_valid',
      Verdict.invalid => 'invalid',
    };

Verdict verdictFromCode(String s) => _verdict(s);

class SampleSummary {
  const SampleSummary({
    required this.name,
    required this.homRef,
    required this.het,
    required this.homAlt,
    required this.missing,
  });

  final String name;
  final int homRef;
  final int het;
  final int homAlt;
  final int missing;

  factory SampleSummary.fromJson(Map<String, dynamic> j) => SampleSummary(
        name: j['name'] as String,
        homRef: j['hom_ref'] as int,
        het: j['het'] as int,
        homAlt: j['hom_alt'] as int,
        missing: j['missing'] as int,
      );
}

class ReportIssue {
  const ReportIssue({
    required this.line,
    required this.isError,
    required this.code,
    required this.message,
  });

  /// 0 = arquivo como um todo (cabeçalho).
  final int line;
  final bool isError;
  final String code;
  final String message;

  factory ReportIssue.fromJson(Map<String, dynamic> j) => ReportIssue(
        line: j['line'] as int,
        isError: j['severity'] == 'error',
        code: j['code'] as String,
        message: j['message'] as String,
      );
}

class ChromCount {
  const ChromCount(this.raw, this.records);
  final String raw;
  final int records;
}

class InspectReport {
  const InspectReport({
    required this.coreVersion,
    required this.sha256,
    required this.bytes,
    required this.compression,
    required this.fileFormat,
    required this.build,
    required this.buildConfidence,
    required this.buildEvidence,
    required this.chromStyle,
    required this.samples,
    required this.recordsRead,
    required this.recordsOk,
    required this.recordsRejected,
    required this.multiallelic,
    required this.biallelicAfterSplit,
    required this.byKind,
    required this.byChrom,
    required this.filterPass,
    required this.filterFailed,
    required this.filterMissing,
    required this.sorted,
    required this.errors,
    required this.warnings,
    required this.issues,
    required this.issuesTruncated,
    required this.fatal,
    required this.verdict,
  });

  final String coreVersion;
  final String sha256;
  final int bytes;

  /// `none`, `gzip` ou `bgzf`.
  final String compression;
  final String? fileFormat;

  /// `GRCh37`, `GRCh38` ou `unknown`.
  final String build;

  /// `high`, `low` ou `none`.
  final String buildConfidence;
  final List<String> buildEvidence;

  /// `ucsc`, `ensembl`, `mixed` ou `unknown`.
  final String chromStyle;
  final List<SampleSummary> samples;
  final int recordsRead;
  final int recordsOk;
  final int recordsRejected;
  final int multiallelic;
  final int biallelicAfterSplit;

  /// Tipo (`snv`, `insertion`...) → quantidade, após dividir multialélicos.
  final Map<String, int> byKind;
  final List<ChromCount> byChrom;
  final int filterPass;
  final int filterFailed;
  final int filterMissing;
  final bool sorted;
  final int errors;
  final int warnings;
  final List<ReportIssue> issues;
  final bool issuesTruncated;
  final String? fatal;
  final Verdict verdict;

  bool get isUsable => verdict != Verdict.invalid;

  factory InspectReport.fromJson(Map<String, dynamic> j) {
    final digest = j['digest'] as Map<String, dynamic>?;
    final build = j['build'] as Map<String, dynamic>;
    return InspectReport(
      coreVersion: j['core_version'] as String,
      sha256: digest?['sha256'] as String? ?? '',
      bytes: digest?['bytes'] as int? ?? 0,
      compression: j['compression'] as String,
      fileFormat: j['file_format'] as String?,
      build: build['build'] as String,
      buildConfidence: build['confidence'] as String,
      buildEvidence: (build['evidence'] as List).cast<String>(),
      chromStyle: j['chrom_style'] as String,
      samples: (j['samples'] as List)
          .map((s) => SampleSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
      recordsRead: j['records_read'] as int,
      recordsOk: j['records_ok'] as int,
      recordsRejected: j['records_rejected'] as int,
      multiallelic: j['multiallelic'] as int,
      biallelicAfterSplit: j['biallelic_after_split'] as int,
      byKind: (j['by_kind'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
      byChrom: (j['by_chrom'] as List)
          .map((c) => ChromCount(c['raw'] as String, c['records'] as int))
          .toList(),
      filterPass: j['filter_pass'] as int,
      filterFailed: j['filter_failed'] as int,
      filterMissing: j['filter_missing'] as int,
      sorted: j['sorted'] as bool,
      errors: j['errors'] as int,
      warnings: j['warnings'] as int,
      issues: (j['issues'] as List)
          .map((i) => ReportIssue.fromJson(i as Map<String, dynamic>))
          .toList(),
      issuesTruncated: j['issues_truncated'] as bool,
      fatal: j['fatal'] as String?,
      verdict: _verdict(j['verdict'] as String),
    );
  }

  factory InspectReport.parse(String json) =>
      InspectReport.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
