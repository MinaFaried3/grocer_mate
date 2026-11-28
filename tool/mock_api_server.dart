import 'dart:io';

import 'package:grocer_mate/core/network/demo/demo_market_client.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.single);
  final client = DemoMarketClient(
    _MemoryStorage(),
    (path) => File(path).readAsString(),
    checkoutScenario:
        Platform.environment['MOCK_CHECKOUT_SCENARIO'] ?? 'normal',
  );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('GrocerMate demo API at http://127.0.0.1:${server.port}');
  await for (final request in server) {
    _handle(request, client);
  }
}

Future<void> _handle(HttpRequest request, DemoMarketClient client) async {
  final response = request.response;
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type, Idempotency-Key');
  try {
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      return;
    }
    final forwarded = http.Request(request.method, request.requestedUri)
      ..bodyBytes = await request.fold<List<int>>(
        [],
        (bytes, chunk) => bytes..addAll(chunk),
      );
    if (request.headers.value('Idempotency-Key') case final key?) {
      forwarded.headers['Idempotency-Key'] = key;
    }
    final result = await client.send(forwarded);
    response.statusCode = result.statusCode;
    response.headers.set(
      HttpHeaders.contentTypeHeader,
      result.headers['content-type']!,
    );
    await response.addStream(result.stream);
  } catch (error) {
    stderr.writeln(error);
    response.statusCode = HttpStatus.internalServerError;
  } finally {
    await response.close();
  }
}

class _MemoryStorage implements LocalStorage {
  final _values = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, Map<String, Object?> value) async =>
      _values[key] = value;
}
