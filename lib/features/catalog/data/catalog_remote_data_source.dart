import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/catalog.dart';
import 'catalog_json.dart';
import 'catalog_source.dart';

class const CatalogRemoteDataSource(final MarketApi _api)
    implements CatalogSource {
  @override
  Future<List<Category>> categories() async =>
      decodeCategories(await _api.get<List<dynamic>>('categories'));

  @override
  Future<List<String>> brands(String? category) async => decodeBrands(
    await _api.get<Json>(
      'brands',
      query: category == null ? null : {'categoryId': category},
    ),
    category,
  );

  @override
  Future<({List<Product> products, int total})> products(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  }) async => decodeProductPage(
    await _api.get<Json>(
      'products',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        'category': ?query.category,
        'brand': ?query.brand,
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      },
    ),
  );

  @override
  Future<Product> detail(String id, {Product? summary}) async =>
      decodeApiProduct(
        await _api.get<Json>('product', id: id),
        summary: summary,
      );

  Future<Json> priceHistory(String id) =>
      _api.get('price-history', id: id);

  Future<Json> inventory(String id) => _api.get('inventory', id: id);

  Future<List<String>> suggestions(String input) async {
    final json = await _api.get<Json>('suggest', query: {'q': input});
    return List<String>.unmodifiable(json['suggestions']);
  }

  @override
  Future<Json> dealsOfDay() => _api.get('deals-of-day');

  Future<Json> checkStock(Iterable<String> ids) =>
      _api.get('stock-check', query: {'ids': ids.join(',')});
}
