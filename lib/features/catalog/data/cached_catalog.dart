import 'dart:math' as math;

import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';

import '../domain/entities/catalog.dart';
import '../domain/repositories/catalog_repository.dart';
import 'catalog_json.dart';
import 'catalog_remote_data_source.dart';

class CachedCatalog(
  final LocalStorage _store,
  final Connection _connection,
  final CatalogRemoteDataSource _remote,
) implements CatalogRepository {
  static const _key = 'catalog_v1';

  Future<_CatalogSnapshot>? _loading;
  _CatalogSnapshot? _snapshot;

  Future<_CatalogSnapshot> _catalog({bool refresh = false}) async {
    if (!_connection.online) return _readCache();
    final loading = _loading;
    if (loading != null) return loading;
    final snapshot = _snapshot;
    if (!refresh && snapshot != null) return snapshot;
    return _loading = _refresh();
  }

  Future<_CatalogSnapshot> _readCache() async {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot;
    final data = await _store.read(_key);
    if (data == null) throw const OfflineException();
    return _snapshot ??= .fromJson(data);
  }

  Future<_CatalogSnapshot> _refresh() async {
    try {
      final data = await _remote.fetchCatalog();
      final snapshot = _CatalogSnapshot.fromJson(data);
      await _store.write(_key, data);
      return _snapshot = snapshot;
    } on OfflineException {
      return await _readCache();
    } finally {
      _loading = null;
    }
  }

  @override
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
    bool refresh = false,
  }) async {
    final catalog = await _catalog(refresh: refresh);
    final words = query.search.trim().toLowerCase().split(RegExp(r'\s+'));
    final categoryProducts = catalog.products.where(
      (product) =>
          query.category == null || product.categoryId == query.category,
    );
    final brands = <String>{};
    final matching = <Product>[];
    for (final product in categoryProducts) {
      brands.add(product.brand);
      if ((query.brand == null || product.brand == query.brand) &&
          (!query.deals || product.discountPercent > 0) &&
          words.every(product.title.toLowerCase().contains)) {
        matching.add(product);
      }
    }

    final start = math.min((page - 1) * pageSize, matching.length);
    final end = math.min(start + pageSize, matching.length);
    return (
      products: List<Product>.unmodifiable(matching.getRange(start, end)),
      total: matching.length,
      categories: catalog.categories,
      brands: List<String>.unmodifiable(brands.toList()..sort()),
    );
  }

  @override
  Future<Product> detail(String id) async =>
      (await _catalog()).products.firstWhere((product) => product.id == id);
}

class const _CatalogSnapshot(
  final List<Category> categories,
  final List<Product> products,
) {
  factory fromJson(Map<String, dynamic> data) => .new(
    .unmodifiable(
      (data['categories'] as List).map((json) => decodeCategory(json)),
    ),
    .unmodifiable(
      (data['products'] as List).map((json) => decodeProduct(json)),
    ),
  );
}
