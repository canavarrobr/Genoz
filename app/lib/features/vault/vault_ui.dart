// Telas do cofre .genoz: criar senha, digitar senha, exportar, importar, proteger, abrir.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../../platform/file_saver.dart';
import '../../platform/picker_cache.dart';
import '../../ui/theme.dart';
import '../about/about_screen.dart' show appVersion;
import 'project_vault.dart';

String vaultMessage(AppLocalizations l, Object e) => switch (e) {
      VaultError(code: 'senha') => l.vaultWrongPassword,
      VaultError(code: 'formato') => l.vaultNotGenoz,
      VaultError(code: 'versao') => l.vaultNewerVersion,
      VaultError(:final detail) => l.vaultFailed(detail),
      _ => l.vaultFailed('$e'),
    };

/// Pede uma senha nova (duas vezes) e a confirmação de que senha perdida = dados perdidos.
Future<String?> askNewPassword(BuildContext context, {required String body}) => showDialog<String>(
      context: context,
      builder: (_) => _NewPasswordDialog(body: body),
    );

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog({required this.body});
  final String body;

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  bool _accepted = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppLocalizations.of(context);
    setState(() {
      _error = _a.text.length < minPasswordLength
          ? l.vaultPasswordShort(minPasswordLength)
          : _a.text != _b.text
              ? l.vaultPasswordMismatch
              : null;
    });
    if (_error == null && _accepted) Navigator.pop(context, _a.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: Text(l.vaultNewPasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body, style: t.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _a,
              // Sem foco automático: o teclado esconderia o aviso e a confirmação abaixo.
              obscureText: !_show,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l.vaultPassword,
                suffixIcon: IconButton(
                  icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _show = !_show),
                ),
              ),
            ),
            TextField(
              controller: _b,
              obscureText: !_show,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l.vaultPasswordRepeat, errorText: _error),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Text(l.vaultLossWarning, style: t.bodySmall?.copyWith(color: context.palette.error)),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v ?? false),
              title: Text(l.vaultLossAccept, style: t.bodyMedium),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _accepted ? _submit : null, child: Text(l.save)),
      ],
    );
  }
}

/// Pede a senha de um .genoz ou projeto protegido.
Future<String?> askPassword(BuildContext context, {String? title, String? error}) {
  final c = TextEditingController();
  final l = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock_open_outlined),
      title: Text(title ?? l.vaultOpen),
      content: TextField(
        controller: c,
        obscureText: true,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(labelText: l.vaultPassword, errorText: error, errorMaxLines: 3),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.vaultOpen)),
      ],
    ),
  ).whenComplete(c.dispose);
}

/// Mostra o progresso enquanto `action` roda (sem como fechar no meio).
Future<T> withProgress<T>(BuildContext context, String message, Future<T> Function() action) async {
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await action();
  } finally {
    navigator.pop();
  }
}

String _fileName(String projectName) {
  final slug = projectName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9à-ü]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return '${slug.isEmpty ? 'projeto' : slug}.$vaultExtension';
}

Future<void> exportProjectFlow(BuildContext context, WidgetRef ref, Project project) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  String password = '';
  if (!project.locked) {
    final p = await askNewPassword(context, body: l.vaultExportBody);
    if (p == null || !context.mounted) return;
    password = p;
  } else {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.vaultExport),
        content: Text(l.vaultExportLockedBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
  }
  final storage = ref.read(appStorageProvider);
  String? out;
  try {
    final file = await withProgress(
      context,
      l.vaultSealing,
      () => ref.read(projectVaultProvider).export(project.id, password, appVersion: appVersion),
    );
    out = file;
    final saved = await saveStoredFile(storage, file, _fileName(project.name));
    if (saved) {
      if (!project.locked) await ref.read(analysisRepositoryProvider).log(project.id, 'export', l.logVaultExported);
      messenger.showSnackBar(SnackBar(content: Text(l.vaultExported)));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(vaultMessage(l, e))));
  } finally {
    if (out != null) await storage.blobs.deleteFile(out);
  }
}

/// Protege o projeto. Devolve `true` se foi protegido.
Future<bool> protectProjectFlow(BuildContext context, WidgetRef ref, Project project) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final password = await askNewPassword(context, body: l.vaultProtectBody);
  if (password == null || !context.mounted) return false;
  try {
    await withProgress(
      context,
      l.vaultSealing,
      () => ref.read(projectVaultProvider).lock(project.id, password, appVersion: appVersion),
    );
    messenger.showSnackBar(SnackBar(content: Text(l.vaultProtected)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(vaultMessage(l, e))));
    return false;
  }
}

/// Abre um projeto protegido (pede a senha de novo se estiver errada). `true` se abriu.
Future<bool> unlockProjectFlow(BuildContext context, WidgetRef ref, Project project) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  String? error;
  while (true) {
    if (!context.mounted) return false;
    final password = await askPassword(context, title: project.name, error: error);
    if (password == null || !context.mounted) return false;
    try {
      await withProgress(
        context,
        l.vaultOpening,
        () => ref.read(projectVaultProvider).unlock(project.id, password, journalMessage: l.logVaultOpened),
      );
      messenger.showSnackBar(SnackBar(content: Text(l.vaultOpened)));
      return true;
    } on VaultError catch (e) {
      if (e.code != 'senha') {
        messenger.showSnackBar(SnackBar(content: Text(vaultMessage(l, e))));
        return false;
      }
      error = l.vaultWrongPassword;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(vaultMessage(l, e))));
      return false;
    }
  }
}

/// Importa um .genoz como projeto novo. Devolve o ID do projeto, ou `null`.
Future<String?> importProjectFlow(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final f = await FilePicker.pickFile(type: FileType.any);
  if (f == null || !context.mounted) return null;
  final source = SourceFile(name: f.name, path: f.path, open: f.readAsByteStream, size: await f.length());
  String? error;
  try {
    while (true) {
      if (!context.mounted) return null;
      final password = await askPassword(context, title: f.name, error: error);
      if (password == null || !context.mounted) return null;
      try {
        final id = await withProgress(
          context,
          l.vaultOpening,
          () => ref.read(projectVaultProvider).import(source, password, journalMessage: l.logVaultImported),
        );
        final db = ref.read(databaseProvider);
        final p = await (db.select(db.projects)..where((t) => t.id.equals(id))).getSingle();
        messenger.showSnackBar(SnackBar(content: Text(l.vaultImported(p.name))));
        return id;
      } on VaultError catch (e) {
        if (e.code != 'senha') {
          messenger.showSnackBar(SnackBar(content: Text(vaultMessage(l, e))));
          return null;
        }
        error = l.vaultWrongPassword;
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(vaultMessage(l, e))));
        return null;
      }
    }
  } finally {
    await clearPickerCache();
  }
}
