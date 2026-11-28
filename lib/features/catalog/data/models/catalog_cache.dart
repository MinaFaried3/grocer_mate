import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/catalog.dart';

part 'catalog_cache.g.dart';

typedef CachedDeal = ({int price, DateTime endsAt});

@JsonSerializable(explicitToJson: true)
class CatalogCache {
  CatalogCache({
    this.categories,
    Map<String, List<String>>? brands,
    Map<String, Product>? products,
    Map<String, Product>? details,
    Map<String, CachedDeal>? deals,
  }) : brands = brands ?? {},
       products = products ?? {},
       details = details ?? {},
       deals = deals ?? {};

  List<Category>? categories;
  final Map<String, List<String>> brands;

  @JsonKey(fromJson: _productsById, toJson: _productList)
  final Map<String, Product> products;

  @JsonKey(fromJson: _productsById, toJson: _productList)
  final Map<String, Product> details;

  @JsonKey(fromJson: _dealsById, toJson: _dealList)
  Map<String, CachedDeal> deals;

  factory CatalogCache.fromJson(Json json) => _$CatalogCacheFromJson(json);

  Json toJson() => _$CatalogCacheToJson(this);

  static Map<String, Product> _productsById(List<dynamic>? items) {
    final products = <String, Product>{};
    for (final item in items ?? const []) {
      final product = Product.fromJson(item as Json);
      products[product.id] = product;
    }
    return products;
  }

  static List<Json> _productList(Map<String, Product> products) => [
    for (final product in products.values) product.toJson(),
  ];

  static Map<String, CachedDeal> _dealsById(List<dynamic>? items) => {
    for (final Json item in items ?? const [])
      readText(item, 'id'): (
        price: readInt(item, 'price'),
        endsAt: DateTime.parse(readText(item, 'endsAt')),
      ),
  };

  static List<Json> _dealList(Map<String, CachedDeal> deals) => [
    for (final MapEntry(:key, :value) in deals.entries)
      {
        'id': key,
        'price': value.price,
        'endsAt': value.endsAt.toIso8601String(),
      },
  ];
}
