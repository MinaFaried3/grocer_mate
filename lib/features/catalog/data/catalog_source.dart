import '../domain/entities/catalog.dart';
import 'catalog_models.dart';

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
}
