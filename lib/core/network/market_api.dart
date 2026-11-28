import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'connection.dart';

typedef JsonObject = Map<String, dynamic>;

class const ApiException(final int statusCode, final Object? body)
    implements Exception {
  @override
  String toString() => 'Market API returned HTTP $statusCode';
}

class MarketApi(final Uri _baseUrl, final http.Client _client) {
  Future<dynamic> get(
    String endpoint, {
    String? id,
    Map<String, String>? query,
  }) => _send('GET', endpoint, id: id, query: query);

  Future<JsonObject> post(
    String endpoint,
    JsonObject body, {
    String? idempotencyKey,
    Set<int> acceptedStatuses = const {},
  }) async => await _send(
    'POST',
    endpoint,
    body: body,
    idempotencyKey: idempotencyKey,
    acceptedStatuses: acceptedStatuses,
  ) as JsonObject;

  Future<dynamic> _send(
    String method,
    String endpoint, {
    String? id,
    Map<String, String>? query,
    JsonObject? body,
    String? idempotencyKey,
    Set<int> acceptedStatuses = const {},
  }) async {
    final uri = _baseUrl.replace(
      pathSegments: [
        ..._baseUrl.pathSegments.where((part) => part.isNotEmpty),
        endpoint,
        ?id,
      ],
      queryParameters: query,
    );
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    if (idempotencyKey != null) {
      request.headers['Idempotency-Key'] = idempotencyKey;
    }

    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    }

    final raw = utf8.decode(response.bodyBytes);
    final success = response.statusCode >= 200 && response.statusCode < 300;
    if (!success && !acceptedStatuses.contains(response.statusCode)) {
      throw ApiException(response.statusCode, raw);
    }
    return jsonDecode(raw);
  }

  void close() => _client.close();
}
