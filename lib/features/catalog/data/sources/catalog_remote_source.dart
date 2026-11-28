import '../../domain/entities/catalog.dart';
import '../models/deals_response.dart';

abstract interface class CatalogRemoteSource {
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
