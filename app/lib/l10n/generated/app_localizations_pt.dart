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
  String get searchHint => 'BRCA2, chr7:1M-2M ou rs123';

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
  String regionOutside(String chrom) {
    return 'Região inválida. Use posições do cromossomo $chrom, ex.: $chrom:1000-5000.';
  }

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

  @override
  String get brandSignature => 'GENÔMICA SEM FRONTEIRAS';

  @override
  String get brandSlogan => 'Sua genômica, no seu controle.';

  @override
  String get brandSplash => 'Análise genômica local e privada';

  @override
  String get menuProjects => 'Projetos';

  @override
  String get menuAbout => 'Sobre o Genoz';

  @override
  String get menuPrivacy => 'Privacidade';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutBody =>
      'O Genoz compara e explora arquivos genômicos (VCF) inteiramente no seu dispositivo. É um projeto acadêmico para ensino e pesquisa.';

  @override
  String get pillarScience => 'Ciência';

  @override
  String get pillarScienceBody =>
      'Informação confiável, com as fontes e os métodos à vista.';

  @override
  String get pillarPrivacy => 'Privacidade';

  @override
  String get pillarPrivacyBody => 'Seus dados, no seu dispositivo.';

  @override
  String get pillarPerformance => 'Desempenho';

  @override
  String get pillarPerformanceBody =>
      'Análises rápidas e precisas, mesmo em arquivos grandes.';

  @override
  String get pillarMultiplatform => 'Multiplataforma';

  @override
  String get pillarMultiplatformBody =>
      'Web, Android e iOS com o mesmo núcleo.';

  @override
  String aboutVersion(String app, String core) {
    return 'Versão do app $app · núcleo $core';
  }

  @override
  String get aboutLicenses => 'Licenças de código aberto';

  @override
  String get aboutSource => 'Código-fonte: github.com/canavarrobr/Genoz';

  @override
  String get privacyCheckTitle => 'Verificar privacidade';

  @override
  String get privacyCheckIntro =>
      'Estes números são medidos agora, neste dispositivo: o Genoz registra cada requisição de rede que faz.';

  @override
  String get checkUpload => 'Arquivo genômico enviado';

  @override
  String get checkTelemetry => 'Telemetria';

  @override
  String get checkLocal => 'Análise local';

  @override
  String get checkExternalDuring => 'Conexões externas durante análises';

  @override
  String get checkNo => 'NÃO';

  @override
  String get checkYes => 'SIM';

  @override
  String get checkRequestsTitle => 'Requisições desde que o app abriu';

  @override
  String checkOwnSite(int count) {
    return '$count do próprio site (carregar o app)';
  }

  @override
  String checkExternal(int count) {
    return '$count para outros endereços';
  }

  @override
  String get checkNoneNative => 'Nenhuma conexão de rede foi aberta pelo app.';

  @override
  String get checkExport => 'Exportar relatório de auditoria (JSON)';

  @override
  String get checkAirplane =>
      'Dica: ative o modo avião e continue usando o Genoz — tudo funciona sem internet.';

  @override
  String get checkLastRequests => 'Últimas requisições';

  @override
  String get checkWhyOwn =>
      'No navegador, abrir o site baixa o próprio app (código, fontes e o núcleo WebAssembly). Depois disso, nada é enviado.';

  @override
  String webTooLargeHint(int mb) {
    return 'No navegador cada arquivo pode ter até $mb MB. Para arquivos maiores, use o app Android.';
  }

  @override
  String get webUnsupported =>
      'Este navegador não oferece os recursos necessários (WebAssembly com threads e armazenamento privado). Use Chrome, Edge ou Firefox atualizados.';

  @override
  String get checkDuringTag => 'durante análise';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsSystem => 'Sistema';

  @override
  String get settingsLight => 'Claro';

  @override
  String get settingsDark => 'Escuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLock => 'Bloqueio';

  @override
  String get settingsPinLock => 'Bloquear com PIN';

  @override
  String get settingsPinOn => 'O Genoz pede o PIN ao abrir';

  @override
  String get settingsPinOff => 'Desligado';

  @override
  String get settingsChangePin => 'Trocar o PIN';

  @override
  String get settingsLockAfter => 'Pedir de novo após';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get settingsBiometrics => 'Desbloquear com biometria';

  @override
  String get settingsBiometricsUnavailable =>
      'Nenhuma digital ou rosto cadastrado neste aparelho';

  @override
  String get settingsLockNote =>
      'O bloqueio impede que outra pessoa abra o Genoz neste aparelho. Ele não criptografa os arquivos. O PIN não pode ser recuperado: se você o esquecer, a única saída é apagar todos os dados.';

  @override
  String get settingsScreen => 'Tela';

  @override
  String get settingsSecureScreen => 'Proteger a tela';

  @override
  String get settingsSecureScreenHint =>
      'Bloqueia capturas de tela e esconde o conteúdo na lista de apps recentes';

  @override
  String get settingsData => 'Dados';

  @override
  String get wipeTitle => 'Apagar todos os dados';

  @override
  String get wipeSubtitle =>
      'Projetos, arquivos, resultados, diário, ajustes e PIN';

  @override
  String get wipeBody =>
      'Isto apaga do aparelho tudo o que o Genoz guardou: projetos, cópias dos arquivos VCF, resultados das comparações, anotações, diário, ajustes e PIN. Os arquivos originais que você escolheu ao importar não são tocados. Não há como desfazer.';

  @override
  String get wipeWord => 'APAGAR';

  @override
  String wipeTypeWord(String word) {
    return 'Para confirmar, digite $word:';
  }

  @override
  String get wipeButton => 'Apagar tudo';

  @override
  String get wipeDone => 'Todos os dados foram apagados.';

  @override
  String get lockTitle => 'Genoz bloqueado';

  @override
  String get lockWrongPin => 'PIN incorreto';

  @override
  String lockWait(int seconds) {
    return 'Muitas tentativas. Aguarde $seconds s.';
  }

  @override
  String get lockUseBiometrics => 'Usar biometria';

  @override
  String get lockForgot => 'Esqueci o PIN';

  @override
  String get lockForgotBody =>
      'O PIN não fica guardado em lugar nenhum, só uma impressão dele que não pode ser revertida. Para voltar a usar o Genoz sem o PIN, é preciso apagar todos os dados deste aparelho. Os arquivos originais que você importou não são tocados.';

  @override
  String get lockBack => 'Voltar';

  @override
  String get lockBiometricReason => 'Desbloquear o Genoz';

  @override
  String pinDigitsEntered(int count) {
    return '$count dígitos digitados';
  }

  @override
  String get pinErase => 'Apagar dígito';

  @override
  String get pinConfirm => 'Confirmar';

  @override
  String get pinMismatch => 'Os PINs não conferem. Comece de novo.';

  @override
  String get pinCurrent => 'Digite o PIN atual';

  @override
  String get pinNew => 'Escolha um PIN';

  @override
  String get pinRepeat => 'Repita o PIN';

  @override
  String get pinRule => 'De 4 a 8 dígitos';

  @override
  String get tabMap => 'Mapa';

  @override
  String get mapAll => 'Todas';

  @override
  String get mapUnknownBuild =>
      'Build de referência desconhecido: cada cromossomo é desenhado até a maior posição encontrada, sem centrômero.';

  @override
  String get mapFew => 'poucas';

  @override
  String get mapMany => 'muitas';

  @override
  String get mapCentromere => 'centrômero (posição aproximada)';

  @override
  String mapChromSemantics(String chrom, int count) {
    return 'Cromossomo $chrom: $count variantes. Toque para ver a região.';
  }

  @override
  String regionTitle(String chrom) {
    return 'Cromossomo $chrom';
  }

  @override
  String get regionField => 'Região (ex.: 1:1.000.000-2.000.000)';

  @override
  String get regionZoomIn => 'Aproximar';

  @override
  String get regionZoomOut => 'Afastar';

  @override
  String regionTrackSemantics(String region, int count) {
    return 'Trilha da região $region com $count variantes. Toque duas vezes para aproximar; arraste para os lados para mover.';
  }

  @override
  String get regionLoading => 'Carregando…';

  @override
  String regionShowing(int shown, int total) {
    return 'Mostrando $shown de $total variantes — aproxime para ver todas.';
  }

  @override
  String regionCount(int count) {
    return '$count variantes neste trecho';
  }

  @override
  String get regionNoVariants => 'Nenhuma variante neste trecho.';

  @override
  String get vennTitle => 'Interseções';

  @override
  String vennSemantics(
    String a,
    String b,
    int onlyA,
    int both,
    int diff,
    int onlyB,
  ) {
    return 'Diagrama de interseções: $onlyA variantes só em $a, $both nos dois ($diff com genótipo diferente), $onlyB só em $b.';
  }

  @override
  String vennOnly(String name) {
    return 'só em $name';
  }

  @override
  String get vennBoth => 'nos dois';

  @override
  String vennBreakdown(int same, int diff) {
    return '$same iguais · $diff genótipo diferente';
  }

  @override
  String vennOutside(int missing, int notAssessed) {
    return 'Fora do diagrama: $missing ausentes/incertas e $notAssessed não avaliadas.';
  }

  @override
  String get vennNotProportional =>
      'Os círculos não estão em escala: os números indicam as quantidades.';

  @override
  String get learnTitle => 'Aprender';

  @override
  String get learnIntro =>
      'Trilhas guiadas com dados fictícios: comparar amostras, ler genótipos e explorar o mapa do genoma. Tudo roda no aparelho. Para ensino — não é diagnóstico.';

  @override
  String learnProgress(int correct, int total) {
    return '$correct de $total exercícios certos';
  }

  @override
  String get glossaryTitle => 'Glossário';

  @override
  String glossarySubtitle(int count) {
    return '$count termos, em português e inglês';
  }

  @override
  String get glossarySearch => 'Buscar termo';

  @override
  String get glossaryNone => 'Nenhum termo encontrado.';

  @override
  String get packageImport => 'Importar pacote de aula';

  @override
  String get packageImportHint => 'Arquivo .genozaula recebido do professor';

  @override
  String get packageImporting =>
      'Importando a aula: conferindo arquivos e comparando…';

  @override
  String get packageProjectDescription =>
      'Aula importada de um pacote de professor.';

  @override
  String packageImported(String title) {
    return 'Aula \"$title\" importada.';
  }

  @override
  String packageError(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'notPackage': 'Este arquivo não é um pacote de aula do Genoz.',
      'newerVersion': 'Este pacote foi feito por uma versão mais nova do Genoz. Atualize o app.',
      'missingFile': 'O pacote está incompleto (falta um arquivo).',
      'corrupted': 'Um arquivo do pacote está corrompido (SHA-256 não confere). Nada foi importado.',
      'tooLarge': 'O pacote é grande demais para este aparelho.',
      'other': 'Não foi possível importar o pacote.',
    });
    return '$_temp0';
  }

  @override
  String learnProjectName(String title) {
    return 'Aula: $title';
  }

  @override
  String get learnProjectDescription => 'Dados fictícios do modo estudante.';

  @override
  String learnDataset(String title) {
    return 'Dados: $title';
  }

  @override
  String learnOpenTab(String tab) {
    return 'Abrir $tab';
  }

  @override
  String get learnExercises => 'Exercícios';

  @override
  String get learnPrepare => 'Preparar os dados da aula';

  @override
  String get exerciseCorrect => 'Respondido corretamente';

  @override
  String get exerciseCheck => 'Conferir';

  @override
  String get exerciseReveal => 'Ver resposta';

  @override
  String get exerciseUnavailable =>
      'Não dá para calcular esta resposta com estes dados.';

  @override
  String get exerciseRight => 'Certo!';

  @override
  String get exerciseWrong => 'Ainda não.';

  @override
  String exerciseAnswer(String answer) {
    return 'Resposta: $answer';
  }

  @override
  String get packageCreateTitle => 'Criar pacote de aula';

  @override
  String get packageCreateIntro =>
      'Transforma esta comparação num arquivo .genozaula para os alunos. Eles importam em Aprender e recebem os mesmos arquivos, a comparação pronta e as perguntas.';

  @override
  String get packageTitleField => 'Título da aula';

  @override
  String get packageInstructionsField => 'Instruções para os alunos (opcional)';

  @override
  String get packageQuestions => 'Perguntas (corrigidas automaticamente)';

  @override
  String get packagePrivacyNote =>
      'O pacote leva cópias dos arquivos VCF desta comparação. Use só dados fictícios ou com autorização. As respostas não vão no pacote: são calculadas no aparelho de cada aluno.';

  @override
  String get packageSave => 'Salvar pacote';

  @override
  String get packageSaved => 'Pacote de aula salvo.';

  @override
  String get exerciseHint => 'Sua resposta';

  @override
  String get packageOpenStep =>
      'Abra a comparação da aula: as respostas estão no Resumo, na Tabela e no Mapa.';

  @override
  String get chipModeHint =>
      'A é um arquivo de chip: a comparação fica restrita aos sítios que o chip avalia. B precisa ser um VCF.';

  @override
  String get referenceTitle => 'Referência (FASTA)';

  @override
  String get referenceHintChip =>
      'Opcional. Com a referência, sítios homozigotos do chip sem registro no VCF também podem ser julgados.';

  @override
  String get referenceHintVcf =>
      'Opcional. Alinha os indels à esquerda antes de comparar e confere o REF de cada variante (usa mais memória).';

  @override
  String get referenceNone => 'Sem referência';

  @override
  String kindChip(String vendor) {
    return 'chip $vendor';
  }

  @override
  String get kindFasta => 'FASTA de referência';

  @override
  String sitesCount(int count) {
    return '$count sítios';
  }

  @override
  String sequencesCount(int count) {
    return '$count sequências';
  }

  @override
  String get sectionChip => 'Chip de consumidor';

  @override
  String get chipVendor => 'Empresa';

  @override
  String get chipSites => 'Sítios no chip';

  @override
  String get chipCalled => 'Com genótipo';

  @override
  String get chipNoCalls => 'Sem chamada (--)';

  @override
  String get chipHet => 'Heterozigotos';

  @override
  String get chipHom => 'Homozigotos';

  @override
  String get chipHaploid => 'Haploides (X/Y/MT)';

  @override
  String get chipIndels => 'Indels ignorados';

  @override
  String get chipNote =>
      'Chips medem só posições escolhidas pelo fabricante e não informam a base de referência. Na comparação com um VCF os genótipos são comparados letra a letra, só nesses sítios.';

  @override
  String get sectionFasta => 'Referência (FASTA)';

  @override
  String get fastaSequences => 'Sequências';

  @override
  String get fastaTotalBases => 'Bases no total';

  @override
  String get fastaNote =>
      'Usado para alinhar indels à esquerda e para julgar sítios do chip sem registro no VCF. Fica só neste aparelho.';

  @override
  String chipCompareTitle(String vendor) {
    return 'Chip $vendor × sequenciamento';
  }

  @override
  String get chipCompareRestricted =>
      'Só os sítios que o chip avalia. Variantes do VCF fora do chip não entram na conta (ver abaixo).';

  @override
  String get chipCompareNonref =>
      'Concordância sem os sítios referência × referência';

  @override
  String get chipCompareOffChip => 'Variantes do VCF fora do chip';

  @override
  String get chipCompareUnknownRef =>
      'Homozigotos do chip sem registro no VCF (referência desconhecida)';

  @override
  String get chipCompareRefNotAssessed =>
      'Homozigotos de referência sem registro no VCF';

  @override
  String get chipCompareStrandFlips => 'Diferenças que parecem troca de fita';

  @override
  String zipError(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'invalid': 'Não foi possível abrir o .zip.',
      'empty': 'O .zip não tem um arquivo de dados (.txt, .csv, .vcf).',
      'many': 'O .zip tem mais de um arquivo de dados; extraia e importe o que quiser.',
      'tooLarge': 'O arquivo dentro do .zip é grande demais.',
      'other': 'Não foi possível importar o .zip.',
    });
    return '$_temp0';
  }

  @override
  String get annotTitle => 'Anotações';

  @override
  String get annotIntro =>
      'Anotação acrescenta o que fontes públicas dizem sobre cada variante e região: genes (GENCODE) e o ClinVar. Tudo é consultado no aparelho. O Genoz não classifica variantes: só mostra o que cada fonte diz, com versão e data.';

  @override
  String get annotNoInternet =>
      'O Genoz não tem acesso à internet. Para um pacote do catálogo, baixe o arquivo oficial pelo seu navegador e importe aqui: o app só aceita se a impressão digital (SHA-256) for exatamente a do catálogo.';

  @override
  String get annotInstalled => 'Instalados';

  @override
  String get annotCatalog => 'Catálogo (baixar pelo navegador)';

  @override
  String get annotCustom => 'Pacote próprio';

  @override
  String get annotCustomImport => 'Importar BED ou TSV';

  @override
  String get annotCustomHint =>
      'Ex.: a lista de genes de uma disciplina. BED (0-based) ou TSV com colunas chrom, start, end, nome…';

  @override
  String get annotCustomName => 'Nome do pacote';

  @override
  String get annotChooseFile => 'Escolher arquivo';

  @override
  String get annotBuilding => 'Montando o pacote…';

  @override
  String get annotChecking =>
      'Conferindo o SHA-256 e montando o pacote. Arquivos grandes (ClinVar) podem levar alguns minutos.';

  @override
  String annotInstalledOk(String name, int records) {
    return 'Pacote \"$name\" instalado ($records registros).';
  }

  @override
  String get annotHashMismatch =>
      'Este arquivo não é o do catálogo (SHA-256 diferente). Nada foi instalado. Confira se baixou o arquivo do link indicado e se o download terminou.';

  @override
  String annotBuildFailed(String detail) {
    return 'Não foi possível montar o pacote: $detail';
  }

  @override
  String annotRecords(String count) {
    return '$count registros';
  }

  @override
  String get annotEmbedded => 'embutido';

  @override
  String get annotVersion => 'Versão';

  @override
  String get annotLicense => 'Licença';

  @override
  String get annotCitation => 'Como citar';

  @override
  String get annotSourceUrl => 'Origem';

  @override
  String get annotHowTo =>
      '1. Baixe o arquivo pelo navegador. 2. Importe o arquivo baixado aqui. O app confere o SHA-256 antes de usar.';

  @override
  String get annotOpenBrowser => 'Baixar no navegador';

  @override
  String get annotCopyUrl => 'Copiar link';

  @override
  String get annotUrlCopied => 'Link copiado.';

  @override
  String get annotImportDownloaded => 'Importar arquivo baixado';

  @override
  String get sourcesTitle => 'O que as fontes dizem';

  @override
  String sourcesSays(String source, String version, String date) {
    return '$source · versão $version ($date)';
  }

  @override
  String sourcesMore(int count) {
    return '… e mais $count';
  }

  @override
  String get sourcesNoClassification =>
      'O Genoz não classifica variantes: os textos acima são da fonte indicada, na versão indicada.';

  @override
  String geneFound(String gene, String region) {
    return '$gene: $region';
  }

  @override
  String get clinvarLicense =>
      'Uso e redistribuição livres com atribuição ao ClinVar';

  @override
  String get clinvarDisclaimer =>
      'O ClinVar não é para uso diagnóstico direto nem decisão médica sem revisão de um profissional de genética; o NIH não verifica as informações enviadas.';

  @override
  String get gencodeLicense =>
      'Acesso aberto (EMBL-EBI: sem restrições adicionais; atribuição esperada)';

  @override
  String get vaultExport => 'Exportar projeto (.genoz)';

  @override
  String get vaultProtect => 'Proteger com senha';

  @override
  String get vaultImport => 'Importar projeto (.genoz)';

  @override
  String get vaultLocked => 'Protegido com senha';

  @override
  String get vaultOpen => 'Abrir com a senha';

  @override
  String get vaultLockedBody =>
      'Os dados deste projeto estão cifrados neste aparelho. Digite a senha para abri-lo.';

  @override
  String get vaultNewPasswordTitle => 'Criar senha';

  @override
  String get vaultPassword => 'Senha';

  @override
  String get vaultPasswordRepeat => 'Repita a senha';

  @override
  String vaultPasswordShort(int min) {
    return 'Use pelo menos $min caracteres.';
  }

  @override
  String get vaultPasswordMismatch => 'As senhas não são iguais.';

  @override
  String get vaultLossWarning =>
      'Se você esquecer a senha, os dados não podem ser recuperados — por ninguém, nem pelo Genoz. Anote-a num lugar seguro.';

  @override
  String get vaultLossAccept => 'Entendi: senha perdida = dados perdidos';

  @override
  String get vaultProtectBody =>
      'O projeto será cifrado neste aparelho (Argon2id + XChaCha20-Poly1305) e a cópia em claro, apagada. Para usá-lo de novo, abra com a senha.';

  @override
  String get vaultExportBody =>
      'O arquivo .genoz sai cifrado com esta senha. Leve-o a outro aparelho (cabo, pendrive, Bluetooth...) e importe-o lá com a mesma senha. Nada é enviado para a internet.';

  @override
  String get vaultExportLockedBody =>
      'Este projeto já está cifrado: o arquivo .genoz usa a mesma senha dele.';

  @override
  String get vaultSealing => 'Cifrando o projeto…';

  @override
  String get vaultOpening => 'Conferindo a senha e decifrando…';

  @override
  String get vaultWrongPassword =>
      'Senha incorreta — ou o arquivo foi alterado ou está incompleto.';

  @override
  String get vaultNotGenoz => 'Este arquivo não é um projeto .genoz do Genoz.';

  @override
  String get vaultNewerVersion =>
      'Este arquivo é de uma versão mais nova do Genoz. Atualize o app.';

  @override
  String get vaultExported => 'Projeto exportado.';

  @override
  String get vaultProtected => 'Projeto protegido com senha.';

  @override
  String vaultImported(String name) {
    return 'Projeto \"$name\" importado.';
  }

  @override
  String get vaultOpened =>
      'Projeto aberto. Para cifrar de novo, use \"Proteger com senha\".';

  @override
  String vaultFailed(String detail) {
    return 'Não foi possível concluir: $detail';
  }

  @override
  String get logVaultImported => 'Projeto importado de um arquivo .genoz';

  @override
  String get logVaultOpened => 'Projeto aberto com a senha';

  @override
  String get logVaultExported => 'Projeto exportado (.genoz, cifrado)';

  @override
  String get reportSection => 'Relatório';

  @override
  String get reportHtml => 'Relatório HTML (abre em qualquer navegador)';

  @override
  String get reportPdf => 'Relatório PDF';

  @override
  String get reportSaved => 'Relatório salvo.';

  @override
  String logReport(String format) {
    return 'Relatório $format gerado';
  }

  @override
  String get reproVerify => 'Verificar reprodutibilidade';

  @override
  String get reproRunning => 'Conferindo as entradas e refazendo a análise…';

  @override
  String get reproTitle => 'Reprodutibilidade';

  @override
  String reproOk(int total) {
    return 'Reproduzida: mesmo ID e $total de $total saídas idênticas (SHA-256).';
  }

  @override
  String reproPartial(int ok, int total) {
    return '$ok de $total saídas idênticas.';
  }

  @override
  String get reproInputs => 'Entradas';

  @override
  String get reproOutputs => 'Saídas';

  @override
  String get reproInputOk => 'SHA-256 confere';

  @override
  String get reproInputMissing => 'não está mais no projeto';

  @override
  String get reproInputChanged => 'SHA-256 diferente (arquivo alterado)';

  @override
  String get reproInputUnsupported =>
      'regiões avaliadas (BED): reexecute pela linha de comando';

  @override
  String get reproIdDiffers => 'O ID da reexecução é diferente do original.';

  @override
  String get reproNotRun =>
      'As entradas não conferem: a reexecução não provaria nada.';

  @override
  String reproFailed(String detail) {
    return 'A reexecução falhou: $detail';
  }

  @override
  String get reproIdentical => 'idêntica';

  @override
  String get reproDifferent => 'diferente';

  @override
  String get reproMissing => 'ausente';

  @override
  String get reproExplain =>
      'A análise foi refeita numa pasta temporária com os mesmos arquivos e parâmetros, e cada saída comparada pelo SHA-256 com o manifesto. A análise salva não muda.';

  @override
  String logRepro(String result) {
    return 'Reprodutibilidade verificada: $result';
  }
}
