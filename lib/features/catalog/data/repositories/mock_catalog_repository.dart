import 'dart:math' as math;

import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/catalog_cache.dart';
import '../sources/catalog_cache_source.dart';
import '../sources/catalog_source.dart';

class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository(this._cacheSource, this._isOnline, this._source);

  final CatalogCacheSource _cacheSource;
  final bool Function() _isOnline;
  final CatalogSource _source;

  Future<CatalogCache>? _cache;
  Future<CatalogCache> get _saved => _cache ??= _load();

  Future<CatalogCache> _load() async {
    try {
      return await _cacheSource.read() ?? CatalogCache();
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }

  @override
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
    bool refresh = false,
  }) async {
    //------------ Offline Fallback ---------------
    final cache = await _saved;
    if (!_isOnline()) return _offlinePage(cache, query, page, pageSize);

    final brandKey = query.category ?? '';
    try {
      //------------ Categories and Brands ---------------
      final cachedCategories = cache.categories;
      final categoriesRequest = refresh || cachedCategories == null
          ? _source.categories()
          : Future.value(cachedCategories);

      final cachedBrands = cache.brands[brandKey];
      final brandsRequest = refresh || cachedBrands == null
          ? _source.brands(query.category)
          : Future.value(cachedBrands);

      //------------ Product Page ---------------
      final productsRequest = query.deals
          ? _dealsPage(cache, query, page, pageSize)
          : _source.products(query, page: page, pageSize: pageSize);
      final (categories, brands, result) = await (
        categoriesRequest,
        brandsRequest,
        productsRequest,
      ).wait;

      //------------ Save Results ---------------
      cache.categories = categories;
      cache.brands[brandKey] = brands;
      if (!query.deals) {
        for (final product in result.products) {
          cache.products[product.id] = product;
        }
      }
      await _cacheSource.write(cache);
      return (
        products: List<Product>.unmodifiable(result.products),
        total: result.total,
        categories: List<Category>.unmodifiable(categories),
        brands: List<String>.unmodifiable(brands),
      );
    } on ParallelWaitError catch (error) {
      final errors = error.errors;
      final failure = errors.$1 ?? errors.$2 ?? errors.$3;
      if (failure?.error is OfflineException) {
        return _offlinePage(cache, query, page, pageSize);
      }
      Error.throwWithStackTrace(failure!.error, failure.stackTrace);
    }
  }

  Future<({List<Product> products, int total})> _dealsPage(
    CatalogCache cache,
    CatalogQuery query,
    int page,
    int pageSize,
  ) async {
    //------------ Load Active Offers ---------------
    final deals = await _source.dealsOfDay();
    final now = DateTime.now().toUtc();
    final offers = <String, CachedDeal>{
      for (final item in deals.items)
        requireText(item.productId, 'productId'): (
          price: requireCents(item.dealPrice, 'dealPrice'),
          endsAt: DateTime.parse(item.endsAt),
        ),
    };
    final prices = Map.of(offers)
      ..removeWhere((_, deal) => !deal.endsAt.isAfter(now));

    //------------ Match Offers to Products ---------------
    final matches = <Product>[];
    if (prices.isNotEmpty) {
      const batchSize = 50;
      var consumed = 0;
      for (var next = 1; ; next++) {
        final result = await _source.products(
          query,
          page: next,
          pageSize: batchSize,
        );
        for (final product in result.products) {
          if (prices[product.id] case final deal?) {
            matches.add(_withCurrentOffer(product, product, price: deal.price));
            cache.products[product.id] = product;
          }
        }
        consumed += result.products.length;
        // Stop scanning pages once all deals are matched or all products are consumed.
        final foundAllDeals = matches.length >= prices.length;
        final reachedEndOfCatalog =
            result.products.isEmpty || consumed >= result.total;
        if (foundAllDeals || reachedEndOfCatalog) {
          break;
        }
      }
    }

    //------------ Cache Offers and Return Page ---------------
    cache.deals = offers;
    return (products: _page(matches, page, pageSize), total: matches.length);
  }

  CatalogPage _offlinePage(
    CatalogCache cache,
    CatalogQuery query,
    int page,
    int pageSize,
  ) {
    //------------ Read Available Offline Data ---------------
    final categories = cache.categories;
    if (categories == null) throw const OfflineException();
    final words = query.search.trim().toLowerCase().split(RegExp(r'\s+'));
    final now = DateTime.now().toUtc();
    final prices = {
      for (final MapEntry(:key, :value) in cache.deals.entries)
        if (value.endsAt.isAfter(now)) key: value.price,
    };

    //------------ Apply Catalog Filters ---------------
    final categoryProducts = cache.products.values.where(
      (product) =>
          query.category == null ||
          product.categoryId.toLowerCase() == query.category!.toLowerCase(),
    );
    final matching = <Product>[];
    for (final product in categoryProducts) {
      // Match brand filter when provided.
      final matchesBrand =
          query.brand == null ||
          product.brand.toLowerCase() == query.brand!.toLowerCase();

      // Require an active offer when the deals filter is selected.
      final matchesDeals = !query.deals || prices.containsKey(product.id);

      // Match every search term against the product title.
      final matchesSearch = words.every(product.title.toLowerCase().contains);

      if (matchesBrand && matchesDeals && matchesSearch) {
        matching.add(
          query.deals
              ? _withCurrentOffer(product, product, price: prices[product.id])
              : product,
        );
      }
    }

    //------------ Build Offline Page ---------------
    return (
      products: _page(matching, page, pageSize),
      total: matching.length,
      categories: List<Category>.unmodifiable(categories),
      brands: List.unmodifiable(
        cache.brands[query.category ?? ''] ??
            (categoryProducts.map((product) => product.brand).toSet().toList()
              ..sort()),
      ),
    );
  }

  @override
  Future<Product> detail(String id) async {
    //------------ Fetch and Cache Product Details ---------------
    final cache = await _saved;
    final summary = cache.products[id];
    if (_isOnline()) {
      try {
        final product = await _source.detail(id, summary: summary);
        cache.details[id] = product;
        if (product.categoryId.isNotEmpty) cache.products[id] = product;
        await _cacheSource.write(cache);
        return _withActiveDeal(product, cache.deals[id]);
      } on OfflineException {
        // Use details or the summary already downloaded for this product.
      }
    }

    //------------ Build Details from the Cache ---------------
    final detail = cache.details[id];
    final product = switch ((detail, summary)) {
      (final detail?, final summary?) => _withCurrentOffer(detail, summary),
      (final detail?, null) => detail,
      (null, final summary?) => summary,
      _ => throw const OfflineException(),
    };
    return _withActiveDeal(product, cache.deals[id]);
  }
}

Product _withActiveDeal(Product product, CachedDeal? deal) =>
    deal != null && deal.endsAt.isAfter(DateTime.now().toUtc())
    ? _withCurrentOffer(product, product, price: deal.price)
    : product;

List<Product> _page(List<Product> products, int page, int pageSize) {
  final start = math.min((page - 1) * pageSize, products.length);
  return List.unmodifiable(
    products.getRange(start, math.min(start + pageSize, products.length)),
  );
}

Product _withCurrentOffer(Product detail, Product current, {int? price}) =>
    Product(
      id: detail.id,
      title: detail.title,
      brand: detail.brand,
      categoryId: current.categoryId,
      price: price ?? current.price,
      originalPrice: current.originalPrice,
      stock: current.stock,
      rating: current.rating,
      description: detail.description,
      images: detail.images,
      badges: current.badges,
      nutrition: detail.nutrition,
      allergens: detail.allergens,
      related: detail.related,
    );
