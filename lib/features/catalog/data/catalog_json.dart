import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/catalog.dart';

Category decodeCategory(Map<String, dynamic> json) => Category(
  id: readText(json, 'id'),
  name: readText(json, 'name'),
  icon: readText(json, 'icon'),
);

Product decodeProduct(
  Map<String, dynamic> json, {
  bool allowMissingCategory = false,
}) {
  final images = json['images'];
  if (images is! List ||
      images.isEmpty ||
      images.any((image) => image is! String || image.trim().isEmpty)) {
    throw const FormatException('A product needs a usable image.');
  }
  final rating = json['rating'];
  if (rating is! num || !rating.isFinite || rating < 0 || rating > 5) {
    throw const FormatException('Product rating must be between 0 and 5.');
  }
  return Product(
    id: readText(json, 'id'),
    title: readText(json, 'title'),
    brand: readText(json, 'brand'),
    categoryId: allowMissingCategory && json['categoryId'] == ''
        ? ''
        : readText(json, 'categoryId'),
    price: readInt(json, 'price'),
    originalPrice: readInt(json, 'originalPrice'),
    stock: readInt(json, 'stock'),
    rating: rating.toDouble(),
    description: json['description'],
    images: .unmodifiable(images),
    badges: .unmodifiable(json['badges']),
    nutrition: .unmodifiable(json['nutrition'] ?? {}),
    allergens: .unmodifiable(json['allergens'] ?? []),
    related: .unmodifiable(json['related'] ?? []),
  );
}

Product decodeApiProduct(Map<String, dynamic> json, {Product? summary}) =>
    decodeProduct({
      ...json,
      'price': readCents(json, 'price'),
      'originalPrice': readCents(json, 'originalPrice'),
      'images': json['images'] ?? [json['image']],
      'rating': json['rating'] ?? summary?.rating ?? 0.0,
      'badges': json['badges'] ?? summary?.badges ?? const <String>[],
      'categoryId': json['categoryId'] ?? summary?.categoryId ?? '',
      'description': json['description'] ?? '',
    }, allowMissingCategory: true);

Map<String, dynamic> encodeCategory(Category category) => {
  'id': category.id,
  'name': category.name,
  'icon': category.icon,
};

Map<String, dynamic> encodeProduct(Product product) => {
  'id': product.id,
  'title': product.title,
  'brand': product.brand,
  'categoryId': product.categoryId,
  'price': product.price,
  'originalPrice': product.originalPrice,
  'stock': product.stock,
  'rating': product.rating,
  'description': product.description,
  'images': product.images,
  'badges': product.badges,
  'nutrition': product.nutrition,
  'allergens': product.allergens,
  'related': product.related,
};
List<Category> decodeCategories(List<dynamic> items) => [
  for (final item in items) decodeCategory(item),
];

List<String> decodeBrands(Json json, String? category) => {
  for (final names in category == null ? json.values : [json[category]])
    if (names is List) ...names.cast<String>(),
}.toList()..sort();

({List<Product> products, int total}) decodeProductPage(Json json) => (
  products: [for (final item in json['data']) decodeApiProduct(item)],
  total: json['total'] as int,
);
