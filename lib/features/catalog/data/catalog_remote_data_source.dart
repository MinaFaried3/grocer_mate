import 'package:grocer_mate/core/network/market_api.dart';

import '../domain/entities/catalog.dart';
import 'catalog_json.dart';

class const CatalogRemoteDataSource(final MarketApi _api) {
  Future<List<Category>> categories() async => [
    for (final json in await _api.get('categories') as List)
      decodeCategory(json),
  ];

  Future<List<String>> brands(String? category) async {
    final json = await _api.get(
      'brands',
      query: category == null ? null : {'categoryId': category},
    ) as JsonObject;
    return {
      for (final names in category == null ? json.values : [json[category]])
        if (names is List) ...names.cast<String>(),
    }.toList()..sort();
  }

  Future<({List<Product> products, int total})> products(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  }) async {
    final json = await _api.get(
      'products',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        'category': ?query.category,
        'brand': ?query.brand,
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      },
    ) as JsonObject;
    return (
      products: [for (final item in json['data']) decodeApiProduct(item)],
      total: json['total'] as int,
    );
  }

  Future<Product> detail(String id, {Product? summary}) async =>
      decodeApiProduct(await _api.get('product', id: id), summary: summary);

  Future<JsonObject> priceHistory(String id) async =>
      await _api.get('price-history', id: id) as JsonObject;

  Future<JsonObject> inventory(String id) async =>
      await _api.get('inventory', id: id) as JsonObject;

  Future<List<String>> suggestions(String input) async {
    final json = await _api.get('suggest', query: {'q': input}) as JsonObject;
    return List<String>.unmodifiable(json['suggestions']);
  }

  Future<JsonObject> dealsOfDay() async =>
      await _api.get('deals-of-day') as JsonObject;

  Future<JsonObject> checkStock(Iterable<String> ids) async =>
      await _api.get('stock-check', query: {'ids': ids.join(',')})
          as JsonObject;
}
