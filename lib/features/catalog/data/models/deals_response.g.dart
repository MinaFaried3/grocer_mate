// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deals_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DealsResponse _$DealsResponseFromJson(Map<String, dynamic> json) =>
    DealsResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => DealResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      date: json['date'] as String?,
    );

Map<String, dynamic> _$DealsResponseToJson(DealsResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'date': ?instance.date,
    };
