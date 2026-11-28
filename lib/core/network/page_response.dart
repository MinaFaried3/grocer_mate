import 'package:json_annotation/json_annotation.dart';

import '../storage/json_fields.dart';

part 'page_response.g.dart';

@JsonSerializable(genericArgumentFactories: true, includeIfNull: false)
class const PageResponse<T>({
  required final List<T> data,
  required final int total,
  final int? page,
  final int? pageSize,
  final String? sort,
}) {
  factory fromJson(Json json, T Function(Object?) fromJsonT) =>
      _$PageResponseFromJson(json, fromJsonT);

  Json toJson(Object? Function(T) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}
