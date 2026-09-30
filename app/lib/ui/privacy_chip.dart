import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Indicador sempre visível de que o processamento é local (especificação, seção 8).
class PrivacyChip extends StatelessWidget {
  const PrivacyChip({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l.privateMode,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.lock),
            title: Text(l.privacyTitle),
            content: Text('${l.privacyBody}\n\n${l.notDiagnosis}'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.ok))],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 16, color: c.onPrimaryContainer),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.privateMode,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.onPrimaryContainer, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
