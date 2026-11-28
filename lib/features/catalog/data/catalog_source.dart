import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/catalog.dart';

abstract interface class CatalogSource {
  Future<List<Category>> categories();
  Future<List<String>> brands(String? category);
  Future<({List<Product> products, int total})> products(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  });
  Future<Product> detail(String id, {Product? summary});
  Future<Json> dealsOfDay();
}
