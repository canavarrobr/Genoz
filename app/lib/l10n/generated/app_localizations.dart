import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Genoz'**
  String get appTitle;

  /// No description provided for @privateMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo privado — processamento local'**
  String get privateMode;

  /// No description provided for @privacyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua privacidade'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In pt, this message translates to:
  /// **'No modo privado, o Genoz processa seus arquivos genômicos somente neste aparelho. Nada é enviado a servidores, não há conta nem telemetria.\n\nOs arquivos importados ficam numa pasta privada do app. Apagar um projeto apaga também os arquivos dele.'**
  String get privacyBody;

  /// No description provided for @notDiagnosis.
  ///
  /// In pt, this message translates to:
  /// **'Uso educacional e de pesquisa. Não é diagnóstico.'**
  String get notDiagnosis;

  /// No description provided for @ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get rename;

  /// No description provided for @projectsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum projeto ainda'**
  String get projectsEmptyTitle;

  /// No description provided for @projectsEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Crie um projeto para importar arquivos VCF e comparar amostras.'**
  String get projectsEmptyBody;

  /// No description provided for @newProject.
  ///
  /// In pt, this message translates to:
  /// **'Novo projeto'**
  String get newProject;

  /// No description provided for @projectName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do projeto'**
  String get projectName;

  /// No description provided for @projectDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get projectDescription;

  /// No description provided for @projectNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Dê um nome ao projeto'**
  String get projectNameRequired;

  /// No description provided for @filesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhum arquivo} =1{1 arquivo} other{{count} arquivos}}'**
  String filesCount(int count);

  /// No description provided for @deleteProjectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar projeto?'**
  String get deleteProjectTitle;

  /// No description provided for @deleteProjectBody.
  ///
  /// In pt, this message translates to:
  /// **'O projeto \"{name}\" e todos os seus arquivos serão apagados deste aparelho. Isso não pode ser desfeito.'**
  String deleteProjectBody(String name);

  /// No description provided for @deleteFileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover arquivo?'**
  String get deleteFileTitle;

  /// No description provided for @deleteFileBody.
  ///
  /// In pt, this message translates to:
  /// **'A cópia de \"{name}\" guardada pelo Genoz será apagada. O arquivo original não é afetado.'**
  String deleteFileBody(String name);

  /// No description provided for @importVcf.
  ///
  /// In pt, this message translates to:
  /// **'Importar VCF'**
  String get importVcf;

  /// No description provided for @generateExample.
  ///
  /// In pt, this message translates to:
  /// **'Gerar exemplo sintético'**
  String get generateExample;

  /// No description provided for @generateExampleHint.
  ///
  /// In pt, this message translates to:
  /// **'Cria um VCF fictício para experimentar o app sem dados reais.'**
  String get generateExampleHint;

  /// No description provided for @filesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum arquivo neste projeto'**
  String get filesEmptyTitle;

  /// No description provided for @filesEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Importe um arquivo VCF (.vcf ou .vcf.gz) ou gere um exemplo sintético.'**
  String get filesEmptyBody;

  /// No description provided for @importCopying.
  ///
  /// In pt, this message translates to:
  /// **'Copiando e calculando o SHA-256…'**
  String get importCopying;

  /// No description provided for @importValidating.
  ///
  /// In pt, this message translates to:
  /// **'Validando o VCF…'**
  String get importValidating;

  /// No description provided for @importing.
  ///
  /// In pt, this message translates to:
  /// **'Importando {name}'**
  String importing(String name);

  /// No description provided for @importCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Importação cancelada.'**
  String get importCancelled;

  /// No description provided for @importFailedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível importar'**
  String get importFailedTitle;

  /// No description provided for @importInvalidTitle.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo inválido'**
  String get importInvalidTitle;

  /// No description provided for @importInvalidBody.
  ///
  /// In pt, this message translates to:
  /// **'O Genoz leu o arquivo, mas nenhuma variante pôde ser usada.'**
  String get importInvalidBody;

  /// No description provided for @importDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo já foi importado neste projeto (\"{name}\").'**
  String importDuplicate(String name);

  /// No description provided for @importDone.
  ///
  /// In pt, this message translates to:
  /// **'\"{name}\" importado.'**
  String importDone(String name);

  /// No description provided for @verdictValid.
  ///
  /// In pt, this message translates to:
  /// **'Válido'**
  String get verdictValid;

  /// No description provided for @verdictValidWithWarnings.
  ///
  /// In pt, this message translates to:
  /// **'Válido com avisos'**
  String get verdictValidWithWarnings;

  /// No description provided for @verdictPartiallyValid.
  ///
  /// In pt, this message translates to:
  /// **'Parcialmente válido'**
  String get verdictPartiallyValid;

  /// No description provided for @verdictInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Inválido'**
  String get verdictInvalid;

  /// No description provided for @samplesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{apenas sítios} =1{1 amostra} other{{count} amostras}}'**
  String samplesCount(int count);

  /// No description provided for @variantsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} variantes'**
  String variantsCount(int count);

  /// No description provided for @buildUnknown.
  ///
  /// In pt, this message translates to:
  /// **'build desconhecido'**
  String get buildUnknown;

  /// No description provided for @sectionFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get sectionFile;

  /// No description provided for @sectionBuild.
  ///
  /// In pt, this message translates to:
  /// **'Genoma de referência'**
  String get sectionBuild;

  /// No description provided for @sectionSamples.
  ///
  /// In pt, this message translates to:
  /// **'Amostras'**
  String get sectionSamples;

  /// No description provided for @sectionKinds.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de variante'**
  String get sectionKinds;

  /// No description provided for @sectionChromosomes.
  ///
  /// In pt, this message translates to:
  /// **'Cromossomos'**
  String get sectionChromosomes;

  /// No description provided for @sectionProblems.
  ///
  /// In pt, this message translates to:
  /// **'Problemas encontrados'**
  String get sectionProblems;

  /// No description provided for @fieldSha256.
  ///
  /// In pt, this message translates to:
  /// **'SHA-256'**
  String get fieldSha256;

  /// No description provided for @fieldSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get fieldSize;

  /// No description provided for @fieldCompression.
  ///
  /// In pt, this message translates to:
  /// **'Compressão'**
  String get fieldCompression;

  /// No description provided for @fieldFormat.
  ///
  /// In pt, this message translates to:
  /// **'Formato'**
  String get fieldFormat;

  /// No description provided for @fieldRecords.
  ///
  /// In pt, this message translates to:
  /// **'Registros'**
  String get fieldRecords;

  /// No description provided for @fieldMultiallelic.
  ///
  /// In pt, this message translates to:
  /// **'Multialélicos'**
  String get fieldMultiallelic;

  /// No description provided for @fieldFilter.
  ///
  /// In pt, this message translates to:
  /// **'FILTER'**
  String get fieldFilter;

  /// No description provided for @fieldSorted.
  ///
  /// In pt, this message translates to:
  /// **'Ordenado'**
  String get fieldSorted;

  /// No description provided for @fieldChromStyle.
  ///
  /// In pt, this message translates to:
  /// **'Nomes dos cromossomos'**
  String get fieldChromStyle;

  /// No description provided for @recordsSummary.
  ///
  /// In pt, this message translates to:
  /// **'{ok} válidos de {read} ({rejected} descartados)'**
  String recordsSummary(int ok, int read, int rejected);

  /// No description provided for @multiallelicSummary.
  ///
  /// In pt, this message translates to:
  /// **'{multi} → {split} registros bialélicos'**
  String multiallelicSummary(int multi, int split);

  /// No description provided for @filterSummary.
  ///
  /// In pt, this message translates to:
  /// **'PASS {pass} · filtrados {failed} · sem filtro {missing}'**
  String filterSummary(int pass, int failed, int missing);

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'sim'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'não'**
  String get no;

  /// No description provided for @confidence.
  ///
  /// In pt, this message translates to:
  /// **'confiança {level}'**
  String confidence(String level);

  /// No description provided for @colHomRef.
  ///
  /// In pt, this message translates to:
  /// **'0/0'**
  String get colHomRef;

  /// No description provided for @colHet.
  ///
  /// In pt, this message translates to:
  /// **'het'**
  String get colHet;

  /// No description provided for @colHomAlt.
  ///
  /// In pt, this message translates to:
  /// **'hom-alt'**
  String get colHomAlt;

  /// No description provided for @colMissing.
  ///
  /// In pt, this message translates to:
  /// **'ausente'**
  String get colMissing;

  /// No description provided for @problemsNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum problema encontrado.'**
  String get problemsNone;

  /// No description provided for @problemsCount.
  ///
  /// In pt, this message translates to:
  /// **'{errors} erros · {warnings} avisos'**
  String problemsCount(int errors, int warnings);

  /// No description provided for @problemsTruncated.
  ///
  /// In pt, this message translates to:
  /// **'Lista resumida: só os primeiros problemas aparecem.'**
  String get problemsTruncated;

  /// No description provided for @lineHeader.
  ///
  /// In pt, this message translates to:
  /// **'cabeçalho'**
  String get lineHeader;

  /// No description provided for @lineNumber.
  ///
  /// In pt, this message translates to:
  /// **'linha {n}'**
  String lineNumber(int n);

  /// No description provided for @readInterrupted.
  ///
  /// In pt, this message translates to:
  /// **'Leitura interrompida: {reason}'**
  String readInterrupted(String reason);

  /// No description provided for @coreVersion.
  ///
  /// In pt, this message translates to:
  /// **'Núcleo {version}'**
  String coreVersion(String version);

  /// No description provided for @fileNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo não encontrado.'**
  String get fileNotFound;

  /// No description provided for @kindSnv.
  ///
  /// In pt, this message translates to:
  /// **'SNV'**
  String get kindSnv;

  /// No description provided for @kindMnv.
  ///
  /// In pt, this message translates to:
  /// **'MNV'**
  String get kindMnv;

  /// No description provided for @kindInsertion.
  ///
  /// In pt, this message translates to:
  /// **'inserção'**
  String get kindInsertion;

  /// No description provided for @kindDeletion.
  ///
  /// In pt, this message translates to:
  /// **'deleção'**
  String get kindDeletion;

  /// No description provided for @kindComplex.
  ///
  /// In pt, this message translates to:
  /// **'indel complexo'**
  String get kindComplex;

  /// No description provided for @kindStructural.
  ///
  /// In pt, this message translates to:
  /// **'estrutural/simbólico'**
  String get kindStructural;

  /// No description provided for @kindOther.
  ///
  /// In pt, this message translates to:
  /// **'outro'**
  String get kindOther;

  /// No description provided for @compNone.
  ///
  /// In pt, this message translates to:
  /// **'nenhuma (texto)'**
  String get compNone;

  /// No description provided for @compGzip.
  ///
  /// In pt, this message translates to:
  /// **'gzip comum (não indexável)'**
  String get compGzip;

  /// No description provided for @compBgzf.
  ///
  /// In pt, this message translates to:
  /// **'BGZF (indexável)'**
  String get compBgzf;

  /// No description provided for @styleUcsc.
  ///
  /// In pt, this message translates to:
  /// **'UCSC (chr1, chrX)'**
  String get styleUcsc;

  /// No description provided for @styleEnsembl.
  ///
  /// In pt, this message translates to:
  /// **'Ensembl/NCBI (1, X)'**
  String get styleEnsembl;

  /// No description provided for @styleMixed.
  ///
  /// In pt, this message translates to:
  /// **'misto (chr1 e 1)'**
  String get styleMixed;

  /// No description provided for @styleUnknown.
  ///
  /// In pt, this message translates to:
  /// **'indeterminado'**
  String get styleUnknown;

  /// No description provided for @confHigh.
  ///
  /// In pt, this message translates to:
  /// **'alta'**
  String get confHigh;

  /// No description provided for @confLow.
  ///
  /// In pt, this message translates to:
  /// **'baixa'**
  String get confLow;

  /// No description provided for @confNone.
  ///
  /// In pt, this message translates to:
  /// **'nenhuma'**
  String get confNone;

  /// No description provided for @importFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get importFile;

  /// No description provided for @fileMenuReport.
  ///
  /// In pt, this message translates to:
  /// **'Ver relatório'**
  String get fileMenuReport;

  /// No description provided for @compareTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comparar A × B'**
  String get compareTitle;

  /// No description provided for @compareNeedsFiles.
  ///
  /// In pt, this message translates to:
  /// **'Importe ao menos um arquivo VCF para comparar.'**
  String get compareNeedsFiles;

  /// No description provided for @sideA.
  ///
  /// In pt, this message translates to:
  /// **'Amostra A'**
  String get sideA;

  /// No description provided for @sideB.
  ///
  /// In pt, this message translates to:
  /// **'Amostra B'**
  String get sideB;

  /// No description provided for @chooseFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get chooseFile;

  /// No description provided for @chooseSample.
  ///
  /// In pt, this message translates to:
  /// **'Amostra'**
  String get chooseSample;

  /// No description provided for @firstSample.
  ///
  /// In pt, this message translates to:
  /// **'(primeira do arquivo)'**
  String get firstSample;

  /// No description provided for @qualityGate.
  ///
  /// In pt, this message translates to:
  /// **'Portão de qualidade'**
  String get qualityGate;

  /// No description provided for @qualityGateHint.
  ///
  /// In pt, this message translates to:
  /// **'Chamadas reprovadas viram “incertas”, nunca “ausentes”.'**
  String get qualityGateHint;

  /// No description provided for @passOnly.
  ///
  /// In pt, this message translates to:
  /// **'Somente FILTER = PASS'**
  String get passOnly;

  /// No description provided for @minQual.
  ///
  /// In pt, this message translates to:
  /// **'QUAL mínimo'**
  String get minQual;

  /// No description provided for @minDp.
  ///
  /// In pt, this message translates to:
  /// **'DP mínimo'**
  String get minDp;

  /// No description provided for @minGq.
  ///
  /// In pt, this message translates to:
  /// **'GQ mínimo'**
  String get minGq;

  /// No description provided for @truthLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tratar como verdade (benchmark)'**
  String get truthLabel;

  /// No description provided for @truthNone.
  ///
  /// In pt, this message translates to:
  /// **'nenhuma'**
  String get truthNone;

  /// No description provided for @runCompare.
  ///
  /// In pt, this message translates to:
  /// **'Comparar'**
  String get runCompare;

  /// No description provided for @comparing.
  ///
  /// In pt, this message translates to:
  /// **'Comparando…'**
  String get comparing;

  /// No description provided for @compareFailedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível comparar'**
  String get compareFailedTitle;

  /// No description provided for @compareCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Comparação cancelada.'**
  String get compareCancelled;

  /// No description provided for @sameSampleWarning.
  ///
  /// In pt, this message translates to:
  /// **'A e B são a mesma amostra do mesmo arquivo: o resultado será tudo “compartilhada”.'**
  String get sameSampleWarning;

  /// No description provided for @analysesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análises'**
  String get analysesTitle;

  /// No description provided for @analysisVs.
  ///
  /// In pt, this message translates to:
  /// **'{a} × {b}'**
  String analysisVs(String a, String b);

  /// No description provided for @deleteAnalysisTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar análise?'**
  String get deleteAnalysisTitle;

  /// No description provided for @deleteAnalysisBody.
  ///
  /// In pt, this message translates to:
  /// **'Os resultados desta comparação serão apagados. Os arquivos VCF continuam no projeto.'**
  String get deleteAnalysisBody;

  /// No description provided for @analysisNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Análise não encontrada.'**
  String get analysisNotFound;

  /// No description provided for @catShared.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhada'**
  String get catShared;

  /// No description provided for @catGenotypeDifference.
  ///
  /// In pt, this message translates to:
  /// **'Genótipo diferente'**
  String get catGenotypeDifference;

  /// No description provided for @catOnlyA.
  ///
  /// In pt, this message translates to:
  /// **'Somente em A'**
  String get catOnlyA;

  /// No description provided for @catOnlyB.
  ///
  /// In pt, this message translates to:
  /// **'Somente em B'**
  String get catOnlyB;

  /// No description provided for @catMissingUncertain.
  ///
  /// In pt, this message translates to:
  /// **'Ausente/incerta'**
  String get catMissingUncertain;

  /// No description provided for @catNotAssessed.
  ///
  /// In pt, this message translates to:
  /// **'Não avaliada'**
  String get catNotAssessed;

  /// No description provided for @stCarrier.
  ///
  /// In pt, this message translates to:
  /// **'carrega o alelo'**
  String get stCarrier;

  /// No description provided for @stLowQuality.
  ///
  /// In pt, this message translates to:
  /// **'carrega, baixa qualidade'**
  String get stLowQuality;

  /// No description provided for @stExplicitRef.
  ///
  /// In pt, this message translates to:
  /// **'0/0 explícito'**
  String get stExplicitRef;

  /// No description provided for @stMissing.
  ///
  /// In pt, this message translates to:
  /// **'genótipo ausente'**
  String get stMissing;

  /// No description provided for @stAbsentRefBlock.
  ///
  /// In pt, this message translates to:
  /// **'referência (bloco gVCF)'**
  String get stAbsentRefBlock;

  /// No description provided for @stAbsentCallable.
  ///
  /// In pt, this message translates to:
  /// **'sem registro (região avaliada)'**
  String get stAbsentCallable;

  /// No description provided for @stAbsentUnknown.
  ///
  /// In pt, this message translates to:
  /// **'sem registro'**
  String get stAbsentUnknown;

  /// No description provided for @stNotAssessed.
  ///
  /// In pt, this message translates to:
  /// **'fora da região avaliada'**
  String get stNotAssessed;

  /// No description provided for @tabSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get tabSummary;

  /// No description provided for @tabTable.
  ///
  /// In pt, this message translates to:
  /// **'Tabela'**
  String get tabTable;

  /// No description provided for @tabQc.
  ///
  /// In pt, this message translates to:
  /// **'QC'**
  String get tabQc;

  /// No description provided for @concordance.
  ///
  /// In pt, this message translates to:
  /// **'Concordância de genótipos'**
  String get concordance;

  /// No description provided for @jaccard.
  ///
  /// In pt, this message translates to:
  /// **'Jaccard (sítios)'**
  String get jaccard;

  /// No description provided for @benchmarkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Benchmark (verdade: {side})'**
  String benchmarkTitle(String side);

  /// No description provided for @precision.
  ///
  /// In pt, this message translates to:
  /// **'Precisão'**
  String get precision;

  /// No description provided for @recall.
  ///
  /// In pt, this message translates to:
  /// **'Sensibilidade'**
  String get recall;

  /// No description provided for @f1.
  ///
  /// In pt, this message translates to:
  /// **'F1'**
  String get f1;

  /// No description provided for @classAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get classAll;

  /// No description provided for @warningsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avisos'**
  String get warningsTitle;

  /// No description provided for @modeInMemory.
  ///
  /// In pt, this message translates to:
  /// **'Comparação feita em memória (arquivos fora de ordem).'**
  String get modeInMemory;

  /// No description provided for @absenceHint.
  ///
  /// In pt, this message translates to:
  /// **'Sem BED de regiões avaliadas ou gVCF, “somente em A/B” inclui posições sem registro no outro arquivo — que podem simplesmente não ter sido sequenciadas.'**
  String get absenceHint;

  /// No description provided for @rowsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} linhas'**
  String rowsCount(int count);

  /// No description provided for @filters.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get clearFilters;

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'chr1:1000, chr7:1M-2M ou rs123'**
  String get searchHint;

  /// No description provided for @noRows.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma linha com esses filtros.'**
  String get noRows;

  /// No description provided for @saveFilter.
  ///
  /// In pt, this message translates to:
  /// **'Salvar filtro'**
  String get saveFilter;

  /// No description provided for @filterName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do filtro'**
  String get filterName;

  /// No description provided for @savedFilters.
  ///
  /// In pt, this message translates to:
  /// **'Filtros salvos'**
  String get savedFilters;

  /// No description provided for @categoriesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get categoriesLabel;

  /// No description provided for @kindsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de variante'**
  String get kindsLabel;

  /// No description provided for @regionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Região'**
  String get regionLabel;

  /// No description provided for @regionInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Região inválida (ex.: chr1:1000-2000)'**
  String get regionInvalid;

  /// No description provided for @idLabel.
  ///
  /// In pt, this message translates to:
  /// **'ID contém'**
  String get idLabel;

  /// No description provided for @apply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @stateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get stateLabel;

  /// No description provided for @gtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Genótipo'**
  String get gtLabel;

  /// No description provided for @qualLabel.
  ///
  /// In pt, this message translates to:
  /// **'QUAL'**
  String get qualLabel;

  /// No description provided for @dpLabel.
  ///
  /// In pt, this message translates to:
  /// **'DP'**
  String get dpLabel;

  /// No description provided for @gqLabel.
  ///
  /// In pt, this message translates to:
  /// **'GQ'**
  String get gqLabel;

  /// No description provided for @filterLabel.
  ///
  /// In pt, this message translates to:
  /// **'FILTER'**
  String get filterLabel;

  /// No description provided for @idsLabel.
  ///
  /// In pt, this message translates to:
  /// **'IDs'**
  String get idsLabel;

  /// No description provided for @noteLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nota'**
  String get noteLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas (separadas por vírgula)'**
  String get tagsLabel;

  /// No description provided for @favorite.
  ///
  /// In pt, this message translates to:
  /// **'Favorita'**
  String get favorite;

  /// No description provided for @noteSaved.
  ///
  /// In pt, this message translates to:
  /// **'Nota salva.'**
  String get noteSaved;

  /// No description provided for @tiTvHint.
  ///
  /// In pt, this message translates to:
  /// **'Referência: ~2,0–2,1 em genoma; ~3,0 em exoma.'**
  String get tiTvHint;

  /// No description provided for @hetHom.
  ///
  /// In pt, this message translates to:
  /// **'het / hom-alt'**
  String get hetHom;

  /// No description provided for @missingRate.
  ///
  /// In pt, this message translates to:
  /// **'Ausentes'**
  String get missingRate;

  /// No description provided for @carriers.
  ///
  /// In pt, this message translates to:
  /// **'Variantes carregadas'**
  String get carriers;

  /// No description provided for @lowQualityCount.
  ///
  /// In pt, this message translates to:
  /// **'Baixa qualidade'**
  String get lowQualityCount;

  /// No description provided for @dpDistribution.
  ///
  /// In pt, this message translates to:
  /// **'Profundidade (DP)'**
  String get dpDistribution;

  /// No description provided for @gqDistribution.
  ///
  /// In pt, this message translates to:
  /// **'Qualidade do genótipo (GQ)'**
  String get gqDistribution;

  /// No description provided for @qualDistribution.
  ///
  /// In pt, this message translates to:
  /// **'QUAL'**
  String get qualDistribution;

  /// No description provided for @xHet.
  ///
  /// In pt, this message translates to:
  /// **'Heterozigosidade no X (fora das PAR)'**
  String get xHet;

  /// No description provided for @xHetHint.
  ///
  /// In pt, this message translates to:
  /// **'Indicador educacional de consistência; não determina sexo.'**
  String get xHetHint;

  /// No description provided for @export.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get export;

  /// No description provided for @exportFormat.
  ///
  /// In pt, this message translates to:
  /// **'Formato'**
  String get exportFormat;

  /// No description provided for @exportFiltered.
  ///
  /// In pt, this message translates to:
  /// **'Exporta as {count} linhas do filtro atual, com o manifesto de reprodutibilidade.'**
  String exportFiltered(int count);

  /// No description provided for @exportDone.
  ///
  /// In pt, this message translates to:
  /// **'{count} linhas exportadas.'**
  String exportDone(int count);

  /// No description provided for @exportSaveManifest.
  ///
  /// In pt, this message translates to:
  /// **'Salvar também o manifesto?'**
  String get exportSaveManifest;

  /// No description provided for @exportSaveManifestBody.
  ///
  /// In pt, this message translates to:
  /// **'O manifesto registra entradas, parâmetros e hashes para refazer esta análise.'**
  String get exportSaveManifestBody;

  /// No description provided for @journalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Diário do projeto'**
  String get journalTitle;

  /// No description provided for @journalEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada registrado ainda.'**
  String get journalEmpty;

  /// No description provided for @notesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notas e favoritas'**
  String get notesTitle;

  /// No description provided for @notesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Toque numa variante da tabela para anotar ou favoritar.'**
  String get notesEmpty;

  /// No description provided for @logImport.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo importado: {name}'**
  String logImport(String name);

  /// No description provided for @logDeleteFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo removido: {name}'**
  String logDeleteFile(String name);

  /// No description provided for @logCompare.
  ///
  /// In pt, this message translates to:
  /// **'Comparação {a} × {b} ({id})'**
  String logCompare(String a, String b, String id);

  /// No description provided for @logExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportação {format}: {count} linhas'**
  String logExport(String format, int count);

  /// No description provided for @logFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtro salvo: {name}'**
  String logFilter(String name);

  /// No description provided for @logDeleteAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise apagada: {name}'**
  String logDeleteAnalysis(String name);

  /// No description provided for @minQualShort.
  ///
  /// In pt, this message translates to:
  /// **'QUAL ≥'**
  String get minQualShort;

  /// No description provided for @minDpShort.
  ///
  /// In pt, this message translates to:
  /// **'DP ≥'**
  String get minDpShort;

  /// No description provided for @minGqShort.
  ///
  /// In pt, this message translates to:
  /// **'GQ ≥'**
  String get minGqShort;

  /// No description provided for @exportVcf.
  ///
  /// In pt, this message translates to:
  /// **'VCF (A e B)'**
  String get exportVcf;

  /// No description provided for @notNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get notNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
