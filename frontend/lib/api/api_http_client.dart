import 'dart:async';

import 'package:http/http.dart' as http;

class ApiHttpClient extends http.BaseClient {
  ApiHttpClient({
    http.Client? inner,
    this.requestTimeout = const Duration(seconds: 30),
    this.onUnauthorized,
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration requestTimeout;
  final void Function()? onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request).timeout(requestTimeout);

    if (response.statusCode == 401 &&
        request.headers.containsKey('Authorization')) {
      onUnauthorized?.call();
    }

    return http.StreamedResponse(
      response.stream.timeout(requestTimeout),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
