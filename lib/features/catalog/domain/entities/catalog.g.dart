// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon': instance.icon,
};

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  title: json['title'] as String,
  brand: json['brand'] as String,
  categoryId: json['categoryId'] as String,
  price: (json['price'] as num).toInt(),
  originalPrice: (json['originalPrice'] as num).toInt(),
  stock: (json['stock'] as num).toInt(),
  rating: (json['rating'] as num).toDouble(),
  description: json['description'] as String,
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  badges: (json['badges'] as List<dynamic>).map((e) => e as String).toList(),
  nutrition: Map<String, num>.from(json['nutrition'] as Map),
  allergens: (json['allergens'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  related:
      (json['related'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'brand': instance.brand,
  'categoryId': instance.categoryId,
  'price': instance.price,
  'originalPrice': instance.originalPrice,
  'stock': instance.stock,
  'rating': instance.rating,
  'description': instance.description,
  'images': instance.images,
  'badges': instance.badges,
  'nutrition': instance.nutrition,
  'allergens': instance.allergens,
  'related': instance.related,
};
