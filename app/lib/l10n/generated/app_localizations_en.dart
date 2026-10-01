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
  String regionOutside(String chrom) {
    return 'Invalid region. Use positions on chromosome $chrom, e.g. $chrom:1000-5000.';
  }

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

  @override
  String get privacyCheckTitle => 'Check privacy';

  @override
  String get privacyCheckIntro =>
      'These numbers are measured right now, on this device: Genoz records every network request it makes.';

  @override
  String get checkUpload => 'Genomic file uploaded';

  @override
  String get checkTelemetry => 'Telemetry';

  @override
  String get checkLocal => 'Local analysis';

  @override
  String get checkExternalDuring => 'External connections during analyses';

  @override
  String get checkNo => 'NO';

  @override
  String get checkYes => 'YES';

  @override
  String get checkRequestsTitle => 'Requests since the app opened';

  @override
  String checkOwnSite(int count) {
    return '$count to this site (loading the app)';
  }

  @override
  String checkExternal(int count) {
    return '$count to other addresses';
  }

  @override
  String get checkNoneNative =>
      'The app has not opened any network connection.';

  @override
  String get checkExport => 'Export audit report (JSON)';

  @override
  String get checkAirplane =>
      'Tip: turn on airplane mode and keep using Genoz — everything works offline.';

  @override
  String get checkLastRequests => 'Latest requests';

  @override
  String get checkWhyOwn =>
      'In the browser, opening the site downloads the app itself (code, fonts and the WebAssembly core). After that, nothing is sent.';

  @override
  String webTooLargeHint(int mb) {
    return 'In the browser each file can be up to $mb MB. For larger files, use the Android app.';
  }

  @override
  String get webUnsupported =>
      'This browser lacks required features (WebAssembly threads and private storage). Use an up-to-date Chrome, Edge or Firefox.';

  @override
  String get checkDuringTag => 'during analysis';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLock => 'Lock';

  @override
  String get settingsPinLock => 'Lock with PIN';

  @override
  String get settingsPinOn => 'Genoz asks for the PIN when opened';

  @override
  String get settingsPinOff => 'Off';

  @override
  String get settingsChangePin => 'Change PIN';

  @override
  String get settingsLockAfter => 'Ask again after';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get settingsBiometrics => 'Unlock with biometrics';

  @override
  String get settingsBiometricsUnavailable =>
      'No fingerprint or face enrolled on this device';

  @override
  String get settingsLockNote =>
      'The lock stops other people from opening Genoz on this device. It does not encrypt the files. The PIN cannot be recovered: if you forget it, the only way out is to delete all data.';

  @override
  String get settingsScreen => 'Screen';

  @override
  String get settingsSecureScreen => 'Protect the screen';

  @override
  String get settingsSecureScreenHint =>
      'Blocks screenshots and hides the content in the recent apps list';

  @override
  String get settingsData => 'Data';

  @override
  String get wipeTitle => 'Delete all data';

  @override
  String get wipeSubtitle =>
      'Projects, files, results, journal, settings and PIN';

  @override
  String get wipeBody =>
      'This deletes everything Genoz stored on this device: projects, copies of the VCF files, comparison results, notes, journal, settings and PIN. The original files you picked when importing are not touched. This cannot be undone.';

  @override
  String get wipeWord => 'DELETE';

  @override
  String wipeTypeWord(String word) {
    return 'To confirm, type $word:';
  }

  @override
  String get wipeButton => 'Delete everything';

  @override
  String get wipeDone => 'All data was deleted.';

  @override
  String get lockTitle => 'Genoz is locked';

  @override
  String get lockWrongPin => 'Wrong PIN';

  @override
  String lockWait(int seconds) {
    return 'Too many attempts. Wait $seconds s.';
  }

  @override
  String get lockUseBiometrics => 'Use biometrics';

  @override
  String get lockForgot => 'I forgot the PIN';

  @override
  String get lockForgotBody =>
      'The PIN is not stored anywhere — only a fingerprint of it that cannot be reversed. To use Genoz again without the PIN, all data on this device must be deleted. The original files you imported are not touched.';

  @override
  String get lockBack => 'Back';

  @override
  String get lockBiometricReason => 'Unlock Genoz';

  @override
  String pinDigitsEntered(int count) {
    return '$count digits entered';
  }

  @override
  String get pinErase => 'Erase digit';

  @override
  String get pinConfirm => 'Confirm';

  @override
  String get pinMismatch => 'The PINs don\'t match. Start over.';

  @override
  String get pinCurrent => 'Enter the current PIN';

  @override
  String get pinNew => 'Choose a PIN';

  @override
  String get pinRepeat => 'Repeat the PIN';

  @override
  String get pinRule => '4 to 8 digits';

  @override
  String get tabMap => 'Map';

  @override
  String get mapAll => 'All';

  @override
  String get mapUnknownBuild =>
      'Unknown reference build: each chromosome is drawn up to the largest position found, without a centromere.';

  @override
  String get mapFew => 'few';

  @override
  String get mapMany => 'many';

  @override
  String get mapCentromere => 'centromere (approximate position)';

  @override
  String mapChromSemantics(String chrom, int count) {
    return 'Chromosome $chrom: $count variants. Tap to see the region.';
  }

  @override
  String regionTitle(String chrom) {
    return 'Chromosome $chrom';
  }

  @override
  String get regionField => 'Region (e.g. 1:1,000,000-2,000,000)';

  @override
  String get regionZoomIn => 'Zoom in';

  @override
  String get regionZoomOut => 'Zoom out';

  @override
  String regionTrackSemantics(String region, int count) {
    return 'Track of region $region with $count variants. Double-tap to zoom in; drag sideways to move.';
  }

  @override
  String get regionLoading => 'Loading…';

  @override
  String regionShowing(int shown, int total) {
    return 'Showing $shown of $total variants — zoom in to see all.';
  }

  @override
  String regionCount(int count) {
    return '$count variants in this stretch';
  }

  @override
  String get regionNoVariants => 'No variants in this stretch.';

  @override
  String get vennTitle => 'Intersections';

  @override
  String vennSemantics(
    String a,
    String b,
    int onlyA,
    int both,
    int diff,
    int onlyB,
  ) {
    return 'Intersection diagram: $onlyA variants only in $a, $both in both ($diff with a different genotype), $onlyB only in $b.';
  }

  @override
  String vennOnly(String name) {
    return 'only in $name';
  }

  @override
  String get vennBoth => 'in both';

  @override
  String vennBreakdown(int same, int diff) {
    return '$same equal · $diff different genotype';
  }

  @override
  String vennOutside(int missing, int notAssessed) {
    return 'Outside the diagram: $missing missing/uncertain and $notAssessed not assessed.';
  }

  @override
  String get vennNotProportional =>
      'The circles are not to scale: the numbers give the amounts.';

  @override
  String get learnTitle => 'Learn';

  @override
  String get learnIntro =>
      'Guided tracks with fictional data: compare samples, read genotypes and explore the genome map. Everything runs on the device. For teaching — not a diagnosis.';

  @override
  String learnProgress(int correct, int total) {
    return '$correct of $total exercises right';
  }

  @override
  String get glossaryTitle => 'Glossary';

  @override
  String glossarySubtitle(int count) {
    return '$count terms, in Portuguese and English';
  }

  @override
  String get glossarySearch => 'Search term';

  @override
  String get glossaryNone => 'No term found.';

  @override
  String get packageImport => 'Import lesson package';

  @override
  String get packageImportHint => '.genozaula file received from the teacher';

  @override
  String get packageImporting =>
      'Importing the lesson: checking files and comparing…';

  @override
  String get packageProjectDescription =>
      'Lesson imported from a teacher package.';

  @override
  String packageImported(String title) {
    return 'Lesson \"$title\" imported.';
  }

  @override
  String packageError(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'notPackage': 'This file is not a Genoz lesson package.',
      'newerVersion':
          'This package was made by a newer Genoz version. Update the app.',
      'missingFile': 'The package is incomplete (a file is missing).',
      'corrupted': 'A file in the package is corrupted (SHA-256 mismatch). Nothing was imported.',
      'tooLarge': 'The package is too large for this device.',
      'other': 'Could not import the package.',
    });
    return '$_temp0';
  }

  @override
  String learnProjectName(String title) {
    return 'Lesson: $title';
  }

  @override
  String get learnProjectDescription => 'Fictional student-mode data.';

  @override
  String learnDataset(String title) {
    return 'Data: $title';
  }

  @override
  String learnOpenTab(String tab) {
    return 'Open $tab';
  }

  @override
  String get learnExercises => 'Exercises';

  @override
  String get learnPrepare => 'Prepare the lesson data';

  @override
  String get exerciseCorrect => 'Answered correctly';

  @override
  String get exerciseCheck => 'Check';

  @override
  String get exerciseReveal => 'Show answer';

  @override
  String get exerciseUnavailable =>
      'This answer cannot be computed with these data.';

  @override
  String get exerciseRight => 'Right!';

  @override
  String get exerciseWrong => 'Not yet.';

  @override
  String exerciseAnswer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String get packageCreateTitle => 'Create lesson package';

  @override
  String get packageCreateIntro =>
      'Turns this comparison into a .genozaula file for students. They import it in Learn and get the same files, the comparison ready and the questions.';

  @override
  String get packageTitleField => 'Lesson title';

  @override
  String get packageInstructionsField => 'Instructions for students (optional)';

  @override
  String get packageQuestions => 'Questions (graded automatically)';

  @override
  String get packagePrivacyNote =>
      'The package carries copies of this comparison\'s VCF files. Use only fictional data or data you are authorized to share. The answers are not in the package: they are computed on each student\'s device.';

  @override
  String get packageSave => 'Save package';

  @override
  String get packageSaved => 'Lesson package saved.';

  @override
  String get exerciseHint => 'Your answer';

  @override
  String get packageOpenStep =>
      'Open the lesson\'s comparison: the answers are in the Summary, the Table and the Map.';
}
