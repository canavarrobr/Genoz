// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Genoz';

  @override
  String get privateMode => 'Modo privado — processamento local';

  @override
  String get privacyTitle => 'Sua privacidade';

  @override
  String get privacyBody =>
      'No modo privado, o Genoz processa seus arquivos genômicos somente neste aparelho. Nada é enviado a servidores, não há conta nem telemetria.\n\nOs arquivos importados ficam numa pasta privada do app. Apagar um projeto apaga também os arquivos dele.';

  @override
  String get notDiagnosis =>
      'Uso educacional e de pesquisa. Não é diagnóstico.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Apagar';

  @override
  String get rename => 'Renomear';

  @override
  String get projectsEmptyTitle => 'Nenhum projeto ainda';

  @override
  String get projectsEmptyBody =>
      'Crie um projeto para importar arquivos VCF e comparar amostras.';

  @override
  String get newProject => 'Novo projeto';

  @override
  String get projectName => 'Nome do projeto';

  @override
  String get projectDescription => 'Descrição (opcional)';

  @override
  String get projectNameRequired => 'Dê um nome ao projeto';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
      zero: 'nenhum arquivo',
    );
    return '$_temp0';
  }

  @override
  String get deleteProjectTitle => 'Apagar projeto?';

  @override
  String deleteProjectBody(String name) {
    return 'O projeto \"$name\" e todos os seus arquivos serão apagados deste aparelho. Isso não pode ser desfeito.';
  }

  @override
  String get deleteFileTitle => 'Remover arquivo?';

  @override
  String deleteFileBody(String name) {
    return 'A cópia de \"$name\" guardada pelo Genoz será apagada. O arquivo original não é afetado.';
  }

  @override
  String get importVcf => 'Importar VCF';

  @override
  String get generateExample => 'Gerar exemplo sintético';

  @override
  String get generateExampleHint =>
      'Cria um VCF fictício para experimentar o app sem dados reais.';

  @override
  String get filesEmptyTitle => 'Nenhum arquivo neste projeto';

  @override
  String get filesEmptyBody =>
      'Importe um arquivo VCF (.vcf ou .vcf.gz) ou gere um exemplo sintético.';

  @override
  String get importCopying => 'Copiando e calculando o SHA-256…';

  @override
  String get importValidating => 'Validando o VCF…';

  @override
  String importing(String name) {
    return 'Importando $name';
  }

  @override
  String get importCancelled => 'Importação cancelada.';

  @override
  String get importFailedTitle => 'Não foi possível importar';

  @override
  String get importInvalidTitle => 'Arquivo inválido';

  @override
  String get importInvalidBody =>
      'O Genoz leu o arquivo, mas nenhuma variante pôde ser usada.';

  @override
  String importDuplicate(String name) {
    return 'Este arquivo já foi importado neste projeto (\"$name\").';
  }

  @override
  String importDone(String name) {
    return '\"$name\" importado.';
  }

  @override
  String get verdictValid => 'Válido';

  @override
  String get verdictValidWithWarnings => 'Válido com avisos';

  @override
  String get verdictPartiallyValid => 'Parcialmente válido';

  @override
  String get verdictInvalid => 'Inválido';

  @override
  String samplesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amostras',
      one: '1 amostra',
      zero: 'apenas sítios',
    );
    return '$_temp0';
  }

  @override
  String variantsCount(int count) {
    return '$count variantes';
  }

  @override
  String get buildUnknown => 'build desconhecido';

  @override
  String get sectionFile => 'Arquivo';

  @override
  String get sectionBuild => 'Genoma de referência';

  @override
  String get sectionSamples => 'Amostras';

  @override
  String get sectionKinds => 'Tipos de variante';

  @override
  String get sectionChromosomes => 'Cromossomos';

  @override
  String get sectionProblems => 'Problemas encontrados';

  @override
  String get fieldSha256 => 'SHA-256';

  @override
  String get fieldSize => 'Tamanho';

  @override
  String get fieldCompression => 'Compressão';

  @override
  String get fieldFormat => 'Formato';

  @override
  String get fieldRecords => 'Registros';

  @override
  String get fieldMultiallelic => 'Multialélicos';

  @override
  String get fieldFilter => 'FILTER';

  @override
  String get fieldSorted => 'Ordenado';

  @override
  String get fieldChromStyle => 'Nomes dos cromossomos';

  @override
  String recordsSummary(int ok, int read, int rejected) {
    return '$ok válidos de $read ($rejected descartados)';
  }

  @override
  String multiallelicSummary(int multi, int split) {
    return '$multi → $split registros bialélicos';
  }

  @override
  String filterSummary(int pass, int failed, int missing) {
    return 'PASS $pass · filtrados $failed · sem filtro $missing';
  }

  @override
  String get yes => 'sim';

  @override
  String get no => 'não';

  @override
  String confidence(String level) {
    return 'confiança $level';
  }

  @override
  String get colHomRef => '0/0';

  @override
  String get colHet => 'het';

  @override
  String get colHomAlt => 'hom-alt';

  @override
  String get colMissing => 'ausente';

  @override
  String get problemsNone => 'Nenhum problema encontrado.';

  @override
  String problemsCount(int errors, int warnings) {
    return '$errors erros · $warnings avisos';
  }

  @override
  String get problemsTruncated =>
      'Lista resumida: só os primeiros problemas aparecem.';

  @override
  String get lineHeader => 'cabeçalho';

  @override
  String lineNumber(int n) {
    return 'linha $n';
  }

  @override
  String readInterrupted(String reason) {
    return 'Leitura interrompida: $reason';
  }

  @override
  String coreVersion(String version) {
    return 'Núcleo $version';
  }

  @override
  String get fileNotFound => 'Arquivo não encontrado.';

  @override
  String get kindSnv => 'SNV';

  @override
  String get kindMnv => 'MNV';

  @override
  String get kindInsertion => 'inserção';

  @override
  String get kindDeletion => 'deleção';

  @override
  String get kindComplex => 'indel complexo';

  @override
  String get kindStructural => 'estrutural/simbólico';

  @override
  String get kindOther => 'outro';

  @override
  String get compNone => 'nenhuma (texto)';

  @override
  String get compGzip => 'gzip comum (não indexável)';

  @override
  String get compBgzf => 'BGZF (indexável)';

  @override
  String get styleUcsc => 'UCSC (chr1, chrX)';

  @override
  String get styleEnsembl => 'Ensembl/NCBI (1, X)';

  @override
  String get styleMixed => 'misto (chr1 e 1)';

  @override
  String get styleUnknown => 'indeterminado';

  @override
  String get confHigh => 'alta';

  @override
  String get confLow => 'baixa';

  @override
  String get confNone => 'nenhuma';

  @override
  String get importFile => 'Arquivo';

  @override
  String get fileMenuReport => 'Ver relatório';
}
