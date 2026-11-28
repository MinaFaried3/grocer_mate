import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/cart_line.dart';

part 'pending_purchase.g.dart';

@JsonSerializable(explicitToJson: true)
class const PendingPurchase(
  final String id,
  final List<CartLine> lines, {
  final bool attempted = false,
}) {
  factory fromJson(Json json) {
    readText(json, 'id');
    return _$PendingPurchaseFromJson(json);
  }

  Json toJson() => _$PendingPurchaseToJson(this);
}
