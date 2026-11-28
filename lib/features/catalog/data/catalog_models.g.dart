// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryResponse _$CategoryResponseFromJson(Map<String, dynamic> json) =>
    CategoryResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );

Map<String, dynamic> _$CategoryResponseToJson(CategoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
    };

ProductResponse _$ProductResponseFromJson(
  Map<String, dynamic> json,
) => ProductResponse(
  id: json['id'] as String,
  title: json['title'] as String,
  brand: json['brand'] as String,
  price: json['price'] as num,
  originalPrice: json['originalPrice'] as num,
  stock: json['stock'] as num,
  categoryId: json['categoryId'] as String?,
  image: json['image'] as String?,
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  rating: (json['rating'] as num?)?.toDouble(),
  description: json['description'] as String?,
  badges: (json['badges'] as List<dynamic>?)?.map((e) => e as String).toList(),
  nutrition: (json['nutrition'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as num),
  ),
  allergens: (json['allergens'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  related: (json['related'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ProductResponseToJson(ProductResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'brand': instance.brand,
      'price': instance.price,
      'originalPrice': instance.originalPrice,
      'stock': instance.stock,
      'categoryId': ?instance.categoryId,
      'image': ?instance.image,
      'images': ?instance.images,
      'rating': ?instance.rating,
      'description': ?instance.description,
      'badges': ?instance.badges,
      'nutrition': ?instance.nutrition,
      'allergens': ?instance.allergens,
      'related': ?instance.related,
    };

DealsResponse _$DealsResponseFromJson(Map<String, dynamic> json) =>
    DealsResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => DealResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      date: json['date'] as String?,
    );

Map<String, dynamic> _$DealsResponseToJson(DealsResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'date': ?instance.date,
    };

DealResponse _$DealResponseFromJson(Map<String, dynamic> json) => DealResponse(
  productId: json['productId'] as String,
  dealPrice: json['dealPrice'] as num,
  endsAt: json['endsAt'] as String,
);

Map<String, dynamic> _$DealResponseToJson(DealResponse instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'dealPrice': instance.dealPrice,
      'endsAt': instance.endsAt,
    };

InventoryResponse _$InventoryResponseFromJson(Map<String, dynamic> json) =>
    InventoryResponse(
      productId: json['productId'] as String,
      stock: (json['stock'] as num).toInt(),
      backorderable: json['backorderable'] as bool?,
      etaDays: (json['etaDays'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InventoryResponseToJson(InventoryResponse instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'stock': instance.stock,
      'backorderable': ?instance.backorderable,
      'etaDays': ?instance.etaDays,
    };

PriceHistoryResponse _$PriceHistoryResponseFromJson(
  Map<String, dynamic> json,
) => PriceHistoryResponse(
  productId: json['productId'] as String,
  history: (json['history'] as List<dynamic>).map((e) => e as num).toList(),
);

Map<String, dynamic> _$PriceHistoryResponseToJson(
  PriceHistoryResponse instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'history': instance.history,
};

SuggestionsResponse _$SuggestionsResponseFromJson(Map<String, dynamic> json) =>
    SuggestionsResponse(
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      q: json['q'] as String?,
    );

Map<String, dynamic> _$SuggestionsResponseToJson(
  SuggestionsResponse instance,
) => <String, dynamic>{'suggestions': instance.suggestions, 'q': ?instance.q};

StockResponse _$StockResponseFromJson(Map<String, dynamic> json) =>
    StockResponse(
      stocks: (json['stocks'] as List<dynamic>)
          .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$StockResponseToJson(StockResponse instance) =>
    <String, dynamic>{
      'stocks': instance.stocks.map((e) => e.toJson()).toList(),
      'timestamp': ?instance.timestamp,
    };

StockItem _$StockItemFromJson(Map<String, dynamic> json) => StockItem(
  productId: json['productId'] as String,
  stock: (json['stock'] as num).toInt(),
);

Map<String, dynamic> _$StockItemToJson(StockItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'stock': instance.stock,
};
