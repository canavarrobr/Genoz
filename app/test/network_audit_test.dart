import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/platform/network_audit.dart';

void main() {
  test('toda conexão HTTP feita pelo app é registrada, inclusive durante análises', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) => req.response
      ..write('ok')
      ..close());
    final audit = NetworkAudit.instance..start();
    final before = audit.events.length;

    final client = HttpClient();
    final res = await (await client.getUrl(Uri.parse('http://127.0.0.1:${server.port}/teste'))).close();
    await res.drain<void>();

    audit.beginAnalysis();
    final res2 = await (await client.getUrl(Uri.parse('http://127.0.0.1:${server.port}/durante'))).close();
    await res2.drain<void>();
    audit.endAnalysis();

    client.close();
    await server.close();

    final novos = audit.events.sublist(before);
    expect(novos.map((e) => Uri.parse(e.url).path), ['/teste', '/durante']);
    expect(novos.last.duringAnalysis, isTrue);
    expect(audit.externalDuringAnalysis, greaterThanOrEqualTo(1), reason: 'no app nativo toda conexão é externa');
    expect(audit.toJson()['requests_total'], audit.events.length);
  });
}
