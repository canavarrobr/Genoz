import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../platform/network_audit.dart';
import '../../ui/brand.dart';
import '../../ui/theme.dart';

/// "Verificar privacidade": números medidos pela auditoria de rede, não texto fixo.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final audit = NetworkAudit.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l.privacyCheckTitle)),
      drawer: const GenozDrawer(current: '/privacidade'),
      body: ListenableBuilder(
        listenable: audit,
        builder: (context, _) {
          final duringOk = audit.externalDuringAnalysis == 0;
          final fmt = DateFormat.Hms(Localizations.localeOf(context).toString());
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text(l.privacyCheckIntro)),
              Card(
                child: Column(
                  children: [
                    _Check(label: l.checkUpload, value: l.checkNo, ok: true),
                    _Check(label: l.checkTelemetry, value: l.checkNo, ok: true),
                    _Check(label: l.checkLocal, value: l.checkYes, ok: true),
                    _Check(label: l.checkExternalDuring, value: '${audit.externalDuringAnalysis}', ok: duringOk),
                  ],
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.checkRequestsTitle, style: t.titleSmall),
                      const SizedBox(height: 8),
                      if (!kIsWeb && audit.events.isEmpty)
                        Text(l.checkNoneNative)
                      else ...[
                        Text(l.checkOwnSite(audit.ownSiteCount)),
                        Text(l.checkExternal(audit.externalCount),
                            style: TextStyle(color: audit.externalCount == 0 ? null : context.palette.warning)),
                        if (kIsWeb) ...[const SizedBox(height: 8), Text(l.checkWhyOwn, style: t.bodySmall)],
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(l.checkExport),
                  onPressed: () => FilePicker.saveFile(
                    fileName: 'genoz_auditoria_rede.json',
                    bytes: Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(audit.toJson()))),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.airplanemode_active, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.checkAirplane, style: t.bodySmall)),
                ]),
              ),
              if (audit.events.isNotEmpty) ...[
                Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text(l.checkLastRequests, style: t.titleSmall)),
                for (final e in audit.events.reversed.take(40))
                  ListTile(
                    dense: true,
                    leading: Icon(e.external ? Icons.public : Icons.home_outlined,
                        color: e.external ? context.palette.warning : context.palette.success),
                    title: Text(Uri.tryParse(e.url)?.path ?? e.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${fmt.format(e.at)} · ${e.kind}${e.duringAnalysis ? ' · ${l.checkDuringTag}' : ''}'),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.label, required this.value, required this.ok});
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(ok ? Icons.check_circle : Icons.warning_amber, color: ok ? context.palette.success : context.palette.warning),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
