// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogCache _$CatalogCacheFromJson(Map<String, dynamic> json) => CatalogCache(
  categories: (json['categories'] as List<dynamic>?)
      ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList(),
  brands: (json['brands'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
  products: CatalogCache._productsById(json['products'] as List?),
  details: CatalogCache._productsById(json['details'] as List?),
  deals: CatalogCache._dealsById(json['deals'] as List?),
);

Map<String, dynamic> _$CatalogCacheToJson(CatalogCache instance) =>
    <String, dynamic>{
      'categories': instance.categories?.map((e) => e.toJson()).toList(),
      'brands': instance.brands,
      'products': CatalogCache._productList(instance.products),
      'details': CatalogCache._productList(instance.details),
      'deals': CatalogCache._dealList(instance.deals),
    };
