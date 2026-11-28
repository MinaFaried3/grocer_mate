import 'dart:math' as math;

import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';

import '../domain/entities/catalog.dart';
import '../domain/repositories/catalog_repository.dart';
import 'catalog_source.dart';

class CachedCatalog(
  final LocalStorage _store,
  final bool Function() _isOnline,
  final CatalogSource _source,
) implements CatalogRepository {
  static const _key = 'catalog_v2';
  Future<_CatalogCache>? _cache;
  Future<_CatalogCache> get _saved => _cache ??= _load();

  Future<_CatalogCache> _load() async {
    final json = await _store.read(_key);
    if (json != null) return _CatalogCache.fromJson(json);

    final legacy = await _store.read('catalog_v1');
    if (legacy == null) return _CatalogCache();
    final cache = _CatalogCache.fromJson(legacy);
    cache.details.addAll(cache.products);
    return cache;
  }

  @override
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
    bool refresh = false,
  }) async {
    final cache = await _saved;
    if (!_isOnline()) return _offlinePage(cache, query, page, pageSize);

    final brandKey = query.category ?? '';
    try {
      final metadata = (
        refresh || cache.categories == null
            ? _source.categories()
            : Future.value(cache.categories!),
        refresh || !cache.brands.containsKey(brandKey)
            ? _source.brands(query.category)
            : Future.value(cache.brands[brandKey]!),
        query.deals
            ? _dealsPage(cache, query, page, pageSize)
            : _source.products(query, page: page, pageSize: pageSize),
      );
      final (categories, brands, result) = await metadata.wait;
      cache.categories = categories;
      cache.brands[brandKey] = brands;
      if (!query.deals) {
        for (final product in result.products) {
          cache.products[product.id] = product;
        }
      }
      await _store.write(_key, cache.toJson());
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
    _CatalogCache cache,
    CatalogQuery query,
    int page,
    int pageSize,
  ) async {
    final deals = await _source.dealsOfDay();
    final now = DateTime.now().toUtc();
    final offers = <String, _Deal>{
      for (final item in deals.items)
        requireText(item.productId, 'productId'): (
          price: requireCents(item.dealPrice, 'dealPrice'),
          endsAt: DateTime.parse(item.endsAt),
        ),
    };
    final prices = Map.of(offers)
      ..removeWhere((_, deal) => !deal.endsAt.isAfter(now));
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
        if (matches.length >= prices.length ||
            result.products.isEmpty ||
            consumed >= result.total) {
          break;
        }
      }
    }
    cache.deals = offers;
    return (products: _page(matches, page, pageSize), total: matches.length);
  }

  CatalogPage _offlinePage(
    _CatalogCache cache,
    CatalogQuery query,
    int page,
    int pageSize,
  ) {
    final categories = cache.categories;
    if (categories == null) throw const OfflineException();
    final words = query.search.trim().toLowerCase().split(RegExp(r'\s+'));
    final now = DateTime.now().toUtc();
    final prices = {
      for (final MapEntry(:key, :value) in cache.deals.entries)
        if (value.endsAt.isAfter(now)) key: value.price,
    };
    final categoryProducts = cache.products.values.where(
      (product) =>
          query.category == null ||
          product.categoryId.toLowerCase() == query.category!.toLowerCase(),
    );
    final matching = [
      for (final product in categoryProducts)
        if ((query.brand == null ||
                product.brand.toLowerCase() == query.brand!.toLowerCase()) &&
            (!query.deals || prices.containsKey(product.id)) &&
            words.every(product.title.toLowerCase().contains))
          query.deals
              ? _withCurrentOffer(product, product, price: prices[product.id])
              : product,
    ];
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
    final cache = await _saved;
    final summary = cache.products[id];
    if (_isOnline()) {
      try {
        final product = await _source.detail(id, summary: summary);
        cache.details[id] = product;
        if (product.categoryId.isNotEmpty) cache.products[id] = product;
        await _store.write(_key, cache.toJson());
        return _withActiveDeal(product, cache.deals[id]);
      } on OfflineException {
        // Use details or the summary already downloaded for this product.
      }
    }
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

typedef _Deal = ({int price, DateTime endsAt});

Product _withActiveDeal(Product product, _Deal? deal) =>
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

class _CatalogCache {
  List<Category>? categories;
  final brands = <String, List<String>>{};
  final products = <String, Product>{};
  final details = <String, Product>{};
  Map<String, _Deal> deals = {};

  _CatalogCache();

  _CatalogCache.fromJson(Json json) {
    if (json['categories'] case final List saved) {
      categories = [for (final item in saved) Category.fromJson(item as Json)];
    }
    for (final entry in (json['brands'] as Map? ?? {}).entries) {
      brands[entry.key] = (entry.value as List).cast<String>();
    }
    for (final item in json['products'] as List? ?? []) {
      final product = Product.fromJson(item as Json);
      products[product.id] = product;
    }
    for (final item in json['details'] as List? ?? []) {
      final product = Product.fromJson(item as Json);
      details[product.id] = product;
    }
    for (final Json item in json['deals'] as List? ?? []) {
      deals[readText(item, 'id')] = (
        price: readInt(item, 'price'),
        endsAt: DateTime.parse(readText(item, 'endsAt')),
      );
    }
  }

  Json toJson() => {
    'categories': categories?.map((item) => item.toJson()).toList(),
    'brands': brands,
    'products': [for (final item in products.values) item.toJson()],
    'details': [for (final item in details.values) item.toJson()],
    'deals': [
      for (final MapEntry(:key, :value) in deals.entries)
        {
          'id': key,
          'price': value.price,
          'endsAt': value.endsAt.toIso8601String(),
        },
    ],
  };
}
