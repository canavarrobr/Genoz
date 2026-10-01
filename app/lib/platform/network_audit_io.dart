// Auditoria de rede no Android/iOS: toda requisição HTTP feita pelo Dart é registrada.

import 'dart:io';

import 'network_audit.dart';

void startNetworkAudit(NetworkAudit audit) {
  HttpOverrides.global = _AuditingOverrides(audit, HttpOverrides.current);
}

/// No app nativo não existe "o próprio site": qualquer conexão é externa.
bool isExternal(String url) => true;

class _AuditingOverrides extends HttpOverrides {
  _AuditingOverrides(this.audit, this.previous);

  final NetworkAudit audit;
  final HttpOverrides? previous;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = previous?.createHttpClient(context) ?? super.createHttpClient(context);
    // findProxy é consultado a cada requisição (inclusive em conexões reaproveitadas
    // por keep-alive), então registra pedidos, não só conexões novas.
    client.findProxy = (uri) {
      audit.record(uri.toString(), 'http');
      return HttpClient.findProxyFromEnvironment(uri);
    };
    return client;
  }
}
