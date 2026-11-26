import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/catalog.dart';

Category decodeCategory(Map<String, dynamic> json) => Category(
  id: readText(json, 'id'),
  name: readText(json, 'name'),
  icon: readText(json, 'icon'),
);

Product decodeProduct(Map<String, dynamic> json) {
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
    categoryId: readText(json, 'categoryId'),
    price: readInt(json, 'price'),
    originalPrice: readInt(json, 'originalPrice'),
    stock: readInt(json, 'stock'),
    rating: rating.toDouble(),
    description: json['description'],
    images: .unmodifiable(images),
    badges: .unmodifiable(json['badges']),
    nutrition: .unmodifiable(json['nutrition'] ?? {}),
    allergens: .unmodifiable(json['allergens'] ?? []),
  );
}
