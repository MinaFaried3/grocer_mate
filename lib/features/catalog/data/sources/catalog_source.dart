import 'package:grocer_mate/core/network/page_response.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../../domain/entities/catalog.dart';
import '../models/deals_response.dart';
import '../models/product_response.dart';

abstract interface class CatalogSource {
  Future<List<Category>> categories();
  Future<List<String>> brands(String? category);
  Future<({List<Product> products, int total})> products(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  });
  Future<Product> detail(String id, {Product? summary});
  Future<DealsResponse> dealsOfDay();

  static List<Category> parseCategories(List<dynamic> items) => [
    for (final item in items) Category.fromJson(item as Json),
  ];

  static List<String> parseBrands(Json json, String? category) => {
    for (final names in category == null ? json.values : [json[category]])
      if (names is List) ...names.cast<String>(),
  }.toList()..sort();

  static ({List<Product> products, int total}) parseProductPage(Json json) {
    final page = PageResponse<ProductResponse>.fromJson(
      json,
      (item) => ProductResponse.fromJson(item as Json),
    );
    return (
      products: [for (final item in page.data) item.toProduct()],
      total: page.total,
    );
  }
}
