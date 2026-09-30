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

  @override
  String get compareTitle => 'Comparar A × B';

  @override
  String get compareNeedsFiles =>
      'Importe ao menos um arquivo VCF para comparar.';

  @override
  String get sideA => 'Amostra A';

  @override
  String get sideB => 'Amostra B';

  @override
  String get chooseFile => 'Arquivo';

  @override
  String get chooseSample => 'Amostra';

  @override
  String get firstSample => '(primeira do arquivo)';

  @override
  String get qualityGate => 'Portão de qualidade';

  @override
  String get qualityGateHint =>
      'Chamadas reprovadas viram “incertas”, nunca “ausentes”.';

  @override
  String get passOnly => 'Somente FILTER = PASS';

  @override
  String get minQual => 'QUAL mínimo';

  @override
  String get minDp => 'DP mínimo';

  @override
  String get minGq => 'GQ mínimo';

  @override
  String get truthLabel => 'Tratar como verdade (benchmark)';

  @override
  String get truthNone => 'nenhuma';

  @override
  String get runCompare => 'Comparar';

  @override
  String get comparing => 'Comparando…';

  @override
  String get compareFailedTitle => 'Não foi possível comparar';

  @override
  String get compareCancelled => 'Comparação cancelada.';

  @override
  String get sameSampleWarning =>
      'A e B são a mesma amostra do mesmo arquivo: o resultado será tudo “compartilhada”.';

  @override
  String get analysesTitle => 'Análises';

  @override
  String analysisVs(String a, String b) {
    return '$a × $b';
  }

  @override
  String get deleteAnalysisTitle => 'Apagar análise?';

  @override
  String get deleteAnalysisBody =>
      'Os resultados desta comparação serão apagados. Os arquivos VCF continuam no projeto.';

  @override
  String get analysisNotFound => 'Análise não encontrada.';

  @override
  String get catShared => 'Compartilhada';

  @override
  String get catGenotypeDifference => 'Genótipo diferente';

  @override
  String get catOnlyA => 'Somente em A';

  @override
  String get catOnlyB => 'Somente em B';

  @override
  String get catMissingUncertain => 'Ausente/incerta';

  @override
  String get catNotAssessed => 'Não avaliada';

  @override
  String get stCarrier => 'carrega o alelo';

  @override
  String get stLowQuality => 'carrega, baixa qualidade';

  @override
  String get stExplicitRef => '0/0 explícito';

  @override
  String get stMissing => 'genótipo ausente';

  @override
  String get stAbsentRefBlock => 'referência (bloco gVCF)';

  @override
  String get stAbsentCallable => 'sem registro (região avaliada)';

  @override
  String get stAbsentUnknown => 'sem registro';

  @override
  String get stNotAssessed => 'fora da região avaliada';

  @override
  String get tabSummary => 'Resumo';

  @override
  String get tabTable => 'Tabela';

  @override
  String get tabQc => 'QC';

  @override
  String get concordance => 'Concordância de genótipos';

  @override
  String get jaccard => 'Jaccard (sítios)';

  @override
  String benchmarkTitle(String side) {
    return 'Benchmark (verdade: $side)';
  }

  @override
  String get precision => 'Precisão';

  @override
  String get recall => 'Sensibilidade';

  @override
  String get f1 => 'F1';

  @override
  String get classAll => 'Todas';

  @override
  String get warningsTitle => 'Avisos';

  @override
  String get modeInMemory =>
      'Comparação feita em memória (arquivos fora de ordem).';

  @override
  String get absenceHint =>
      'Sem BED de regiões avaliadas ou gVCF, “somente em A/B” inclui posições sem registro no outro arquivo — que podem simplesmente não ter sido sequenciadas.';

  @override
  String rowsCount(int count) {
    return '$count linhas';
  }

  @override
  String get filters => 'Filtros';

  @override
  String get clearFilters => 'Limpar';

  @override
  String get searchHint => 'chr1:1000, chr7:1M-2M ou rs123';

  @override
  String get noRows => 'Nenhuma linha com esses filtros.';

  @override
  String get saveFilter => 'Salvar filtro';

  @override
  String get filterName => 'Nome do filtro';

  @override
  String get savedFilters => 'Filtros salvos';

  @override
  String get categoriesLabel => 'Categorias';

  @override
  String get kindsLabel => 'Tipos de variante';

  @override
  String get regionLabel => 'Região';

  @override
  String get regionInvalid => 'Região inválida (ex.: chr1:1000-2000)';

  @override
  String get idLabel => 'ID contém';

  @override
  String get apply => 'Aplicar';

  @override
  String get stateLabel => 'Estado';

  @override
  String get gtLabel => 'Genótipo';

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
  String get noteLabel => 'Nota';

  @override
  String get tagsLabel => 'Etiquetas (separadas por vírgula)';

  @override
  String get favorite => 'Favorita';

  @override
  String get noteSaved => 'Nota salva.';

  @override
  String get tiTvHint => 'Referência: ~2,0–2,1 em genoma; ~3,0 em exoma.';

  @override
  String get hetHom => 'het / hom-alt';

  @override
  String get missingRate => 'Ausentes';

  @override
  String get carriers => 'Variantes carregadas';

  @override
  String get lowQualityCount => 'Baixa qualidade';

  @override
  String get dpDistribution => 'Profundidade (DP)';

  @override
  String get gqDistribution => 'Qualidade do genótipo (GQ)';

  @override
  String get qualDistribution => 'QUAL';

  @override
  String get xHet => 'Heterozigosidade no X (fora das PAR)';

  @override
  String get xHetHint =>
      'Indicador educacional de consistência; não determina sexo.';

  @override
  String get export => 'Exportar';

  @override
  String get exportFormat => 'Formato';

  @override
  String exportFiltered(int count) {
    return 'Exporta as $count linhas do filtro atual, com o manifesto de reprodutibilidade.';
  }

  @override
  String exportDone(int count) {
    return '$count linhas exportadas.';
  }

  @override
  String get exportSaveManifest => 'Salvar também o manifesto?';

  @override
  String get exportSaveManifestBody =>
      'O manifesto registra entradas, parâmetros e hashes para refazer esta análise.';

  @override
  String get journalTitle => 'Diário do projeto';

  @override
  String get journalEmpty => 'Nada registrado ainda.';

  @override
  String get notesTitle => 'Notas e favoritas';

  @override
  String get notesEmpty =>
      'Toque numa variante da tabela para anotar ou favoritar.';

  @override
  String logImport(String name) {
    return 'Arquivo importado: $name';
  }

  @override
  String logDeleteFile(String name) {
    return 'Arquivo removido: $name';
  }

  @override
  String logCompare(String a, String b, String id) {
    return 'Comparação $a × $b ($id)';
  }

  @override
  String logExport(String format, int count) {
    return 'Exportação $format: $count linhas';
  }

  @override
  String logFilter(String name) {
    return 'Filtro salvo: $name';
  }

  @override
  String logDeleteAnalysis(String name) {
    return 'Análise apagada: $name';
  }

  @override
  String get minQualShort => 'QUAL ≥';

  @override
  String get minDpShort => 'DP ≥';

  @override
  String get minGqShort => 'GQ ≥';

  @override
  String get exportVcf => 'VCF (A e B)';

  @override
  String get notNow => 'Agora não';
}
