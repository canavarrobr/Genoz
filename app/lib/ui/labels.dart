// Tradução dos códigos que vêm do núcleo (snake_case) para textos da interface.

import 'package:flutter/material.dart';

import '../core/inspect_report.dart';
import '../l10n/generated/app_localizations.dart';

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

Color verdictColor(Verdict v, ColorScheme c) => switch (v) {
      Verdict.valid => Colors.green.shade600,
      Verdict.validWithWarnings => c.primary,
      Verdict.partiallyValid => Colors.orange.shade700,
      Verdict.invalid => c.error,
    };

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
