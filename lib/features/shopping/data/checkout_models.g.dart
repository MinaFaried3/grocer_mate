// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_models.dart';

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

PurchaseRequest _$PurchaseRequestFromJson(Map<String, dynamic> json) =>
    PurchaseRequest(
      items: (json['items'] as List<dynamic>)
          .map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      currency: json['currency'] as String?,
    );

Map<String, dynamic> _$PurchaseRequestToJson(PurchaseRequest instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'currency': ?instance.currency,
    };

PurchaseItem _$PurchaseItemFromJson(Map<String, dynamic> json) => PurchaseItem(
  productId: json['productId'] as String,
  qty: json['qty'] as num,
  expectedPrice: json['expectedPrice'] as num?,
);

Map<String, dynamic> _$PurchaseItemToJson(PurchaseItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'qty': instance.qty,
      'expectedPrice': ?instance.expectedPrice,
    };

PurchaseResponse _$PurchaseResponseFromJson(Map<String, dynamic> json) =>
    PurchaseResponse(
      status: json['status'] as String,
      orderId: json['orderId'] as String?,
      finalTotal: json['finalTotal'] as num?,
      note: json['note'] as String?,
      changes: (json['changes'] as List<dynamic>?)
          ?.map((e) => PriceChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => StockChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      priceChanges: (json['priceChanges'] as List<dynamic>?)
          ?.map((e) => PriceChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      oos: (json['oos'] as List<dynamic>?)
          ?.map((e) => StockChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      fulfilled: (json['fulfilled'] as List<dynamic>?)
          ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      missing: (json['missing'] as List<dynamic>?)
          ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PurchaseResponseToJson(PurchaseResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'orderId': ?instance.orderId,
      'finalTotal': ?instance.finalTotal,
      'note': ?instance.note,
      'changes': ?instance.changes?.map((e) => e.toJson()).toList(),
      'items': ?instance.items?.map((e) => e.toJson()).toList(),
      'priceChanges': ?instance.priceChanges?.map((e) => e.toJson()).toList(),
      'oos': ?instance.oos?.map((e) => e.toJson()).toList(),
      'fulfilled': ?instance.fulfilled?.map((e) => e.toJson()).toList(),
      'missing': ?instance.missing?.map((e) => e.toJson()).toList(),
    };

PriceChangeResponse _$PriceChangeResponseFromJson(Map<String, dynamic> json) =>
    PriceChangeResponse(
      productId: json['productId'] as String,
      newPrice: json['newPrice'] as num,
      oldPrice: json['oldPrice'] as num?,
    );

Map<String, dynamic> _$PriceChangeResponseToJson(
  PriceChangeResponse instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'newPrice': instance.newPrice,
  'oldPrice': ?instance.oldPrice,
};

StockChangeResponse _$StockChangeResponseFromJson(Map<String, dynamic> json) =>
    StockChangeResponse(
      productId: json['productId'] as String,
      available: json['available'] as num,
    );

Map<String, dynamic> _$StockChangeResponseToJson(
  StockChangeResponse instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'available': instance.available,
};

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      orderId: json['orderId'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      currency: json['currency'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: json['subtotal'] as num,
      tax: json['tax'] as num,
      deliveryFee: json['deliveryFee'] as num,
      total: json['total'] as num,
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'currency': instance.currency,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotal': instance.subtotal,
      'tax': instance.tax,
      'deliveryFee': instance.deliveryFee,
      'total': instance.total,
    };

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  productId: json['productId'] as String,
  qty: (json['qty'] as num).toInt(),
  unitPrice: json['unitPrice'] as num,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'qty': instance.qty,
  'unitPrice': instance.unitPrice,
};

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

SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) => SyncResponse(
  status: json['status'] as String,
  newVersion: (json['newVersion'] as num).toInt(),
);

Map<String, dynamic> _$SyncResponseToJson(SyncResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'newVersion': instance.newVersion,
    };
