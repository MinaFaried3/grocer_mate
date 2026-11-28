// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestionsResponse _$SuggestionsResponseFromJson(Map<String, dynamic> json) =>
    SuggestionsResponse(
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      q: json['q'] as String?,
    );

Map<String, dynamic> _$SuggestionsResponseToJson(
  SuggestionsResponse instance,
) => <String, dynamic>{'suggestions': instance.suggestions, 'q': ?instance.q};
