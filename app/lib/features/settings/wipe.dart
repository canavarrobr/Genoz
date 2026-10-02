// "Apagar todos os dados": projetos, arquivos, resultados, diário, ajustes e PIN.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../../platform/picker_cache.dart';
import '../../ui/theme.dart';
import '../annotation/annotation_store.dart';
import '../learn/content.dart';
import '../learn/progress.dart';
import 'settings.dart';

/// Apaga tudo o que o Genoz guardou neste aparelho/navegador.
Future<void> wipeAll({
  required GenozDatabase db,
  required AppStorage storage,
  required GenozCore core,
  required SettingsController settings,
}) async {
  // Resultados abertos na memória (navegador) ou com índice em cache.
  for (final a in await db.select(db.analyses).get()) {
    core.forgetResult(a.resultDir);
  }
  await db.transaction(() async {
    // Tabelas filhas primeiro (ordem inversa da declaração).
    for (final table in db.allTables.toList().reversed) {
      await db.delete(table).go();
    }
  });
  // Linhas apagadas continuam nas páginas livres do arquivo do SQLite até o VACUUM.
  await db.customStatement('VACUUM');
  await storage.deleteDir('projetos');
  // Modo estudante: progresso e aulas importadas.
  await storage.deleteDir(learnDir);
  // Pacotes de anotação baixados (os embutidos são copiados de novo ao abrir).
  await storage.deleteDir(annotationDir);
  await settings.reset();
}

Future<void> wipeAllData(WidgetRef ref) async {
  // Fecha os pacotes de anotação abertos antes de apagar as pastas.
  final core = ref.read(genozCoreProvider);
  for (final p in ref.read(installedPackagesProvider).value ?? const <InstalledPackage>[]) {
    core.forgetAnnotation(p.dir);
  }
  await wipeAll(
    db: ref.read(databaseProvider),
    storage: ref.read(appStorageProvider),
    core: ref.read(genozCoreProvider),
    settings: ref.read(settingsProvider.notifier),
  );
  // Cópias que o seletor de arquivos possa ter deixado no cache.
  await clearPickerCache();
  ref.invalidate(learnProgressProvider);
  ref.invalidate(learnContentProvider);
  ref.invalidate(installedPackagesProvider);
}

/// Campo de confirmação: o botão só funciona depois de digitar a palavra pedida.
class WipeConfirmField extends StatefulWidget {
  const WipeConfirmField({super.key, required this.onConfirmed, this.onDark = false});
  final Future<void> Function() onConfirmed;
  final bool onDark;

  @override
  State<WipeConfirmField> createState() => _WipeConfirmFieldState();
}

class _WipeConfirmFieldState extends State<WipeConfirmField> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final word = l.wipeWord;
    final ok = _text.text.trim().toUpperCase() == word.toUpperCase();
    final fg = widget.onDark ? Colors.white : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.wipeTypeWord(word), style: TextStyle(color: fg)),
        const SizedBox(height: 8),
        TextField(
          controller: _text,
          enabled: !_busy,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: fg),
          decoration: InputDecoration(
            hintText: word,
            filled: widget.onDark,
            fillColor: widget.onDark ? Colors.white12 : null,
            hintStyle: TextStyle(color: widget.onDark ? Colors.white38 : null),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: context.palette.error,
            foregroundColor: Colors.white,
            // Desabilitado continua legível sobre o azul profundo da tela de bloqueio.
            disabledBackgroundColor: widget.onDark ? Colors.white12 : null,
            disabledForegroundColor: widget.onDark ? Colors.white60 : null,
          ),
          onPressed: ok && !_busy
              ? () async {
                  setState(() => _busy = true);
                  await widget.onConfirmed();
                  if (mounted) setState(() => _busy = false);
                }
              : null,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.delete_forever),
          label: Text(l.wipeButton),
        ),
      ],
    );
  }
}
