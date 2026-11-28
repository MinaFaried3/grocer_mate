import 'package:grocer_mate/core/mock/mock_market.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';

import '../domain/entities/catalog.dart';
import 'cached_catalog.dart';
import 'catalog_source.dart';
import 'models/deals_response.dart';
import 'models/product_response.dart';

class MockCatalogRepository extends CachedCatalog {
  MockCatalogRepository(
    LocalStorage storage,
    bool Function() isOnline,
    MockMarket market,
  ) : super(storage, isOnline, _MockCatalogSource(market));
}

class const _MockCatalogSource(final MockMarket _market)
    implements CatalogSource {
  @override
  Future<List<Category>> categories() async =>
      CatalogSource.parseCategories(await _market.categories());

  @override
  Future<List<String>> brands(String? category) async =>
      CatalogSource.parseBrands(await _market.brands(category), category);

  @override
  Future<({List<Product> products, int total})> products(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  }) async => CatalogSource.parseProductPage(
    await _market.products(
      category: query.category,
      brand: query.brand,
      search: query.search,
      page: page,
      pageSize: pageSize,
    ),
  );

  @override
  Future<Product> detail(String id, {Product? summary}) async =>
      ProductResponse.fromJson(await _market.product(id))
          .toProduct(summary: summary);

  @override
  Future<DealsResponse> dealsOfDay() async =>
      DealsResponse.fromJson(await _market.dealsOfDay());
}
