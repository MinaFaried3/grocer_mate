import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestions_response.g.dart';

@JsonSerializable(includeIfNull: false)
class const SuggestionsResponse({
  required final List<String> suggestions,
  final String? q,
}) {
  factory fromJson(Json json) => _$SuggestionsResponseFromJson(json);
  Json toJson() => _$SuggestionsResponseToJson(this);
}
