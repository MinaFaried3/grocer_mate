import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class const Category({
  required final String id,
  required final String name,
  required final String icon,
}) {
  factory fromJson(Json json) {
    readText(json, 'id');
    readText(json, 'name');
    readText(json, 'icon');
    return _$CategoryFromJson(json);
  }

  Json toJson() => _$CategoryToJson(this);
}
