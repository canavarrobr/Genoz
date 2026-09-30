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
