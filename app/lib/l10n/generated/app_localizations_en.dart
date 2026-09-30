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

  @override
  String get compareTitle => 'Compare A × B';

  @override
  String get compareNeedsFiles => 'Import at least one VCF file to compare.';

  @override
  String get sideA => 'Sample A';

  @override
  String get sideB => 'Sample B';

  @override
  String get chooseFile => 'File';

  @override
  String get chooseSample => 'Sample';

  @override
  String get firstSample => '(first in file)';

  @override
  String get qualityGate => 'Quality gate';

  @override
  String get qualityGateHint =>
      'Calls that fail become “uncertain”, never “absent”.';

  @override
  String get passOnly => 'Only FILTER = PASS';

  @override
  String get minQual => 'Minimum QUAL';

  @override
  String get minDp => 'Minimum DP';

  @override
  String get minGq => 'Minimum GQ';

  @override
  String get truthLabel => 'Treat as truth (benchmark)';

  @override
  String get truthNone => 'none';

  @override
  String get runCompare => 'Compare';

  @override
  String get comparing => 'Comparing…';

  @override
  String get compareFailedTitle => 'Could not compare';

  @override
  String get compareCancelled => 'Comparison cancelled.';

  @override
  String get sameSampleWarning =>
      'A and B are the same sample of the same file: everything will be “shared”.';

  @override
  String get analysesTitle => 'Analyses';

  @override
  String analysisVs(String a, String b) {
    return '$a × $b';
  }

  @override
  String get deleteAnalysisTitle => 'Delete analysis?';

  @override
  String get deleteAnalysisBody =>
      'The results of this comparison will be deleted. The VCF files stay in the project.';

  @override
  String get analysisNotFound => 'Analysis not found.';

  @override
  String get catShared => 'Shared';

  @override
  String get catGenotypeDifference => 'Genotype difference';

  @override
  String get catOnlyA => 'Only in A';

  @override
  String get catOnlyB => 'Only in B';

  @override
  String get catMissingUncertain => 'Missing/uncertain';

  @override
  String get catNotAssessed => 'Not assessed';

  @override
  String get stCarrier => 'carries the allele';

  @override
  String get stLowQuality => 'carries, low quality';

  @override
  String get stExplicitRef => 'explicit 0/0';

  @override
  String get stMissing => 'missing genotype';

  @override
  String get stAbsentRefBlock => 'reference (gVCF block)';

  @override
  String get stAbsentCallable => 'no record (callable region)';

  @override
  String get stAbsentUnknown => 'no record';

  @override
  String get stNotAssessed => 'outside assessed region';

  @override
  String get tabSummary => 'Summary';

  @override
  String get tabTable => 'Table';

  @override
  String get tabQc => 'QC';

  @override
  String get concordance => 'Genotype concordance';

  @override
  String get jaccard => 'Jaccard (sites)';

  @override
  String benchmarkTitle(String side) {
    return 'Benchmark (truth: $side)';
  }

  @override
  String get precision => 'Precision';

  @override
  String get recall => 'Recall';

  @override
  String get f1 => 'F1';

  @override
  String get classAll => 'All';

  @override
  String get warningsTitle => 'Warnings';

  @override
  String get modeInMemory => 'Comparison done in memory (unsorted files).';

  @override
  String get absenceHint =>
      'Without a callable-regions BED or gVCF, “only in A/B” includes positions with no record in the other file — which may simply not have been sequenced.';

  @override
  String rowsCount(int count) {
    return '$count rows';
  }

  @override
  String get filters => 'Filters';

  @override
  String get clearFilters => 'Clear';

  @override
  String get searchHint => 'chr1:1000, chr7:1M-2M or rs123';

  @override
  String get noRows => 'No rows match these filters.';

  @override
  String get saveFilter => 'Save filter';

  @override
  String get filterName => 'Filter name';

  @override
  String get savedFilters => 'Saved filters';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get kindsLabel => 'Variant types';

  @override
  String get regionLabel => 'Region';

  @override
  String get regionInvalid => 'Invalid region (e.g. chr1:1000-2000)';

  @override
  String get idLabel => 'ID contains';

  @override
  String get apply => 'Apply';

  @override
  String get stateLabel => 'State';

  @override
  String get gtLabel => 'Genotype';

  @override
  String get qualLabel => 'QUAL';

  @override
  String get dpLabel => 'DP';

  @override
  String get gqLabel => 'GQ';

  @override
  String get filterLabel => 'FILTER';

  @override
  String get idsLabel => 'IDs';

  @override
  String get noteLabel => 'Note';

  @override
  String get tagsLabel => 'Tags (comma separated)';

  @override
  String get favorite => 'Favorite';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get tiTvHint => 'Reference: ~2.0–2.1 genome; ~3.0 exome.';

  @override
  String get hetHom => 'het / hom-alt';

  @override
  String get missingRate => 'Missing';

  @override
  String get carriers => 'Carried variants';

  @override
  String get lowQualityCount => 'Low quality';

  @override
  String get dpDistribution => 'Depth (DP)';

  @override
  String get gqDistribution => 'Genotype quality (GQ)';

  @override
  String get qualDistribution => 'QUAL';

  @override
  String get xHet => 'X heterozygosity (outside PAR)';

  @override
  String get xHetHint =>
      'Educational consistency check; does not determine sex.';

  @override
  String get export => 'Export';

  @override
  String get exportFormat => 'Format';

  @override
  String exportFiltered(int count) {
    return 'Exports the $count rows of the current filter, with the reproducibility manifest.';
  }

  @override
  String exportDone(int count) {
    return '$count rows exported.';
  }

  @override
  String get exportSaveManifest => 'Also save the manifest?';

  @override
  String get exportSaveManifestBody =>
      'The manifest records inputs, parameters and hashes to redo this analysis.';

  @override
  String get journalTitle => 'Project journal';

  @override
  String get journalEmpty => 'Nothing recorded yet.';

  @override
  String get notesTitle => 'Notes and favorites';

  @override
  String get notesEmpty =>
      'Tap a variant in the table to add a note or favorite it.';

  @override
  String logImport(String name) {
    return 'File imported: $name';
  }

  @override
  String logDeleteFile(String name) {
    return 'File removed: $name';
  }

  @override
  String logCompare(String a, String b, String id) {
    return 'Comparison $a × $b ($id)';
  }

  @override
  String logExport(String format, int count) {
    return '$format export: $count rows';
  }

  @override
  String logFilter(String name) {
    return 'Filter saved: $name';
  }

  @override
  String logDeleteAnalysis(String name) {
    return 'Analysis deleted: $name';
  }

  @override
  String get minQualShort => 'QUAL ≥';

  @override
  String get minDpShort => 'DP ≥';

  @override
  String get minGqShort => 'GQ ≥';

  @override
  String get exportVcf => 'VCF (A and B)';

  @override
  String get notNow => 'Not now';

  @override
  String get brandSignature => 'GENOMICS WITHOUT BORDERS';

  @override
  String get brandSlogan => 'Your genomics, under your control.';

  @override
  String get brandSplash => 'Local and private genomic analysis';

  @override
  String get menuProjects => 'Projects';

  @override
  String get menuAbout => 'About Genoz';

  @override
  String get menuPrivacy => 'Privacy';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'Genoz compares and explores genomic files (VCF) entirely on your device. It is an academic project for teaching and research.';

  @override
  String get pillarScience => 'Science';

  @override
  String get pillarScienceBody =>
      'Reliable information, with sources and methods in plain sight.';

  @override
  String get pillarPrivacy => 'Privacy';

  @override
  String get pillarPrivacyBody => 'Your data, on your device.';

  @override
  String get pillarPerformance => 'Performance';

  @override
  String get pillarPerformanceBody =>
      'Fast and precise analyses, even on large files.';

  @override
  String get pillarMultiplatform => 'Multiplatform';

  @override
  String get pillarMultiplatformBody =>
      'Web, Android and iOS with the same core.';

  @override
  String aboutVersion(String app, String core) {
    return 'App version $app · core $core';
  }

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get aboutSource => 'Source code: github.com/canavarrobr/Genoz';
}
