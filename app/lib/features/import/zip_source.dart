// Arquivos .zip de testes de consumidor (23andMe, AncestryDNA…): o arquivo de
// dados fica dentro do ZIP. Abrimos no aparelho e importamos o de dentro.

import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../core/genoz_core.dart';

/// Limite descompactado (os arquivos de chip têm dezenas de MB).
const zipMaxBytes = 400 * 1024 * 1024;

class ZipImportError implements Exception {
  ZipImportError(this.code);

  /// `invalid`, `empty`, `many` ou `tooLarge`.
  final String code;
}

/// Extensões de dados aceitas dentro do ZIP.
const _dataExtensions = ['.txt', '.csv', '.tsv', '.vcf', '.vcf.gz', '.fa', '.fasta'];

/// Devolve o único arquivo de dados do ZIP como origem de importação.
Future<SourceFile> unzipSingleDataFile(String zipName, Uint8List bytes) async {
  // Assinatura "PK": o decodificador aceita lixo como ZIP vazio.
  if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4b || bytes[2] != 3 || bytes[3] != 4) {
    throw ZipImportError('invalid');
  }
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw ZipImportError('invalid');
  }
  final candidates = [
    for (final f in archive.files)
      if (f.isFile &&
          !f.name.split('/').last.startsWith('.') &&
          !f.name.startsWith('__MACOSX') &&
          _dataExtensions.any((e) => f.name.toLowerCase().endsWith(e)))
        f,
  ];
  if (candidates.isEmpty) throw ZipImportError('empty');
  if (candidates.length > 1) throw ZipImportError('many');
  final entry = candidates.single;
  if (entry.size > zipMaxBytes) throw ZipImportError('tooLarge');
  final data = entry.content;
  final name = entry.name.split('/').last;
  return SourceFile(name: name, open: () => Stream.value(data), size: data.length);
}
