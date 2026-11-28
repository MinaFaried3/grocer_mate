import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import 'sync_mutation.dart';

part 'sync_request.g.dart';

@JsonSerializable(explicitToJson: true)
class const SyncRequest({
  required final int baseVersion,
  required final List<SyncMutation> mutations,
}) {
  factory fromJson(Json json) => _$SyncRequestFromJson(json);
  Json toJson() => _$SyncRequestToJson(this);
}
