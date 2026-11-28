import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'catalog.g.dart';

@JsonSerializable()
class const Category({
  required final String id,
  required final String name,
  required final String icon,
}) {
  factory fromJson(Json json) {
    final category = _$CategoryFromJson(json);
    if (category.id.trim().isEmpty ||
        category.name.trim().isEmpty ||
        category.icon.trim().isEmpty) {
      throw const FormatException('Invalid category data.');
    }
    return category;
  }

  Json toJson() => _$CategoryToJson(this);
}

@JsonSerializable()
class const Product({
  required final String id,
  required final String title,
  required final String brand,
  required final String categoryId,
  required final int price,
  required final int originalPrice,
  required final int stock,
  required final double rating,
  required final String description,
  required final List<String> images,
  required final List<String> badges,
  required final Map<String, num> nutrition,
  required final List<String> allergens,
  final List<String> related = const [],
}) {
  this
    : assert(price >= 0),
      assert(originalPrice >= 0),
      assert(stock >= 0),
      assert(rating >= 0 && rating <= 5);

  factory fromJson(Json json) {
    final images = json['images'];
    final rating = json['rating'];
    if (images is! List ||
        images.isEmpty ||
        images.any((image) => image is! String || image.trim().isEmpty) ||
        rating is! num ||
        !rating.isFinite ||
        rating < 0 ||
        rating > 5) {
      throw const FormatException('Invalid product data.');
    }
    readText(json, 'id');
    readText(json, 'title');
    readText(json, 'brand');
    readInt(json, 'price');
    readInt(json, 'originalPrice');
    readInt(json, 'stock');
    return _$ProductFromJson(json);
  }

  Json toJson() => _$ProductToJson(this);

  int get discountPercent => originalPrice > price
      ? ((originalPrice - price) * 100 / originalPrice).round()
      : 0;
}

typedef CatalogQuery = ({
  String search,
  String? category,
  String? brand,
  bool deals,
});
typedef CatalogPage = ({
  List<Product> products,
  int total,
  List<Category> categories,
  List<String> brands,
});
