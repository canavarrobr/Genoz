// Auditoria REAL de rede (especificação, seção 8): registra cada requisição
// que o app faz, em vez de só afirmar que não faz nenhuma.
//
// - Android/iOS: HttpOverrides — toda conexão HTTP do Dart passa por aqui.
// - Navegador: PerformanceObserver — o navegador informa cada recurso buscado
//   pela página (inclusive scripts, fontes, WASM e chamadas fetch/XHR).

import 'package:flutter/foundation.dart';

import 'network_audit_io.dart' if (dart.library.js_interop) 'network_audit_web.dart' as impl;

@immutable
class NetworkEvent {
  const NetworkEvent({required this.at, required this.url, required this.kind, required this.external, required this.duringAnalysis});

  final DateTime at;
  final String url;

  /// Tipo informado pela plataforma (`script`, `fetch`, `http`...).
  final String kind;

  /// Destino fora do próprio site/app.
  final bool external;
  final bool duringAnalysis;

  Map<String, Object> toJson() => {
        'at': at.toUtc().toIso8601String(),
        'url': url,
        'kind': kind,
        'external': external,
        'during_analysis': duringAnalysis,
      };
}

class NetworkAudit extends ChangeNotifier {
  NetworkAudit._();

  static final instance = NetworkAudit._();

  final List<NetworkEvent> events = [];
  final DateTime startedAt = DateTime.now();
  int _analysesRunning = 0;
  bool _started = false;

  /// Começa a observar (chamado uma vez em `main`).
  void start() {
    if (_started) return;
    _started = true;
    impl.startNetworkAudit(this);
  }

  void record(String url, String kind) {
    events.add(NetworkEvent(
      at: DateTime.now(),
      url: url,
      kind: kind,
      external: impl.isExternal(url),
      duringAnalysis: _analysesRunning > 0,
    ));
    notifyListeners();
  }

  /// Marca o início/fim de uma análise (importação ou comparação).
  void beginAnalysis() => _analysesRunning++;
  void endAnalysis() => _analysesRunning = (_analysesRunning - 1).clamp(0, 1 << 30);

  int get externalCount => events.where((e) => e.external).length;
  int get externalDuringAnalysis => events.where((e) => e.external && e.duringAnalysis).length;
  int get ownSiteCount => events.length - externalCount;

  Map<String, Object> toJson() => {
        'started_at': startedAt.toUtc().toIso8601String(),
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'requests_total': events.length,
        'requests_external': externalCount,
        'external_during_analysis': externalDuringAnalysis,
        'events': [for (final e in events) e.toJson()],
      };
}

/// Executa `body` marcando que há uma análise em andamento.
Future<T> auditedAnalysis<T>(Future<T> Function() body) async {
  NetworkAudit.instance.beginAnalysis();
  try {
    return await body();
  } finally {
    NetworkAudit.instance.endAnalysis();
  }
}
