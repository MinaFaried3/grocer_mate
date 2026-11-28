import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/catalog.dart';

part 'product_response.g.dart';

@JsonSerializable(includeIfNull: false)
class const ProductResponse({
  required final String id,
  required final String title,
  required final String brand,
  required final num price,
  required final num originalPrice,
  required final num stock,
  final String? categoryId,
  final String? image,
  final List<String>? images,
  final double? rating,
  final String? description,
  final List<String>? badges,
  final Map<String, num>? nutrition,
  final List<String>? allergens,
  final List<String>? related,
}) {
  factory fromJson(Json json) => _$ProductResponseFromJson(json);
  Json toJson() => _$ProductResponseToJson(this);

  Product toProduct({Product? summary}) {
    final resolvedImages = images ?? [?image];
    // Require at least one non-empty image URL or asset path.
    final hasBlankImage = resolvedImages.any((item) => item.trim().isEmpty);
    final hasInvalidImages = resolvedImages.isEmpty || hasBlankImage;
    if (hasInvalidImages) {
      throw const FormatException('A product needs a usable image.');
    }
    final resolvedRating = rating ?? summary?.rating ?? 0.0;
    // Ensure product rating is a finite number between 0 and 5.
    final isOutOfRange = resolvedRating < 0 || resolvedRating > 5;
    final hasInvalidRating = !resolvedRating.isFinite || isOutOfRange;
    if (hasInvalidRating) {
      throw const FormatException('Product rating must be between 0 and 5.');
    }
    return Product(
      id: requireText(id, 'id'),
      title: requireText(title, 'title'),
      brand: requireText(brand, 'brand'),
      categoryId: categoryId ?? summary?.categoryId ?? '',
      price: requireCents(price, 'price'),
      originalPrice: requireCents(originalPrice, 'originalPrice'),
      stock: requireInt(stock, 'stock'),
      rating: resolvedRating,
      description: description ?? '',
      images: List.unmodifiable(resolvedImages),
      badges: List.unmodifiable(badges ?? summary?.badges ?? const []),
      nutrition: Map.unmodifiable(nutrition ?? const {}),
      allergens: List.unmodifiable(allergens ?? const []),
      related: List.unmodifiable(related ?? const []),
    );
  }
}
