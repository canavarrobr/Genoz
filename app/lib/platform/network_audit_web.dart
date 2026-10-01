// Auditoria de rede no navegador: o próprio navegador informa cada recurso
// buscado pela página (PerformanceObserver, tipo "resource"), inclusive os que
// foram carregados antes do app iniciar (buffered).

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'network_audit.dart';

void startNetworkAudit(NetworkAudit audit) {
  void handle(web.PerformanceObserverEntryList list, web.PerformanceObserver _) {
    final entries = list.getEntries().toDart;
    for (final e in entries) {
      final r = e as web.PerformanceResourceTiming;
      audit.record(r.name, r.initiatorType);
    }
  }

  web.PerformanceObserver(handle.toJS).observe(web.PerformanceObserverInit(type: 'resource', buffered: true));
}

/// Externo = fora do próprio site. `blob:` e `data:` são locais.
bool isExternal(String url) {
  if (url.startsWith('blob:') || url.startsWith('data:')) return false;
  return !url.startsWith(web.window.location.origin);
}
