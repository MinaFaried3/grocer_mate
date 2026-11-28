import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/shopping.dart';

part 'shopping_data.g.dart';

@JsonSerializable(explicitToJson: true)
class const ShoppingData({
  final List<CartLine> cart = const [],
  final List<CartLine> saved = const [],
  final PendingPurchase? pending,
  final OrderReceipt? lastOrder,
}) {
  factory fromJson(Json json) => _$ShoppingDataFromJson(json);

  Json toJson() => _$ShoppingDataToJson(this);

  ShoppingData withLists({List<CartLine>? cart, List<CartLine>? saved}) => .new(
    cart: cart ?? this.cart,
    saved: saved ?? this.saved,
    pending: pending,
    lastOrder: lastOrder,
  );
}
