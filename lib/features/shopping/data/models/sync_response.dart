import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_response.g.dart';

@JsonSerializable()
class const SyncResponse({
  required final String status,
  required final int newVersion,
}) {
  factory fromJson(Json json) => _$SyncResponseFromJson(json);
  Json toJson() => _$SyncResponseToJson(this);
}
