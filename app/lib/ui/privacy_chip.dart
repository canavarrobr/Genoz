import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'theme.dart';

/// Diálogo "Sua privacidade" (selo e menu lateral).
Future<void> showPrivacyDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock),
      title: Text(l.privacyTitle),
      content: Text('${l.privacyBody}\n\n${l.notDiagnosis}'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok))],
    ),
  );
}

/// Indicador sempre visível de que o processamento é local (especificação, seção 8).
class PrivacyChip extends StatelessWidget {
  const PrivacyChip({super.key, this.onDark = false});

  /// Versão para fundo escuro (cabeçalho com gradiente).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    final bg = onDark ? Colors.white.withValues(alpha: 0.16) : c.primaryContainer;
    final fg = onDark ? Colors.white : c.onPrimaryContainer;
    return Semantics(
      button: true,
      label: l.privateMode,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showPrivacyDialog(context),
        child: Container(
          margin: onDark ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 16, color: onDark ? GenozColors.cyan : fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.privateMode,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
