import 'package:grocer_mate/core/network/page_response.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/catalog.dart';
import 'catalog_models.dart';

Category decodeCategory(Json json) {
  final category = CategoryResponse.fromJson(json);
  return Category(
    id: requireText(category.id, 'id'),
    name: requireText(category.name, 'name'),
    icon: requireText(category.icon, 'icon'),
  );
}

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

Product decodeApiProduct(Json json, {Product? summary}) =>
    _apiProduct(ProductResponse.fromJson(json), summary: summary);

Product _apiProduct(ProductResponse response, {Product? summary}) {
  final json = response.toJson()
    ..['price'] = requireCents(response.price, 'price')
    ..['originalPrice'] = requireCents(response.originalPrice, 'originalPrice')
    ..['images'] = response.images ?? [?response.image]
    ..['rating'] = response.rating ?? summary?.rating ?? 0.0
    ..['badges'] = response.badges ?? summary?.badges ?? const <String>[]
    ..['categoryId'] = response.categoryId ?? summary?.categoryId ?? ''
    ..['description'] = response.description ?? '';
  return decodeProduct(json, allowMissingCategory: true);
}

Json encodeCategory(Category category) => CategoryResponse(
  id: category.id,
  name: category.name,
  icon: category.icon,
).toJson();

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
  for (final item in items) decodeCategory(item as Json),
];

List<String> decodeBrands(Json json, String? category) => {
  for (final names in category == null ? json.values : [json[category]])
    if (names is List) ...names.cast<String>(),
}.toList()..sort();

({List<Product> products, int total}) decodeProductPage(Json json) {
  final page = PageResponse<ProductResponse>.fromJson(
    json,
    (item) => ProductResponse.fromJson(item as Json),
  );
  return (products: page.data.map(_apiProduct).toList(), total: page.total);
}
