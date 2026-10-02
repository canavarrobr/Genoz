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
  /// **'BRCA2, chr7:1M-2M ou rs123'**
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

  /// No description provided for @regionOutside.
  ///
  /// In pt, this message translates to:
  /// **'Região inválida. Use posições do cromossomo {chrom}, ex.: {chrom}:1000-5000.'**
  String regionOutside(String chrom);

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

  /// No description provided for @brandSignature.
  ///
  /// In pt, this message translates to:
  /// **'GENÔMICA SEM FRONTEIRAS'**
  String get brandSignature;

  /// No description provided for @brandSlogan.
  ///
  /// In pt, this message translates to:
  /// **'Sua genômica, no seu controle.'**
  String get brandSlogan;

  /// No description provided for @brandSplash.
  ///
  /// In pt, this message translates to:
  /// **'Análise genômica local e privada'**
  String get brandSplash;

  /// No description provided for @menuProjects.
  ///
  /// In pt, this message translates to:
  /// **'Projetos'**
  String get menuProjects;

  /// No description provided for @menuAbout.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o Genoz'**
  String get menuAbout;

  /// No description provided for @menuPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get menuPrivacy;

  /// No description provided for @aboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In pt, this message translates to:
  /// **'O Genoz compara e explora arquivos genômicos (VCF) inteiramente no seu dispositivo. É um projeto acadêmico para ensino e pesquisa.'**
  String get aboutBody;

  /// No description provided for @pillarScience.
  ///
  /// In pt, this message translates to:
  /// **'Ciência'**
  String get pillarScience;

  /// No description provided for @pillarScienceBody.
  ///
  /// In pt, this message translates to:
  /// **'Informação confiável, com as fontes e os métodos à vista.'**
  String get pillarScienceBody;

  /// No description provided for @pillarPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get pillarPrivacy;

  /// No description provided for @pillarPrivacyBody.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados, no seu dispositivo.'**
  String get pillarPrivacyBody;

  /// No description provided for @pillarPerformance.
  ///
  /// In pt, this message translates to:
  /// **'Desempenho'**
  String get pillarPerformance;

  /// No description provided for @pillarPerformanceBody.
  ///
  /// In pt, this message translates to:
  /// **'Análises rápidas e precisas, mesmo em arquivos grandes.'**
  String get pillarPerformanceBody;

  /// No description provided for @pillarMultiplatform.
  ///
  /// In pt, this message translates to:
  /// **'Multiplataforma'**
  String get pillarMultiplatform;

  /// No description provided for @pillarMultiplatformBody.
  ///
  /// In pt, this message translates to:
  /// **'Web, Android e iOS com o mesmo núcleo.'**
  String get pillarMultiplatformBody;

  /// No description provided for @aboutVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão do app {app} · núcleo {core}'**
  String aboutVersion(String app, String core);

  /// No description provided for @aboutLicenses.
  ///
  /// In pt, this message translates to:
  /// **'Licenças de código aberto'**
  String get aboutLicenses;

  /// No description provided for @aboutSource.
  ///
  /// In pt, this message translates to:
  /// **'Código-fonte: github.com/canavarrobr/Genoz'**
  String get aboutSource;

  /// No description provided for @privacyCheckTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verificar privacidade'**
  String get privacyCheckTitle;

  /// No description provided for @privacyCheckIntro.
  ///
  /// In pt, this message translates to:
  /// **'Estes números são medidos agora, neste dispositivo: o Genoz registra cada requisição de rede que faz.'**
  String get privacyCheckIntro;

  /// No description provided for @checkUpload.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo genômico enviado'**
  String get checkUpload;

  /// No description provided for @checkTelemetry.
  ///
  /// In pt, this message translates to:
  /// **'Telemetria'**
  String get checkTelemetry;

  /// No description provided for @checkLocal.
  ///
  /// In pt, this message translates to:
  /// **'Análise local'**
  String get checkLocal;

  /// No description provided for @checkExternalDuring.
  ///
  /// In pt, this message translates to:
  /// **'Conexões externas durante análises'**
  String get checkExternalDuring;

  /// No description provided for @checkNo.
  ///
  /// In pt, this message translates to:
  /// **'NÃO'**
  String get checkNo;

  /// No description provided for @checkYes.
  ///
  /// In pt, this message translates to:
  /// **'SIM'**
  String get checkYes;

  /// No description provided for @checkRequestsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Requisições desde que o app abriu'**
  String get checkRequestsTitle;

  /// No description provided for @checkOwnSite.
  ///
  /// In pt, this message translates to:
  /// **'{count} do próprio site (carregar o app)'**
  String checkOwnSite(int count);

  /// No description provided for @checkExternal.
  ///
  /// In pt, this message translates to:
  /// **'{count} para outros endereços'**
  String checkExternal(int count);

  /// No description provided for @checkNoneNative.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conexão de rede foi aberta pelo app.'**
  String get checkNoneNative;

  /// No description provided for @checkExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar relatório de auditoria (JSON)'**
  String get checkExport;

  /// No description provided for @checkAirplane.
  ///
  /// In pt, this message translates to:
  /// **'Dica: ative o modo avião e continue usando o Genoz — tudo funciona sem internet.'**
  String get checkAirplane;

  /// No description provided for @checkLastRequests.
  ///
  /// In pt, this message translates to:
  /// **'Últimas requisições'**
  String get checkLastRequests;

  /// No description provided for @checkWhyOwn.
  ///
  /// In pt, this message translates to:
  /// **'No navegador, abrir o site baixa o próprio app (código, fontes e o núcleo WebAssembly). Depois disso, nada é enviado.'**
  String get checkWhyOwn;

  /// No description provided for @webTooLargeHint.
  ///
  /// In pt, this message translates to:
  /// **'No navegador cada arquivo pode ter até {mb} MB. Para arquivos maiores, use o app Android.'**
  String webTooLargeHint(int mb);

  /// No description provided for @webUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'Este navegador não oferece os recursos necessários (WebAssembly com threads e armazenamento privado). Use Chrome, Edge ou Firefox atualizados.'**
  String get webUnsupported;

  /// No description provided for @checkDuringTag.
  ///
  /// In pt, this message translates to:
  /// **'durante análise'**
  String get checkDuringTag;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get settingsSystem;

  /// No description provided for @settingsLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get settingsDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsLock.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueio'**
  String get settingsLock;

  /// No description provided for @settingsPinLock.
  ///
  /// In pt, this message translates to:
  /// **'Bloquear com PIN'**
  String get settingsPinLock;

  /// No description provided for @settingsPinOn.
  ///
  /// In pt, this message translates to:
  /// **'O Genoz pede o PIN ao abrir'**
  String get settingsPinOn;

  /// No description provided for @settingsPinOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligado'**
  String get settingsPinOff;

  /// No description provided for @settingsChangePin.
  ///
  /// In pt, this message translates to:
  /// **'Trocar o PIN'**
  String get settingsChangePin;

  /// No description provided for @settingsLockAfter.
  ///
  /// In pt, this message translates to:
  /// **'Pedir de novo após'**
  String get settingsLockAfter;

  /// No description provided for @minutes.
  ///
  /// In pt, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @settingsBiometrics.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear com biometria'**
  String get settingsBiometrics;

  /// No description provided for @settingsBiometricsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma digital ou rosto cadastrado neste aparelho'**
  String get settingsBiometricsUnavailable;

  /// No description provided for @settingsLockNote.
  ///
  /// In pt, this message translates to:
  /// **'O bloqueio impede que outra pessoa abra o Genoz neste aparelho. Ele não criptografa os arquivos. O PIN não pode ser recuperado: se você o esquecer, a única saída é apagar todos os dados.'**
  String get settingsLockNote;

  /// No description provided for @settingsScreen.
  ///
  /// In pt, this message translates to:
  /// **'Tela'**
  String get settingsScreen;

  /// No description provided for @settingsSecureScreen.
  ///
  /// In pt, this message translates to:
  /// **'Proteger a tela'**
  String get settingsSecureScreen;

  /// No description provided for @settingsSecureScreenHint.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueia capturas de tela e esconde o conteúdo na lista de apps recentes'**
  String get settingsSecureScreenHint;

  /// No description provided for @settingsData.
  ///
  /// In pt, this message translates to:
  /// **'Dados'**
  String get settingsData;

  /// No description provided for @wipeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os dados'**
  String get wipeTitle;

  /// No description provided for @wipeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Projetos, arquivos, resultados, diário, ajustes e PIN'**
  String get wipeSubtitle;

  /// No description provided for @wipeBody.
  ///
  /// In pt, this message translates to:
  /// **'Isto apaga do aparelho tudo o que o Genoz guardou: projetos, cópias dos arquivos VCF, resultados das comparações, anotações, diário, ajustes e PIN. Os arquivos originais que você escolheu ao importar não são tocados. Não há como desfazer.'**
  String get wipeBody;

  /// No description provided for @wipeWord.
  ///
  /// In pt, this message translates to:
  /// **'APAGAR'**
  String get wipeWord;

  /// No description provided for @wipeTypeWord.
  ///
  /// In pt, this message translates to:
  /// **'Para confirmar, digite {word}:'**
  String wipeTypeWord(String word);

  /// No description provided for @wipeButton.
  ///
  /// In pt, this message translates to:
  /// **'Apagar tudo'**
  String get wipeButton;

  /// No description provided for @wipeDone.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados foram apagados.'**
  String get wipeDone;

  /// No description provided for @lockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Genoz bloqueado'**
  String get lockTitle;

  /// No description provided for @lockWrongPin.
  ///
  /// In pt, this message translates to:
  /// **'PIN incorreto'**
  String get lockWrongPin;

  /// No description provided for @lockWait.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde {seconds} s.'**
  String lockWait(int seconds);

  /// No description provided for @lockUseBiometrics.
  ///
  /// In pt, this message translates to:
  /// **'Usar biometria'**
  String get lockUseBiometrics;

  /// No description provided for @lockForgot.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci o PIN'**
  String get lockForgot;

  /// No description provided for @lockForgotBody.
  ///
  /// In pt, this message translates to:
  /// **'O PIN não fica guardado em lugar nenhum, só uma impressão dele que não pode ser revertida. Para voltar a usar o Genoz sem o PIN, é preciso apagar todos os dados deste aparelho. Os arquivos originais que você importou não são tocados.'**
  String get lockForgotBody;

  /// No description provided for @lockBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get lockBack;

  /// No description provided for @lockBiometricReason.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear o Genoz'**
  String get lockBiometricReason;

  /// No description provided for @pinDigitsEntered.
  ///
  /// In pt, this message translates to:
  /// **'{count} dígitos digitados'**
  String pinDigitsEntered(int count);

  /// No description provided for @pinErase.
  ///
  /// In pt, this message translates to:
  /// **'Apagar dígito'**
  String get pinErase;

  /// No description provided for @pinConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get pinConfirm;

  /// No description provided for @pinMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Os PINs não conferem. Comece de novo.'**
  String get pinMismatch;

  /// No description provided for @pinCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Digite o PIN atual'**
  String get pinCurrent;

  /// No description provided for @pinNew.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um PIN'**
  String get pinNew;

  /// No description provided for @pinRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Repita o PIN'**
  String get pinRepeat;

  /// No description provided for @pinRule.
  ///
  /// In pt, this message translates to:
  /// **'De 4 a 8 dígitos'**
  String get pinRule;

  /// No description provided for @tabMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa'**
  String get tabMap;

  /// No description provided for @mapAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get mapAll;

  /// No description provided for @mapUnknownBuild.
  ///
  /// In pt, this message translates to:
  /// **'Build de referência desconhecido: cada cromossomo é desenhado até a maior posição encontrada, sem centrômero.'**
  String get mapUnknownBuild;

  /// No description provided for @mapFew.
  ///
  /// In pt, this message translates to:
  /// **'poucas'**
  String get mapFew;

  /// No description provided for @mapMany.
  ///
  /// In pt, this message translates to:
  /// **'muitas'**
  String get mapMany;

  /// No description provided for @mapCentromere.
  ///
  /// In pt, this message translates to:
  /// **'centrômero (posição aproximada)'**
  String get mapCentromere;

  /// No description provided for @mapChromSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Cromossomo {chrom}: {count} variantes. Toque para ver a região.'**
  String mapChromSemantics(String chrom, int count);

  /// No description provided for @regionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cromossomo {chrom}'**
  String regionTitle(String chrom);

  /// No description provided for @regionField.
  ///
  /// In pt, this message translates to:
  /// **'Região (ex.: 1:1.000.000-2.000.000)'**
  String get regionField;

  /// No description provided for @regionZoomIn.
  ///
  /// In pt, this message translates to:
  /// **'Aproximar'**
  String get regionZoomIn;

  /// No description provided for @regionZoomOut.
  ///
  /// In pt, this message translates to:
  /// **'Afastar'**
  String get regionZoomOut;

  /// No description provided for @regionTrackSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Trilha da região {region} com {count} variantes. Toque duas vezes para aproximar; arraste para os lados para mover.'**
  String regionTrackSemantics(String region, int count);

  /// No description provided for @regionLoading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando…'**
  String get regionLoading;

  /// No description provided for @regionShowing.
  ///
  /// In pt, this message translates to:
  /// **'Mostrando {shown} de {total} variantes — aproxime para ver todas.'**
  String regionShowing(int shown, int total);

  /// No description provided for @regionCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} variantes neste trecho'**
  String regionCount(int count);

  /// No description provided for @regionNoVariants.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma variante neste trecho.'**
  String get regionNoVariants;

  /// No description provided for @vennTitle.
  ///
  /// In pt, this message translates to:
  /// **'Interseções'**
  String get vennTitle;

  /// No description provided for @vennSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Diagrama de interseções: {onlyA} variantes só em {a}, {both} nos dois ({diff} com genótipo diferente), {onlyB} só em {b}.'**
  String vennSemantics(
    String a,
    String b,
    int onlyA,
    int both,
    int diff,
    int onlyB,
  );

  /// No description provided for @vennOnly.
  ///
  /// In pt, this message translates to:
  /// **'só em {name}'**
  String vennOnly(String name);

  /// No description provided for @vennBoth.
  ///
  /// In pt, this message translates to:
  /// **'nos dois'**
  String get vennBoth;

  /// No description provided for @vennBreakdown.
  ///
  /// In pt, this message translates to:
  /// **'{same} iguais · {diff} genótipo diferente'**
  String vennBreakdown(int same, int diff);

  /// No description provided for @vennOutside.
  ///
  /// In pt, this message translates to:
  /// **'Fora do diagrama: {missing} ausentes/incertas e {notAssessed} não avaliadas.'**
  String vennOutside(int missing, int notAssessed);

  /// No description provided for @vennNotProportional.
  ///
  /// In pt, this message translates to:
  /// **'Os círculos não estão em escala: os números indicam as quantidades.'**
  String get vennNotProportional;

  /// No description provided for @learnTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aprender'**
  String get learnTitle;

  /// No description provided for @learnIntro.
  ///
  /// In pt, this message translates to:
  /// **'Trilhas guiadas com dados fictícios: comparar amostras, ler genótipos e explorar o mapa do genoma. Tudo roda no aparelho. Para ensino — não é diagnóstico.'**
  String get learnIntro;

  /// No description provided for @learnProgress.
  ///
  /// In pt, this message translates to:
  /// **'{correct} de {total} exercícios certos'**
  String learnProgress(int correct, int total);

  /// No description provided for @glossaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Glossário'**
  String get glossaryTitle;

  /// No description provided for @glossarySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count} termos, em português e inglês'**
  String glossarySubtitle(int count);

  /// No description provided for @glossarySearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar termo'**
  String get glossarySearch;

  /// No description provided for @glossaryNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum termo encontrado.'**
  String get glossaryNone;

  /// No description provided for @packageImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar pacote de aula'**
  String get packageImport;

  /// No description provided for @packageImportHint.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo .genozaula recebido do professor'**
  String get packageImportHint;

  /// No description provided for @packageImporting.
  ///
  /// In pt, this message translates to:
  /// **'Importando a aula: conferindo arquivos e comparando…'**
  String get packageImporting;

  /// No description provided for @packageProjectDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aula importada de um pacote de professor.'**
  String get packageProjectDescription;

  /// No description provided for @packageImported.
  ///
  /// In pt, this message translates to:
  /// **'Aula \"{title}\" importada.'**
  String packageImported(String title);

  /// No description provided for @packageError.
  ///
  /// In pt, this message translates to:
  /// **'{code, select, notPackage{Este arquivo não é um pacote de aula do Genoz.} newerVersion{Este pacote foi feito por uma versão mais nova do Genoz. Atualize o app.} missingFile{O pacote está incompleto (falta um arquivo).} corrupted{Um arquivo do pacote está corrompido (SHA-256 não confere). Nada foi importado.} tooLarge{O pacote é grande demais para este aparelho.} other{Não foi possível importar o pacote.}}'**
  String packageError(String code);

  /// No description provided for @learnProjectName.
  ///
  /// In pt, this message translates to:
  /// **'Aula: {title}'**
  String learnProjectName(String title);

  /// No description provided for @learnProjectDescription.
  ///
  /// In pt, this message translates to:
  /// **'Dados fictícios do modo estudante.'**
  String get learnProjectDescription;

  /// No description provided for @learnDataset.
  ///
  /// In pt, this message translates to:
  /// **'Dados: {title}'**
  String learnDataset(String title);

  /// No description provided for @learnOpenTab.
  ///
  /// In pt, this message translates to:
  /// **'Abrir {tab}'**
  String learnOpenTab(String tab);

  /// No description provided for @learnExercises.
  ///
  /// In pt, this message translates to:
  /// **'Exercícios'**
  String get learnExercises;

  /// No description provided for @learnPrepare.
  ///
  /// In pt, this message translates to:
  /// **'Preparar os dados da aula'**
  String get learnPrepare;

  /// No description provided for @exerciseCorrect.
  ///
  /// In pt, this message translates to:
  /// **'Respondido corretamente'**
  String get exerciseCorrect;

  /// No description provided for @exerciseCheck.
  ///
  /// In pt, this message translates to:
  /// **'Conferir'**
  String get exerciseCheck;

  /// No description provided for @exerciseReveal.
  ///
  /// In pt, this message translates to:
  /// **'Ver resposta'**
  String get exerciseReveal;

  /// No description provided for @exerciseUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não dá para calcular esta resposta com estes dados.'**
  String get exerciseUnavailable;

  /// No description provided for @exerciseRight.
  ///
  /// In pt, this message translates to:
  /// **'Certo!'**
  String get exerciseRight;

  /// No description provided for @exerciseWrong.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não.'**
  String get exerciseWrong;

  /// No description provided for @exerciseAnswer.
  ///
  /// In pt, this message translates to:
  /// **'Resposta: {answer}'**
  String exerciseAnswer(String answer);

  /// No description provided for @packageCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar pacote de aula'**
  String get packageCreateTitle;

  /// No description provided for @packageCreateIntro.
  ///
  /// In pt, this message translates to:
  /// **'Transforma esta comparação num arquivo .genozaula para os alunos. Eles importam em Aprender e recebem os mesmos arquivos, a comparação pronta e as perguntas.'**
  String get packageCreateIntro;

  /// No description provided for @packageTitleField.
  ///
  /// In pt, this message translates to:
  /// **'Título da aula'**
  String get packageTitleField;

  /// No description provided for @packageInstructionsField.
  ///
  /// In pt, this message translates to:
  /// **'Instruções para os alunos (opcional)'**
  String get packageInstructionsField;

  /// No description provided for @packageQuestions.
  ///
  /// In pt, this message translates to:
  /// **'Perguntas (corrigidas automaticamente)'**
  String get packageQuestions;

  /// No description provided for @packagePrivacyNote.
  ///
  /// In pt, this message translates to:
  /// **'O pacote leva cópias dos arquivos VCF desta comparação. Use só dados fictícios ou com autorização. As respostas não vão no pacote: são calculadas no aparelho de cada aluno.'**
  String get packagePrivacyNote;

  /// No description provided for @packageSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar pacote'**
  String get packageSave;

  /// No description provided for @packageSaved.
  ///
  /// In pt, this message translates to:
  /// **'Pacote de aula salvo.'**
  String get packageSaved;

  /// No description provided for @exerciseHint.
  ///
  /// In pt, this message translates to:
  /// **'Sua resposta'**
  String get exerciseHint;

  /// No description provided for @packageOpenStep.
  ///
  /// In pt, this message translates to:
  /// **'Abra a comparação da aula: as respostas estão no Resumo, na Tabela e no Mapa.'**
  String get packageOpenStep;

  /// No description provided for @chipModeHint.
  ///
  /// In pt, this message translates to:
  /// **'A é um arquivo de chip: a comparação fica restrita aos sítios que o chip avalia. B precisa ser um VCF.'**
  String get chipModeHint;

  /// No description provided for @referenceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Referência (FASTA)'**
  String get referenceTitle;

  /// No description provided for @referenceHintChip.
  ///
  /// In pt, this message translates to:
  /// **'Opcional. Com a referência, sítios homozigotos do chip sem registro no VCF também podem ser julgados.'**
  String get referenceHintChip;

  /// No description provided for @referenceHintVcf.
  ///
  /// In pt, this message translates to:
  /// **'Opcional. Alinha os indels à esquerda antes de comparar e confere o REF de cada variante (usa mais memória).'**
  String get referenceHintVcf;

  /// No description provided for @referenceNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem referência'**
  String get referenceNone;

  /// No description provided for @kindChip.
  ///
  /// In pt, this message translates to:
  /// **'chip {vendor}'**
  String kindChip(String vendor);

  /// No description provided for @kindFasta.
  ///
  /// In pt, this message translates to:
  /// **'FASTA de referência'**
  String get kindFasta;

  /// No description provided for @sitesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} sítios'**
  String sitesCount(int count);

  /// No description provided for @sequencesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} sequências'**
  String sequencesCount(int count);

  /// No description provided for @sectionChip.
  ///
  /// In pt, this message translates to:
  /// **'Chip de consumidor'**
  String get sectionChip;

  /// No description provided for @chipVendor.
  ///
  /// In pt, this message translates to:
  /// **'Empresa'**
  String get chipVendor;

  /// No description provided for @chipSites.
  ///
  /// In pt, this message translates to:
  /// **'Sítios no chip'**
  String get chipSites;

  /// No description provided for @chipCalled.
  ///
  /// In pt, this message translates to:
  /// **'Com genótipo'**
  String get chipCalled;

  /// No description provided for @chipNoCalls.
  ///
  /// In pt, this message translates to:
  /// **'Sem chamada (--)'**
  String get chipNoCalls;

  /// No description provided for @chipHet.
  ///
  /// In pt, this message translates to:
  /// **'Heterozigotos'**
  String get chipHet;

  /// No description provided for @chipHom.
  ///
  /// In pt, this message translates to:
  /// **'Homozigotos'**
  String get chipHom;

  /// No description provided for @chipHaploid.
  ///
  /// In pt, this message translates to:
  /// **'Haploides (X/Y/MT)'**
  String get chipHaploid;

  /// No description provided for @chipIndels.
  ///
  /// In pt, this message translates to:
  /// **'Indels ignorados'**
  String get chipIndels;

  /// No description provided for @chipNote.
  ///
  /// In pt, this message translates to:
  /// **'Chips medem só posições escolhidas pelo fabricante e não informam a base de referência. Na comparação com um VCF os genótipos são comparados letra a letra, só nesses sítios.'**
  String get chipNote;

  /// No description provided for @sectionFasta.
  ///
  /// In pt, this message translates to:
  /// **'Referência (FASTA)'**
  String get sectionFasta;

  /// No description provided for @fastaSequences.
  ///
  /// In pt, this message translates to:
  /// **'Sequências'**
  String get fastaSequences;

  /// No description provided for @fastaTotalBases.
  ///
  /// In pt, this message translates to:
  /// **'Bases no total'**
  String get fastaTotalBases;

  /// No description provided for @fastaNote.
  ///
  /// In pt, this message translates to:
  /// **'Usado para alinhar indels à esquerda e para julgar sítios do chip sem registro no VCF. Fica só neste aparelho.'**
  String get fastaNote;

  /// No description provided for @chipCompareTitle.
  ///
  /// In pt, this message translates to:
  /// **'Chip {vendor} × sequenciamento'**
  String chipCompareTitle(String vendor);

  /// No description provided for @chipCompareRestricted.
  ///
  /// In pt, this message translates to:
  /// **'Só os sítios que o chip avalia. Variantes do VCF fora do chip não entram na conta (ver abaixo).'**
  String get chipCompareRestricted;

  /// No description provided for @chipCompareNonref.
  ///
  /// In pt, this message translates to:
  /// **'Concordância sem os sítios referência × referência'**
  String get chipCompareNonref;

  /// No description provided for @chipCompareOffChip.
  ///
  /// In pt, this message translates to:
  /// **'Variantes do VCF fora do chip'**
  String get chipCompareOffChip;

  /// No description provided for @chipCompareUnknownRef.
  ///
  /// In pt, this message translates to:
  /// **'Homozigotos do chip sem registro no VCF (referência desconhecida)'**
  String get chipCompareUnknownRef;

  /// No description provided for @chipCompareRefNotAssessed.
  ///
  /// In pt, this message translates to:
  /// **'Homozigotos de referência sem registro no VCF'**
  String get chipCompareRefNotAssessed;

  /// No description provided for @chipCompareStrandFlips.
  ///
  /// In pt, this message translates to:
  /// **'Diferenças que parecem troca de fita'**
  String get chipCompareStrandFlips;

  /// No description provided for @zipError.
  ///
  /// In pt, this message translates to:
  /// **'{code, select, invalid{Não foi possível abrir o .zip.} empty{O .zip não tem um arquivo de dados (.txt, .csv, .vcf).} many{O .zip tem mais de um arquivo de dados; extraia e importe o que quiser.} tooLarge{O arquivo dentro do .zip é grande demais.} other{Não foi possível importar o .zip.}}'**
  String zipError(String code);

  /// No description provided for @annotTitle.
  ///
  /// In pt, this message translates to:
  /// **'Anotações'**
  String get annotTitle;

  /// No description provided for @annotIntro.
  ///
  /// In pt, this message translates to:
  /// **'Anotação acrescenta o que fontes públicas dizem sobre cada variante e região: genes (GENCODE) e o ClinVar. Tudo é consultado no aparelho. O Genoz não classifica variantes: só mostra o que cada fonte diz, com versão e data.'**
  String get annotIntro;

  /// No description provided for @annotNoInternet.
  ///
  /// In pt, this message translates to:
  /// **'O Genoz não tem acesso à internet. Para um pacote do catálogo, baixe o arquivo oficial pelo seu navegador e importe aqui: o app só aceita se a impressão digital (SHA-256) for exatamente a do catálogo.'**
  String get annotNoInternet;

  /// No description provided for @annotInstalled.
  ///
  /// In pt, this message translates to:
  /// **'Instalados'**
  String get annotInstalled;

  /// No description provided for @annotCatalog.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo (baixar pelo navegador)'**
  String get annotCatalog;

  /// No description provided for @annotCustom.
  ///
  /// In pt, this message translates to:
  /// **'Pacote próprio'**
  String get annotCustom;

  /// No description provided for @annotCustomImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar BED ou TSV'**
  String get annotCustomImport;

  /// No description provided for @annotCustomHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: a lista de genes de uma disciplina. BED (0-based) ou TSV com colunas chrom, start, end, nome…'**
  String get annotCustomHint;

  /// No description provided for @annotCustomName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do pacote'**
  String get annotCustomName;

  /// No description provided for @annotChooseFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher arquivo'**
  String get annotChooseFile;

  /// No description provided for @annotBuilding.
  ///
  /// In pt, this message translates to:
  /// **'Montando o pacote…'**
  String get annotBuilding;

  /// No description provided for @annotChecking.
  ///
  /// In pt, this message translates to:
  /// **'Conferindo o SHA-256 e montando o pacote. Arquivos grandes (ClinVar) podem levar alguns minutos.'**
  String get annotChecking;

  /// No description provided for @annotInstalledOk.
  ///
  /// In pt, this message translates to:
  /// **'Pacote \"{name}\" instalado ({records} registros).'**
  String annotInstalledOk(String name, int records);

  /// No description provided for @annotHashMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo não é o do catálogo (SHA-256 diferente). Nada foi instalado. Confira se baixou o arquivo do link indicado e se o download terminou.'**
  String get annotHashMismatch;

  /// No description provided for @annotBuildFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível montar o pacote: {detail}'**
  String annotBuildFailed(String detail);

  /// No description provided for @annotRecords.
  ///
  /// In pt, this message translates to:
  /// **'{count} registros'**
  String annotRecords(String count);

  /// No description provided for @annotEmbedded.
  ///
  /// In pt, this message translates to:
  /// **'embutido'**
  String get annotEmbedded;

  /// No description provided for @annotVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get annotVersion;

  /// No description provided for @annotLicense.
  ///
  /// In pt, this message translates to:
  /// **'Licença'**
  String get annotLicense;

  /// No description provided for @annotCitation.
  ///
  /// In pt, this message translates to:
  /// **'Como citar'**
  String get annotCitation;

  /// No description provided for @annotSourceUrl.
  ///
  /// In pt, this message translates to:
  /// **'Origem'**
  String get annotSourceUrl;

  /// No description provided for @annotHowTo.
  ///
  /// In pt, this message translates to:
  /// **'1. Baixe o arquivo pelo navegador. 2. Importe o arquivo baixado aqui. O app confere o SHA-256 antes de usar.'**
  String get annotHowTo;

  /// No description provided for @annotOpenBrowser.
  ///
  /// In pt, this message translates to:
  /// **'Baixar no navegador'**
  String get annotOpenBrowser;

  /// No description provided for @annotCopyUrl.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link'**
  String get annotCopyUrl;

  /// No description provided for @annotUrlCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado.'**
  String get annotUrlCopied;

  /// No description provided for @annotImportDownloaded.
  ///
  /// In pt, this message translates to:
  /// **'Importar arquivo baixado'**
  String get annotImportDownloaded;

  /// No description provided for @sourcesTitle.
  ///
  /// In pt, this message translates to:
  /// **'O que as fontes dizem'**
  String get sourcesTitle;

  /// No description provided for @sourcesSays.
  ///
  /// In pt, this message translates to:
  /// **'{source} · versão {version} ({date})'**
  String sourcesSays(String source, String version, String date);

  /// No description provided for @sourcesMore.
  ///
  /// In pt, this message translates to:
  /// **'… e mais {count}'**
  String sourcesMore(int count);

  /// No description provided for @sourcesNoClassification.
  ///
  /// In pt, this message translates to:
  /// **'O Genoz não classifica variantes: os textos acima são da fonte indicada, na versão indicada.'**
  String get sourcesNoClassification;

  /// No description provided for @geneFound.
  ///
  /// In pt, this message translates to:
  /// **'{gene}: {region}'**
  String geneFound(String gene, String region);

  /// No description provided for @clinvarLicense.
  ///
  /// In pt, this message translates to:
  /// **'Uso e redistribuição livres com atribuição ao ClinVar'**
  String get clinvarLicense;

  /// No description provided for @clinvarDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'O ClinVar não é para uso diagnóstico direto nem decisão médica sem revisão de um profissional de genética; o NIH não verifica as informações enviadas.'**
  String get clinvarDisclaimer;

  /// No description provided for @gencodeLicense.
  ///
  /// In pt, this message translates to:
  /// **'Acesso aberto (EMBL-EBI: sem restrições adicionais; atribuição esperada)'**
  String get gencodeLicense;

  /// No description provided for @vaultExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar projeto (.genoz)'**
  String get vaultExport;

  /// No description provided for @vaultProtect.
  ///
  /// In pt, this message translates to:
  /// **'Proteger com senha'**
  String get vaultProtect;

  /// No description provided for @vaultImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar projeto (.genoz)'**
  String get vaultImport;

  /// No description provided for @vaultLocked.
  ///
  /// In pt, this message translates to:
  /// **'Protegido com senha'**
  String get vaultLocked;

  /// No description provided for @vaultOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir com a senha'**
  String get vaultOpen;

  /// No description provided for @vaultLockedBody.
  ///
  /// In pt, this message translates to:
  /// **'Os dados deste projeto estão cifrados neste aparelho. Digite a senha para abri-lo.'**
  String get vaultLockedBody;

  /// No description provided for @vaultNewPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar senha'**
  String get vaultNewPasswordTitle;

  /// No description provided for @vaultPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get vaultPassword;

  /// No description provided for @vaultPasswordRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Repita a senha'**
  String get vaultPasswordRepeat;

  /// No description provided for @vaultPasswordShort.
  ///
  /// In pt, this message translates to:
  /// **'Use pelo menos {min} caracteres.'**
  String vaultPasswordShort(int min);

  /// No description provided for @vaultPasswordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não são iguais.'**
  String get vaultPasswordMismatch;

  /// No description provided for @vaultLossWarning.
  ///
  /// In pt, this message translates to:
  /// **'Se você esquecer a senha, os dados não podem ser recuperados — por ninguém, nem pelo Genoz. Anote-a num lugar seguro.'**
  String get vaultLossWarning;

  /// No description provided for @vaultLossAccept.
  ///
  /// In pt, this message translates to:
  /// **'Entendi: senha perdida = dados perdidos'**
  String get vaultLossAccept;

  /// No description provided for @vaultProtectBody.
  ///
  /// In pt, this message translates to:
  /// **'O projeto será cifrado neste aparelho (Argon2id + XChaCha20-Poly1305) e a cópia em claro, apagada. Para usá-lo de novo, abra com a senha.'**
  String get vaultProtectBody;

  /// No description provided for @vaultExportBody.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo .genoz sai cifrado com esta senha. Leve-o a outro aparelho (cabo, pendrive, Bluetooth...) e importe-o lá com a mesma senha. Nada é enviado para a internet.'**
  String get vaultExportBody;

  /// No description provided for @vaultExportLockedBody.
  ///
  /// In pt, this message translates to:
  /// **'Este projeto já está cifrado: o arquivo .genoz usa a mesma senha dele.'**
  String get vaultExportLockedBody;

  /// No description provided for @vaultSealing.
  ///
  /// In pt, this message translates to:
  /// **'Cifrando o projeto…'**
  String get vaultSealing;

  /// No description provided for @vaultOpening.
  ///
  /// In pt, this message translates to:
  /// **'Conferindo a senha e decifrando…'**
  String get vaultOpening;

  /// No description provided for @vaultWrongPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha incorreta — ou o arquivo foi alterado ou está incompleto.'**
  String get vaultWrongPassword;

  /// No description provided for @vaultNotGenoz.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo não é um projeto .genoz do Genoz.'**
  String get vaultNotGenoz;

  /// No description provided for @vaultNewerVersion.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo é de uma versão mais nova do Genoz. Atualize o app.'**
  String get vaultNewerVersion;

  /// No description provided for @vaultExported.
  ///
  /// In pt, this message translates to:
  /// **'Projeto exportado.'**
  String get vaultExported;

  /// No description provided for @vaultProtected.
  ///
  /// In pt, this message translates to:
  /// **'Projeto protegido com senha.'**
  String get vaultProtected;

  /// No description provided for @vaultImported.
  ///
  /// In pt, this message translates to:
  /// **'Projeto \"{name}\" importado.'**
  String vaultImported(String name);

  /// No description provided for @vaultOpened.
  ///
  /// In pt, this message translates to:
  /// **'Projeto aberto. Para cifrar de novo, use \"Proteger com senha\".'**
  String get vaultOpened;

  /// No description provided for @vaultFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir: {detail}'**
  String vaultFailed(String detail);

  /// No description provided for @logVaultImported.
  ///
  /// In pt, this message translates to:
  /// **'Projeto importado de um arquivo .genoz'**
  String get logVaultImported;

  /// No description provided for @logVaultOpened.
  ///
  /// In pt, this message translates to:
  /// **'Projeto aberto com a senha'**
  String get logVaultOpened;

  /// No description provided for @logVaultExported.
  ///
  /// In pt, this message translates to:
  /// **'Projeto exportado (.genoz, cifrado)'**
  String get logVaultExported;

  /// No description provided for @reportSection.
  ///
  /// In pt, this message translates to:
  /// **'Relatório'**
  String get reportSection;

  /// No description provided for @reportHtml.
  ///
  /// In pt, this message translates to:
  /// **'Relatório HTML (abre em qualquer navegador)'**
  String get reportHtml;

  /// No description provided for @reportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Relatório PDF'**
  String get reportPdf;

  /// No description provided for @reportSaved.
  ///
  /// In pt, this message translates to:
  /// **'Relatório salvo.'**
  String get reportSaved;

  /// No description provided for @logReport.
  ///
  /// In pt, this message translates to:
  /// **'Relatório {format} gerado'**
  String logReport(String format);

  /// No description provided for @reproVerify.
  ///
  /// In pt, this message translates to:
  /// **'Verificar reprodutibilidade'**
  String get reproVerify;

  /// No description provided for @reproRunning.
  ///
  /// In pt, this message translates to:
  /// **'Conferindo as entradas e refazendo a análise…'**
  String get reproRunning;

  /// No description provided for @reproTitle.
  ///
  /// In pt, this message translates to:
  /// **'Reprodutibilidade'**
  String get reproTitle;

  /// No description provided for @reproOk.
  ///
  /// In pt, this message translates to:
  /// **'Reproduzida: mesmo ID e {total} de {total} saídas idênticas (SHA-256).'**
  String reproOk(int total);

  /// No description provided for @reproPartial.
  ///
  /// In pt, this message translates to:
  /// **'{ok} de {total} saídas idênticas.'**
  String reproPartial(int ok, int total);

  /// No description provided for @reproInputs.
  ///
  /// In pt, this message translates to:
  /// **'Entradas'**
  String get reproInputs;

  /// No description provided for @reproOutputs.
  ///
  /// In pt, this message translates to:
  /// **'Saídas'**
  String get reproOutputs;

  /// No description provided for @reproInputOk.
  ///
  /// In pt, this message translates to:
  /// **'SHA-256 confere'**
  String get reproInputOk;

  /// No description provided for @reproInputMissing.
  ///
  /// In pt, this message translates to:
  /// **'não está mais no projeto'**
  String get reproInputMissing;

  /// No description provided for @reproInputChanged.
  ///
  /// In pt, this message translates to:
  /// **'SHA-256 diferente (arquivo alterado)'**
  String get reproInputChanged;

  /// No description provided for @reproInputUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'regiões avaliadas (BED): reexecute pela linha de comando'**
  String get reproInputUnsupported;

  /// No description provided for @reproIdDiffers.
  ///
  /// In pt, this message translates to:
  /// **'O ID da reexecução é diferente do original.'**
  String get reproIdDiffers;

  /// No description provided for @reproNotRun.
  ///
  /// In pt, this message translates to:
  /// **'As entradas não conferem: a reexecução não provaria nada.'**
  String get reproNotRun;

  /// No description provided for @reproFailed.
  ///
  /// In pt, this message translates to:
  /// **'A reexecução falhou: {detail}'**
  String reproFailed(String detail);

  /// No description provided for @reproIdentical.
  ///
  /// In pt, this message translates to:
  /// **'idêntica'**
  String get reproIdentical;

  /// No description provided for @reproDifferent.
  ///
  /// In pt, this message translates to:
  /// **'diferente'**
  String get reproDifferent;

  /// No description provided for @reproMissing.
  ///
  /// In pt, this message translates to:
  /// **'ausente'**
  String get reproMissing;

  /// No description provided for @reproExplain.
  ///
  /// In pt, this message translates to:
  /// **'A análise foi refeita numa pasta temporária com os mesmos arquivos e parâmetros, e cada saída comparada pelo SHA-256 com o manifesto. A análise salva não muda.'**
  String get reproExplain;

  /// No description provided for @logRepro.
  ///
  /// In pt, this message translates to:
  /// **'Reprodutibilidade verificada: {result}'**
  String logRepro(String result);

  /// No description provided for @familyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Família e populações'**
  String get familyTitle;

  /// No description provided for @familyIntro.
  ///
  /// In pt, this message translates to:
  /// **'Parentesco, trechos de homozigose e herança num trio, a partir de um VCF com várias pessoas chamadas juntas (chamada conjunta).'**
  String get familyIntro;

  /// No description provided for @familyNeedsJoint.
  ///
  /// In pt, this message translates to:
  /// **'Para VCFs de uma pessoa só, use Comparar A × B: neles, ausência não é referência, e o parentesco sairia errado.'**
  String get familyNeedsJoint;

  /// No description provided for @familyNoMultiSample.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum VCF deste projeto tem 2 ou mais amostras.'**
  String get familyNoMultiSample;

  /// No description provided for @familyFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get familyFile;

  /// No description provided for @familySamples.
  ///
  /// In pt, this message translates to:
  /// **'Amostras ({count} de no máximo {max})'**
  String familySamples(int count, int max);

  /// No description provided for @familyTooMany.
  ///
  /// In pt, this message translates to:
  /// **'Escolha de 2 a {max} amostras.'**
  String familyTooMany(int max);

  /// No description provided for @familyTrioOptional.
  ///
  /// In pt, this message translates to:
  /// **'Trio (opcional)'**
  String get familyTrioOptional;

  /// No description provided for @familyChild.
  ///
  /// In pt, this message translates to:
  /// **'Filho(a)'**
  String get familyChild;

  /// No description provided for @familyFather.
  ///
  /// In pt, this message translates to:
  /// **'Pai'**
  String get familyFather;

  /// No description provided for @familyMother.
  ///
  /// In pt, this message translates to:
  /// **'Mãe'**
  String get familyMother;

  /// No description provided for @familyTrioDistinct.
  ///
  /// In pt, this message translates to:
  /// **'Filho(a), pai e mãe precisam ser pessoas diferentes.'**
  String get familyTrioDistinct;

  /// No description provided for @familyRun.
  ///
  /// In pt, this message translates to:
  /// **'Analisar'**
  String get familyRun;

  /// No description provided for @familyRunning.
  ///
  /// In pt, this message translates to:
  /// **'Analisando a família…'**
  String get familyRunning;

  /// No description provided for @familyDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa estatística, sujeita a erro. Não é teste de paternidade com valor legal nem diagnóstico.'**
  String get familyDisclaimer;

  /// No description provided for @familyTabKinship.
  ///
  /// In pt, this message translates to:
  /// **'Parentesco'**
  String get familyTabKinship;

  /// No description provided for @familyTabRoh.
  ///
  /// In pt, this message translates to:
  /// **'ROH'**
  String get familyTabRoh;

  /// No description provided for @familyTabTrio.
  ///
  /// In pt, this message translates to:
  /// **'Trio'**
  String get familyTabTrio;

  /// No description provided for @familyTabShared.
  ///
  /// In pt, this message translates to:
  /// **'Interseções'**
  String get familyTabShared;

  /// No description provided for @familySitesUsed.
  ///
  /// In pt, this message translates to:
  /// **'{count} SNVs autossômicos usados'**
  String familySitesUsed(String count);

  /// No description provided for @relDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Mesma pessoa ou gêmeos idênticos'**
  String get relDuplicate;

  /// No description provided for @relParentOffspring.
  ///
  /// In pt, this message translates to:
  /// **'Pai/mãe e filho(a)'**
  String get relParentOffspring;

  /// No description provided for @relFullSiblings.
  ///
  /// In pt, this message translates to:
  /// **'Irmãos'**
  String get relFullSiblings;

  /// No description provided for @relFirstDegree.
  ///
  /// In pt, this message translates to:
  /// **'1º grau (pai/mãe–filho ou irmãos)'**
  String get relFirstDegree;

  /// No description provided for @relSecondDegree.
  ///
  /// In pt, this message translates to:
  /// **'2º grau (avós, tios, meio-irmãos)'**
  String get relSecondDegree;

  /// No description provided for @relThirdDegree.
  ///
  /// In pt, this message translates to:
  /// **'3º grau (ex.: primos de 1º grau)'**
  String get relThirdDegree;

  /// No description provided for @relUnrelated.
  ///
  /// In pt, this message translates to:
  /// **'Sem parentesco próximo'**
  String get relUnrelated;

  /// No description provided for @relInsufficient.
  ///
  /// In pt, this message translates to:
  /// **'Dados insuficientes'**
  String get relInsufficient;

  /// No description provided for @kinshipLabel.
  ///
  /// In pt, this message translates to:
  /// **'φ (parentesco)'**
  String get kinshipLabel;

  /// No description provided for @ibs0Label.
  ///
  /// In pt, this message translates to:
  /// **'IBS0'**
  String get ibs0Label;

  /// No description provided for @pairSites.
  ///
  /// In pt, this message translates to:
  /// **'SNPs comparados'**
  String get pairSites;

  /// No description provided for @concordanceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Concordância de genótipos'**
  String get concordanceLabel;

  /// No description provided for @kinshipExplain.
  ///
  /// In pt, this message translates to:
  /// **'φ é a chance de um alelo sorteado de cada pessoa ser idêntico por descendência: ≈ 0,5 mesma pessoa; ≈ 0,25 pai/mãe–filho e irmãos; ≈ 0,125 2º grau; ≈ 0,0625 3º grau; ≈ 0 sem parentesco (valores negativos aparecem com consanguinidade ou populações diferentes). IBS0 conta os SNPs em que as duas pessoas são homozigotas opostas: perto de zero em pai/mãe–filho. Método KING-robust (Manichaikul et al., 2010).'**
  String get kinshipExplain;

  /// No description provided for @familyMatrix.
  ///
  /// In pt, this message translates to:
  /// **'Matriz de parentesco'**
  String get familyMatrix;

  /// No description provided for @familyPairs.
  ///
  /// In pt, this message translates to:
  /// **'Pares'**
  String get familyPairs;

  /// No description provided for @rohIntro.
  ///
  /// In pt, this message translates to:
  /// **'Runs of homozygosity (ROH) são trechos longos em que as duas cópias do genoma são iguais. Aparecem quando os pais têm ancestrais em comum, próximos ou distantes, e ajudam a estudar a história das populações. Conteúdo educativo, não clínico.'**
  String get rohIntro;

  /// No description provided for @rohSummary.
  ///
  /// In pt, this message translates to:
  /// **'{runs} trechos · {mb} Mb · F_ROH {froh}'**
  String rohSummary(int runs, String mb, String froh);

  /// No description provided for @rohNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum trecho longo de homozigose.'**
  String get rohNone;

  /// No description provided for @rohUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'O VCF não está ordenado por posição: ROH não foi calculado.'**
  String get rohUnavailable;

  /// No description provided for @rohMethod.
  ///
  /// In pt, this message translates to:
  /// **'Trechos de ≥ 1000 kb com ≥ 100 SNPs, até 1 heterozigoto e 5 ausentes (inspirado no plink --homozyg). Com poucas pessoas no VCF há menos SNPs por trecho.'**
  String get rohMethod;

  /// No description provided for @trioRoles.
  ///
  /// In pt, this message translates to:
  /// **'Filho(a): {child} · Pai: {father} · Mãe: {mother}'**
  String trioRoles(String child, String father, String mother);

  /// No description provided for @trioSites.
  ///
  /// In pt, this message translates to:
  /// **'{count} sítios com os três genotipados'**
  String trioSites(String count);

  /// No description provided for @trioConsistent.
  ///
  /// In pt, this message translates to:
  /// **'Consistentes com herança mendeliana'**
  String get trioConsistent;

  /// No description provided for @trioDeNovo.
  ///
  /// In pt, this message translates to:
  /// **'Candidatas a de novo'**
  String get trioDeNovo;

  /// No description provided for @trioOtherErrors.
  ///
  /// In pt, this message translates to:
  /// **'Outros erros mendelianos'**
  String get trioOtherErrors;

  /// No description provided for @trioErrorRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de inconsistência'**
  String get trioErrorRate;

  /// No description provided for @trioInherited.
  ///
  /// In pt, this message translates to:
  /// **'Alelo alternativo do(a) filho(a) heterozigoto(a), quando dá para saber de quem veio'**
  String get trioInherited;

  /// No description provided for @trioPaternal.
  ///
  /// In pt, this message translates to:
  /// **'do pai'**
  String get trioPaternal;

  /// No description provided for @trioMaternal.
  ///
  /// In pt, this message translates to:
  /// **'da mãe'**
  String get trioMaternal;

  /// No description provided for @trioDeNovoExplain.
  ///
  /// In pt, this message translates to:
  /// **'Candidata a de novo: o(a) filho(a) tem uma variante que nenhum dos pais tem. Em dados reais, a maioria é erro de chamada ou de cobertura — confira QUAL, DP e GQ antes de qualquer conclusão. Uma taxa alta de inconsistência pode indicar troca de amostra ou pais biológicos diferentes dos indicados; só um teste oficial confirma.'**
  String get trioDeNovoExplain;

  /// No description provided for @trioEvents.
  ///
  /// In pt, this message translates to:
  /// **'Eventos'**
  String get trioEvents;

  /// No description provided for @trioTruncated.
  ///
  /// In pt, this message translates to:
  /// **'Mostrando os primeiros {max} eventos (as contagens acima são completas).'**
  String trioTruncated(int max);

  /// No description provided for @trioNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum trio foi indicado nesta análise.'**
  String get trioNone;

  /// No description provided for @trioGenotypes.
  ///
  /// In pt, this message translates to:
  /// **'filho(a) {child} · pai {father} · mãe {mother}'**
  String trioGenotypes(String child, String father, String mother);

  /// No description provided for @sharedIntro.
  ///
  /// In pt, this message translates to:
  /// **'Quais amostras carregam o alelo alternativo de cada variante: as combinações mais frequentes (estilo UpSet).'**
  String get sharedIntro;

  /// No description provided for @sharedCarriers.
  ///
  /// In pt, this message translates to:
  /// **'Variantes por amostra'**
  String get sharedCarriers;

  /// No description provided for @sharedCombos.
  ///
  /// In pt, this message translates to:
  /// **'Combinações mais frequentes'**
  String get sharedCombos;

  /// No description provided for @familyListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Família: {count} amostras'**
  String familyListTitle(int count);

  /// No description provided for @familyListTrio.
  ///
  /// In pt, this message translates to:
  /// **'com trio'**
  String get familyListTrio;

  /// No description provided for @familySynthetic.
  ///
  /// In pt, this message translates to:
  /// **'Gerar família fictícia'**
  String get familySynthetic;

  /// No description provided for @familySyntheticHint.
  ///
  /// In pt, this message translates to:
  /// **'VCF com 7 pessoas fictícias (avô, pai, mãe, dois filhos, uma pessoa sem parentesco e uma duplicata) para experimentar Família e populações.'**
  String get familySyntheticHint;

  /// No description provided for @logFamily.
  ///
  /// In pt, this message translates to:
  /// **'Família e populações: {count} amostras'**
  String logFamily(int count);

  /// No description provided for @familyQuality.
  ///
  /// In pt, this message translates to:
  /// **'Portão de qualidade (chamada reprovada = ausente)'**
  String get familyQuality;

  /// No description provided for @trioEventDeNovo.
  ///
  /// In pt, this message translates to:
  /// **'Candidata a de novo'**
  String get trioEventDeNovo;

  /// No description provided for @trioEventError.
  ///
  /// In pt, this message translates to:
  /// **'Erro mendeliano'**
  String get trioEventError;
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
