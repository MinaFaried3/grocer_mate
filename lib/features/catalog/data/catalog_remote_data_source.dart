abstract interface class CatalogRemoteDataSource {
  Future<Map<String, dynamic>> fetchCatalog();
}
