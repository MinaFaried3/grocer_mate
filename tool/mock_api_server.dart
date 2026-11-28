import 'dart:convert';
import 'dart:io';

import 'package:grocer_mate/core/network/endpoint_exception.dart';
import 'package:grocer_mate/core/network/endpoints.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:grocer_mate/core/storage/market_store.dart';
import 'package:grocer_mate/features/catalog/data/sources/mock_catalog_remote_ds.dart';
import 'package:grocer_mate/features/shopping/data/sources/mock_checkout_remote_ds.dart';
import 'package:grocer_mate/features/shopping/domain/entities/checkout_settings.dart';

typedef _Sources = ({
  MockCatalogRemoteDS catalog,
  MockCheckoutRemoteDS checkout,
});

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.single);
  Future<String> loadMockAsset(String path) => File(path).readAsString();
  final store = MarketStore(_MemoryStorage());
  final catalog = MockCatalogRemoteDS(loadMockAsset, store.readAvailability);
  final sources = (
    catalog: catalog,
    checkout: MockCheckoutRemoteDS(
      loadMockAsset,
      store,
      catalog,
      settings: CheckoutSettings(
        scenario: Platform.environment['MOCK_CHECKOUT_SCENARIO'] ?? 'normal',
      ),
    ),
  );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('GrocerMate demo API at http://127.0.0.1:${server.port}');
  await for (final request in server) {
    _handle(request, sources);
  }
}

Future<void> _handle(HttpRequest request, _Sources sources) async {
  //------------ Configure Cross-Origin Headers ---------------
  final response = request.response;
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type, Idempotency-Key');

  //------------ Handle Preflight and Return JSON ---------------
  try {
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      return;
    }
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(await _route(request, sources)));
  } on EndpointException catch (error) {
    response.statusCode = error.statusCode;
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

Future<Object> _route(HttpRequest request, _Sources sources) async {
  //------------ Normalize Request Parameters ---------------
  final segments = request.uri.pathSegments
      .map((segment) => segment.toLowerCase())
      .toList();
  final query = request.uri.queryParameters.map(
    (key, value) => MapEntry(key.toLowerCase(), value.trim()),
  );
  return switch ((request.method, segments)) {
    //------------ Catalog and Checkout Reads ---------------
    ('GET', [Endpoints.categories]) => sources.catalog.categoriesPayload(),
    ('GET', [Endpoints.flags]) => sources.checkout.flags(),
    ('GET', [Endpoints.brands]) => sources.catalog.brandsPayload(
      query['categoryid'],
    ),
    ('GET', [Endpoints.products]) => sources.catalog.productsPayload(
      category: query['category'],
      brand: query['brand'],
      search: query['search'],
      page: int.parse(query['page'] ?? '1'),
      pageSize: int.parse(query['pagesize'] ?? '10'),
    ),
    ('GET', [Endpoints.product, final id]) => sources.catalog.productPayload(
      id,
    ),
    ('GET', [Endpoints.inventory, final id]) => sources.catalog.inventory(id),
    ('GET', [Endpoints.priceHistory, final id]) => sources.catalog.priceHistory(
      id,
    ),
    ('GET', [Endpoints.suggest]) => sources.catalog.suggestions(query['q']),
    ('GET', [Endpoints.stockCheck]) => sources.catalog.checkStock(query['ids']),
    ('GET', [Endpoints.dealsOfDay]) => sources.catalog.dealsOfDayPayload(),
    ('GET', [Endpoints.orders, final id]) => sources.checkout.order(id),

    //------------ Purchase and Sync Writes ---------------
    ('POST', [Endpoints.purchase]) => sources.checkout.purchasePayload(
      await _readBody(request),
      key: request.headers.value('Idempotency-Key'),
    ),
    ('POST', [Endpoints.sync]) => sources.checkout.sync(
      await _readBody(request),
    ),
    _ => throw const EndpointException(
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
