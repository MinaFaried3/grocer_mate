import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import 'purchase_request.dart';

part 'sync_mutation.g.dart';

@JsonSerializable(explicitToJson: true)
class const SyncMutation({
  required final String op,
  required final String idempotencyKey,
  required final PurchaseRequest payload,
}) {
  factory fromJson(Json json) => _$SyncMutationFromJson(json);
  Json toJson() => _$SyncMutationToJson(this);
}
