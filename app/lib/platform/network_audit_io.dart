// Auditoria de rede no Android/iOS: toda conexão HTTP criada pelo Dart é registrada.

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
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      audit.record(uri.toString(), 'http');
      final host = proxyHost ?? uri.host;
      final port = proxyPort ?? uri.port;
      return uri.scheme == 'https' && proxyHost == null
          ? SecureSocket.startConnect(host, port, context: context)
          : Socket.startConnect(host, port);
    };
    return client;
  }
}
