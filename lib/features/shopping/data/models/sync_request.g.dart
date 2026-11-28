// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncRequest _$SyncRequestFromJson(Map<String, dynamic> json) => SyncRequest(
  baseVersion: (json['baseVersion'] as num).toInt(),
  mutations: (json['mutations'] as List<dynamic>)
      .map((e) => SyncMutation.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SyncRequestToJson(SyncRequest instance) =>
    <String, dynamic>{
      'baseVersion': instance.baseVersion,
      'mutations': instance.mutations.map((e) => e.toJson()).toList(),
    };
