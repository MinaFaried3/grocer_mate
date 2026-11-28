import 'dart:convert';
import 'dart:io';

import 'package:grocer_mate/core/mock/mock_market.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.single);
  final market = MockMarket(
    _MemoryStorage(),
    (path) => File(path).readAsString(),
    checkoutScenario:
        Platform.environment['MOCK_CHECKOUT_SCENARIO'] ?? 'normal',
  );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('GrocerMate demo API at http://127.0.0.1:${server.port}');
  await for (final request in server) {
    _handle(request, market);
  }
}

Future<void> _handle(HttpRequest request, MockMarket market) async {
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
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(await _route(request, market)));
  } on MockMarketException catch (error) {
    response.statusCode = error.code;
    response.write(jsonEncode({'error': error.message}));
  } on FormatException catch (error) {
    response.statusCode = HttpStatus.badRequest;
    response.write(jsonEncode({'error': error.message}));
  } catch (error) {
    stderr.writeln(error);
    response.statusCode = HttpStatus.internalServerError;
  } finally {
    await response.close();
  }
}

Future<Object> _route(HttpRequest request, MockMarket market) async {
  final segments = request.uri.pathSegments
      .map((segment) => segment.toLowerCase())
      .toList();
  final query = request.uri.queryParameters.map(
    (key, value) => MapEntry(key.toLowerCase(), value.trim()),
  );
  return switch ((request.method, segments)) {
    ('GET', ['categories']) => market.categories(),
    ('GET', ['flags']) => market.flags(),
    ('GET', ['brands']) => market.brands(query['categoryid']),
    ('GET', ['products']) => market.products(
      category: query['category'],
      brand: query['brand'],
      search: query['search'],
      page: int.parse(query['page'] ?? '1'),
      pageSize: int.parse(query['pagesize'] ?? '10'),
    ),
    ('GET', ['product', final id]) => market.product(id),
    ('GET', ['inventory', final id]) => market.inventory(id),
    ('GET', ['price-history', final id]) => market.priceHistory(id),
    ('GET', ['suggest']) => market.suggestions(query['q']),
    ('GET', ['stock-check']) => market.checkStock(query['ids']),
    ('GET', ['deals-of-day']) => market.dealsOfDay(),
    ('GET', ['orders', final id]) => market.order(id),
    ('POST', ['purchase']) => market.purchase(
      await _readBody(request),
      key: request.headers.value('Idempotency-Key'),
    ),
    ('POST', ['sync']) => market.sync(await _readBody(request)),
    _ => throw const MockMarketException(
      HttpStatus.notFound,
      'Endpoint not found.',
    ),
  };
}

Future<Json> _readBody(HttpRequest request) async {
  final body = jsonDecode(await utf8.decoder.bind(request).join());
  if (body is! Json) {
    throw const FormatException('Expected a JSON object.');
  }
  return body;
}

class _MemoryStorage implements LocalStorage {
  final _values = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, Map<String, Object?> value) async =>
      _values[key] = value;
}
