// O seletor de arquivos do Android/iOS copia o arquivo escolhido para o cache do
// app antes de entregá-lo. Depois da importação o Genoz já tem a própria cópia,
// então a do cache é apagada (não deixar genomas esquecidos fora dos projetos).

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<void> clearPickerCache() async {
  if (kIsWeb) return;
  try {
    await FilePicker.clearTemporaryFiles();
  } catch (_) {
    // Plataforma sem suporte (ou testes): nada a limpar.
  }
}
