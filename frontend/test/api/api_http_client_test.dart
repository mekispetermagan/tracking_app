import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/api/api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('reports unauthorized responses and preserves the response', () async {
    var unauthorizedCount = 0;
    final client = ApiHttpClient(
      inner: MockClient((_) async => http.Response('unauthorized', 401)),
      onUnauthorized: () => unauthorizedCount++,
    );

    final response = await client.get(
      Uri.parse('https://example.test/data'),
      headers: {'Authorization': 'Bearer token'},
    );

    expect(response.statusCode, 401);
    expect(response.body, 'unauthorized');
    expect(unauthorizedCount, 1);
    client.close();
  });

  test('ignores unauthorized responses to unauthenticated requests', () async {
    var unauthorizedCount = 0;
    final client = ApiHttpClient(
      inner: MockClient((_) async => http.Response('unauthorized', 401)),
      onUnauthorized: () => unauthorizedCount++,
    );

    await client.get(Uri.parse('https://example.test/public'));

    expect(unauthorizedCount, 0);
    client.close();
  });

  test('times out stalled requests and closes its owned client', () async {
    final inner = _ControllableClient();
    final client = ApiHttpClient(
      inner: inner,
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      client.get(Uri.parse('https://example.test/slow')),
      throwsA(isA<TimeoutException>()),
    );

    client.close();
    expect(inner.wasClosed, isTrue);
  });
}

class _ControllableClient extends http.BaseClient {
  final _response = Completer<http.StreamedResponse>();
  bool wasClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _response.future;
  }

  @override
  void close() {
    wasClosed = true;
  }
}
