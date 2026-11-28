import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import 'cart_product.dart';

part 'cart_line.g.dart';

@JsonSerializable(explicitToJson: true)
class const CartLine(final CartProduct product, final int quantity) {
  this : assert(quantity > 0);

  factory fromJson(Json json) {
    readInt(json, 'quantity', minimum: 1);
    return _$CartLineFromJson(json);
  }

  Json toJson() => _$CartLineToJson(this);

  CartLine withQuantity(int next) => .new(product, next);
}
