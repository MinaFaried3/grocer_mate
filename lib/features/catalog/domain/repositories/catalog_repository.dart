import '../entities/catalog.dart';

abstract interface class CatalogRepository {
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
    bool refresh = false,
  });
  Future<Product> detail(String id);
}
