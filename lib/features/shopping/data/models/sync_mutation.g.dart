// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_mutation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncMutation _$SyncMutationFromJson(Map<String, dynamic> json) => SyncMutation(
  op: json['op'] as String,
  idempotencyKey: json['idempotencyKey'] as String,
  payload: PurchaseRequest.fromJson(json['payload'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SyncMutationToJson(SyncMutation instance) =>
    <String, dynamic>{
      'op': instance.op,
      'idempotencyKey': instance.idempotencyKey,
      'payload': instance.payload.toJson(),
    };
