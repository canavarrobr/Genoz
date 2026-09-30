// Tradução dos códigos que vêm do núcleo (snake_case) para textos da interface.

import 'package:flutter/material.dart';

import '../core/inspect_report.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme.dart';

extension LabelsX on AppLocalizations {
  String verdict(Verdict v) => switch (v) {
        Verdict.valid => verdictValid,
        Verdict.validWithWarnings => verdictValidWithWarnings,
        Verdict.partiallyValid => verdictPartiallyValid,
        Verdict.invalid => verdictInvalid,
      };

  String kind(String code) => switch (code) {
        'snv' => kindSnv,
        'mnv' => kindMnv,
        'insertion' => kindInsertion,
        'deletion' => kindDeletion,
        'complex' => kindComplex,
        'structural' => kindStructural,
        _ => kindOther,
      };

  String compression(String code) => switch (code) {
        'bgzf' => compBgzf,
        'gzip' => compGzip,
        _ => compNone,
      };

  String chromStyle(String code) => switch (code) {
        'ucsc' => styleUcsc,
        'ensembl' => styleEnsembl,
        'mixed' => styleMixed,
        _ => styleUnknown,
      };

  String buildName(String code) => switch (code) {
        'GRCh37' => 'GRCh37 (hg19)',
        'GRCh38' => 'GRCh38 (hg38)',
        _ => buildUnknown,
      };

  String buildConfidence(String code) => confidence(switch (code) {
        'high' => confHigh,
        'low' => confLow,
        _ => confNone,
      });
}

IconData verdictIcon(Verdict v) => switch (v) {
      Verdict.valid => Icons.check_circle,
      Verdict.validWithWarnings => Icons.info,
      Verdict.partiallyValid => Icons.warning_amber,
      Verdict.invalid => Icons.error,
    };

Color verdictColor(Verdict v, BuildContext context) {
  final p = context.palette;
  return switch (v) {
    Verdict.valid => p.success,
    Verdict.validWithWarnings => p.info,
    Verdict.partiallyValid => p.warning,
    Verdict.invalid => p.error,
  };
}

extension ComparisonLabelsX on AppLocalizations {
  String category(String code) => switch (code) {
        'shared' => catShared,
        'genotype_difference' => catGenotypeDifference,
        'only_a' => catOnlyA,
        'only_b' => catOnlyB,
        'missing_uncertain' => catMissingUncertain,
        _ => catNotAssessed,
      };

  String sideState(String code) => switch (code) {
        'carrier' => stCarrier,
        'low_quality' => stLowQuality,
        'explicit_ref' => stExplicitRef,
        'missing' => stMissing,
        'absent_ref_block' => stAbsentRefBlock,
        'absent_callable' => stAbsentCallable,
        'absent_unknown' => stAbsentUnknown,
        _ => stNotAssessed,
      };
}

IconData categoryIcon(String code) => switch (code) {
      'shared' => Icons.join_inner,
      'genotype_difference' => Icons.compare_arrows,
      'only_a' => Icons.looks_one_outlined,
      'only_b' => Icons.looks_two_outlined,
      'missing_uncertain' => Icons.help_outline,
      _ => Icons.block,
    };

String percent(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(1)}%';

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '$bytes B' : '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[i]}';
}
