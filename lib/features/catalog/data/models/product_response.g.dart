// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
