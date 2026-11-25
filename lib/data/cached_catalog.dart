import 'dart:math' as math;

import '../domain/catalog.dart';
import '../domain/connection.dart';
import '../domain/shopping.dart';
import 'local_store.dart';
import 'mock_market.dart';

class CachedCatalog implements CatalogRepository {
  CachedCatalog(this.market, this.store, this.connection);
  static const _key = 'catalog_v1';

  final MockMarket market;
  final LocalStore store;
  final Connection connection;
  Future<_CatalogSnapshot>? _loading;
  _CatalogSnapshot? _snapshot;
  DateTime? _updatedAt;

  Future<_CatalogSnapshot> _catalog() async {
    if (!connection.online) {
      final cached = _snapshot ?? await _readCache();
      if (cached == null) throw const OfflineException();
      return _snapshot = cached;
    }
    final updatedAt = _updatedAt;
    if (_snapshot != null &&
        updatedAt != null &&
        DateTime.now().difference(updatedAt) < const Duration(seconds: 1)) {
      return _snapshot!;
    }
    final request = _loading ??= _refresh();
    try {
      return await request;
    } finally {
      if (identical(_loading, request)) _loading = null;
    }
  }

  Future<_CatalogSnapshot?> _readCache() async {
    final data = await store.read(_key);
    return data == null ? null : _CatalogSnapshot.fromJson(data);
  }

  Future<_CatalogSnapshot> _refresh() async {
    try {
      final data = await market.catalog();
      final snapshot = _CatalogSnapshot.fromJson(data);
      await store.write(_key, data);
      _updatedAt = DateTime.now();
      return _snapshot = snapshot;
    } on OfflineException {
      final cached = _snapshot ?? await _readCache();
      if (cached == null) rethrow;
      return _snapshot = cached;
    }
  }

  @override
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  }) async {
    final catalog = await _catalog();
    final words = query.search.trim().toLowerCase().split(RegExp(r'\s+'));
    final matches = catalog.products
        .where(
          (product) =>
              (query.category == null ||
                  product.categoryId == query.category) &&
              (query.brand == null || product.brand == query.brand) &&
              (!query.deals || product.discountPercent > 0) &&
              words.every(product.title.toLowerCase().contains),
        )
        .toList();
    final start = math.min((page - 1) * pageSize, matches.length);
    final end = math.min(start + pageSize, matches.length);
    return (
      products: List<Product>.unmodifiable(matches.getRange(start, end)),
      total: matches.length,
    );
  }

  @override
  Future<CatalogFilters> filters(String? category) async {
    final catalog = await _catalog();
    final brands =
        catalog.products
            .where(
              (product) => category == null || product.categoryId == category,
            )
            .map((product) => product.brand)
            .toSet()
            .toList()
          ..sort();
    return (
      categories: catalog.categories,
      brands: List<String>.unmodifiable(brands),
    );
  }

  @override
  Future<Product> detail(String id) async =>
      (await _catalog()).products.firstWhere((product) => product.id == id);
}

class _CatalogSnapshot {
  const _CatalogSnapshot(this.categories, this.products);
  final List<Category> categories;
  final List<Product> products;

  factory _CatalogSnapshot.fromJson(Map<String, dynamic> data) =>
      _CatalogSnapshot(
        List.unmodifiable(
          (data['categories'] as List).map((json) => Category.fromJson(json)),
        ),
        List.unmodifiable(
          (data['products'] as List).map((json) => Product.fromJson(json)),
        ),
      );
}
