// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Genoz';

  @override
  String get privateMode => 'Private mode — on-device processing';

  @override
  String get privacyTitle => 'Your privacy';

  @override
  String get privacyBody =>
      'In private mode, Genoz processes your genomic files only on this device. Nothing is sent to servers; there is no account and no telemetry.\n\nImported files are kept in the app\'s private folder. Deleting a project also deletes its files.';

  @override
  String get notDiagnosis => 'For education and research. Not a diagnosis.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get projectsEmptyTitle => 'No projects yet';

  @override
  String get projectsEmptyBody =>
      'Create a project to import VCF files and compare samples.';

  @override
  String get newProject => 'New project';

  @override
  String get projectName => 'Project name';

  @override
  String get projectDescription => 'Description (optional)';

  @override
  String get projectNameRequired => 'Give the project a name';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'no files',
    );
    return '$_temp0';
  }

  @override
  String get deleteProjectTitle => 'Delete project?';

  @override
  String deleteProjectBody(String name) {
    return 'Project \"$name\" and all its files will be deleted from this device. This cannot be undone.';
  }

  @override
  String get deleteFileTitle => 'Remove file?';

  @override
  String deleteFileBody(String name) {
    return 'The copy of \"$name\" kept by Genoz will be deleted. The original file is not affected.';
  }

  @override
  String get importVcf => 'Import VCF';

  @override
  String get generateExample => 'Generate synthetic example';

  @override
  String get generateExampleHint =>
      'Creates a fictional VCF to try the app without real data.';

  @override
  String get filesEmptyTitle => 'No files in this project';

  @override
  String get filesEmptyBody =>
      'Import a VCF file (.vcf or .vcf.gz) or generate a synthetic example.';

  @override
  String get importCopying => 'Copying and computing SHA-256…';

  @override
  String get importValidating => 'Validating VCF…';

  @override
  String importing(String name) {
    return 'Importing $name';
  }

  @override
  String get importCancelled => 'Import cancelled.';

  @override
  String get importFailedTitle => 'Could not import';

  @override
  String get importInvalidTitle => 'Invalid file';

  @override
  String get importInvalidBody =>
      'Genoz read the file, but no variant could be used.';

  @override
  String importDuplicate(String name) {
    return 'This file was already imported into this project (\"$name\").';
  }

  @override
  String importDone(String name) {
    return '\"$name\" imported.';
  }

  @override
  String get verdictValid => 'Valid';

  @override
  String get verdictValidWithWarnings => 'Valid with warnings';

  @override
  String get verdictPartiallyValid => 'Partially valid';

  @override
  String get verdictInvalid => 'Invalid';

  @override
  String samplesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
      zero: 'sites only',
    );
    return '$_temp0';
  }

  @override
  String variantsCount(int count) {
    return '$count variants';
  }

  @override
  String get buildUnknown => 'unknown build';

  @override
  String get sectionFile => 'File';

  @override
  String get sectionBuild => 'Reference genome';

  @override
  String get sectionSamples => 'Samples';

  @override
  String get sectionKinds => 'Variant types';

  @override
  String get sectionChromosomes => 'Chromosomes';

  @override
  String get sectionProblems => 'Problems found';

  @override
  String get fieldSha256 => 'SHA-256';

  @override
  String get fieldSize => 'Size';

  @override
  String get fieldCompression => 'Compression';

  @override
  String get fieldFormat => 'Format';

  @override
  String get fieldRecords => 'Records';

  @override
  String get fieldMultiallelic => 'Multiallelic';

  @override
  String get fieldFilter => 'FILTER';

  @override
  String get fieldSorted => 'Sorted';

  @override
  String get fieldChromStyle => 'Chromosome names';

  @override
  String recordsSummary(int ok, int read, int rejected) {
    return '$ok valid of $read ($rejected discarded)';
  }

  @override
  String multiallelicSummary(int multi, int split) {
    return '$multi → $split biallelic records';
  }

  @override
  String filterSummary(int pass, int failed, int missing) {
    return 'PASS $pass · filtered $failed · no filter $missing';
  }

  @override
  String get yes => 'yes';

  @override
  String get no => 'no';

  @override
  String confidence(String level) {
    return '$level confidence';
  }

  @override
  String get colHomRef => '0/0';

  @override
  String get colHet => 'het';

  @override
  String get colHomAlt => 'hom-alt';

  @override
  String get colMissing => 'missing';

  @override
  String get problemsNone => 'No problems found.';

  @override
  String problemsCount(int errors, int warnings) {
    return '$errors errors · $warnings warnings';
  }

  @override
  String get problemsTruncated =>
      'Shortened list: only the first problems are shown.';

  @override
  String get lineHeader => 'header';

  @override
  String lineNumber(int n) {
    return 'line $n';
  }

  @override
  String readInterrupted(String reason) {
    return 'Reading stopped: $reason';
  }

  @override
  String coreVersion(String version) {
    return 'Core $version';
  }

  @override
  String get fileNotFound => 'File not found.';

  @override
  String get kindSnv => 'SNV';

  @override
  String get kindMnv => 'MNV';

  @override
  String get kindInsertion => 'insertion';

  @override
  String get kindDeletion => 'deletion';

  @override
  String get kindComplex => 'complex indel';

  @override
  String get kindStructural => 'structural/symbolic';

  @override
  String get kindOther => 'other';

  @override
  String get compNone => 'none (text)';

  @override
  String get compGzip => 'plain gzip (not indexable)';

  @override
  String get compBgzf => 'BGZF (indexable)';

  @override
  String get styleUcsc => 'UCSC (chr1, chrX)';

  @override
  String get styleEnsembl => 'Ensembl/NCBI (1, X)';

  @override
  String get styleMixed => 'mixed (chr1 and 1)';

  @override
  String get styleUnknown => 'undetermined';

  @override
  String get confHigh => 'high';

  @override
  String get confLow => 'low';

  @override
  String get confNone => 'none';

  @override
  String get importFile => 'File';

  @override
  String get fileMenuReport => 'View report';
}
