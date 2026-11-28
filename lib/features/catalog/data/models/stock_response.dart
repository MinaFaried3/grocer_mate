import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import 'stock_item.dart';

part 'stock_response.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class const StockResponse({
  required final List<StockItem> stocks,
  final String? timestamp,
}) {
  factory fromJson(Json json) => _$StockResponseFromJson(json);
  Json toJson() => _$StockResponseToJson(this);
}
