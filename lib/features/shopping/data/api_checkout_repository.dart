import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';
import 'package:grocer_mate/core/network/endpoints.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/shopping.dart';
import '../domain/repositories/checkout_repository.dart';
import 'models/flags_response.dart';
import 'models/order_response.dart';
import 'models/purchase_request.dart';
import 'models/purchase_response.dart';
import 'models/sync_request.dart';
import 'models/sync_response.dart';

class ApiCheckoutRepository(
  final MarketApi _api,
  final bool Function() _isOnline,
) implements CheckoutRepository {
  Future<String>? _currency;

  Future<FlagsResponse> flags() async =>
      FlagsResponse.fromJson(await _api.get<Json>(Endpoints.flags));

  Future<String> _loadCurrency() async {
    try {
      return requireText((await flags()).currency, 'currency');
    } catch (_) {
      _currency = null;
      rethrow;
    }
  }

  @override
  Future<PurchaseResult> purchase(PendingPurchase purchase) async {
    if (!_isOnline()) throw const OfflineException();
    final currency = await (_currency ??= _loadCurrency());
    if (!_isOnline()) throw const OfflineException();
    final response = await _api.post(
      Endpoints.purchase,
      PurchaseRequest.fromPurchase(purchase, currency: currency).toJson(),
      idempotencyKey: purchase.id,
      acceptedStatuses: const {409, 422},
    );
    return PurchaseResponse.fromJson(response).toResult(purchase);
  }

  Future<OrderResponse> order(String id) async =>
      OrderResponse.fromJson(await _api.get<Json>(Endpoints.orders, id: id));

  Future<SyncResponse> sync(SyncRequest request) async =>
      SyncResponse.fromJson(await _api.post(Endpoints.sync, request.toJson()));
}
