import 'package:grocer_mate/core/network/endpoints.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/catalog.dart';
import 'catalog_source.dart';
import 'models/deals_response.dart';
import 'models/inventory_response.dart';
import 'models/price_history_response.dart';
import 'models/product_response.dart';
import 'models/stock_response.dart';
import 'models/suggestions_response.dart';

class const CatalogRemoteDataSource(final MarketApi _api)
    implements CatalogSource {
  @override
  Future<List<Category>> categories() async => CatalogSource.parseCategories(
    await _api.get<List<dynamic>>(Endpoints.categories),
  );

  @override
  Future<List<String>> brands(String? category) async =>
      CatalogSource.parseBrands(
        await _api.get<Json>(
          Endpoints.brands,
          query: category == null ? null : {'categoryId': category},
        ),
        category,
      );

  @override
  Future<({List<Product> products, int total})> products(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  }) async => CatalogSource.parseProductPage(
    await _api.get<Json>(
      Endpoints.products,
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
      ProductResponse.fromJson(await _api.get<Json>(Endpoints.product, id: id))
          .toProduct(summary: summary);

  Future<PriceHistoryResponse> priceHistory(String id) async =>
      PriceHistoryResponse.fromJson(
        await _api.get<Json>(Endpoints.priceHistory, id: id),
      );

  Future<InventoryResponse> inventory(String id) async =>
      InventoryResponse.fromJson(
        await _api.get<Json>(Endpoints.inventory, id: id),
      );

  Future<List<String>> suggestions(String input) async {
    final response = SuggestionsResponse.fromJson(
      await _api.get<Json>(Endpoints.suggest, query: {'q': input}),
    );
    return List<String>.unmodifiable(response.suggestions);
  }

  @override
  Future<DealsResponse> dealsOfDay() async =>
      DealsResponse.fromJson(await _api.get<Json>(Endpoints.dealsOfDay));

  Future<StockResponse> checkStock(Iterable<String> ids) async =>
      StockResponse.fromJson(
        await _api.get<Json>(
          Endpoints.stockCheck,
          query: {'ids': ids.join(',')},
        ),
      );
}
