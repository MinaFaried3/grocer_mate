import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/shopping.dart';
import 'purchase_item.dart';

part 'purchase_request.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class const PurchaseRequest({
  required final List<PurchaseItem> items,
  final String? currency,
}) {
  factory fromJson(Json json) => _$PurchaseRequestFromJson(json);
  Json toJson() => _$PurchaseRequestToJson(this);

  factory fromPurchase(PendingPurchase purchase, {String? currency}) => .new(
    items: [
      for (final line in purchase.lines)
        PurchaseItem(
          productId: line.product.id,
          qty: line.quantity,
          expectedPrice: line.product.price / 100,
        ),
    ],
    currency: currency,
  );
}
