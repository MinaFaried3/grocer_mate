// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flags_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlagsResponse _$FlagsResponseFromJson(Map<String, dynamic> json) =>
    FlagsResponse(
      currency: json['currency'] as String,
      showDeals: json['showDeals'] as bool?,
      enablePriceRevalidation: json['enablePriceRevalidation'] as bool?,
      taxRate: json['taxRate'] as num?,
      deliveryFee: json['deliveryFee'] as num?,
      freeDeliveryThreshold: json['freeDeliveryThreshold'] as num?,
      searchDebounceMs: (json['searchDebounceMs'] as num?)?.toInt(),
      enableSavedForLater: json['enableSavedForLater'] as bool?,
      maintenanceMode: json['maintenanceMode'] as bool?,
    );

Map<String, dynamic> _$FlagsResponseToJson(FlagsResponse instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'showDeals': ?instance.showDeals,
      'enablePriceRevalidation': ?instance.enablePriceRevalidation,
      'taxRate': ?instance.taxRate,
      'deliveryFee': ?instance.deliveryFee,
      'freeDeliveryThreshold': ?instance.freeDeliveryThreshold,
      'searchDebounceMs': ?instance.searchDebounceMs,
      'enableSavedForLater': ?instance.enableSavedForLater,
      'maintenanceMode': ?instance.maintenanceMode,
    };
