import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/shopping.dart';
import '../domain/repositories/checkout_repository.dart';
import 'checkout_json.dart';

class ApiCheckoutRepository(
  final MarketApi _api,
  final bool Function() _isOnline,
) implements CheckoutRepository {
  Future<String>? _currency;

  Future<Json> flags() => _api.get('flags');

  Future<String> _loadCurrency() async {
    try {
      return readText(await flags(), 'currency');
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
      'purchase',
      encodePurchase(purchase, currency: currency),
      idempotencyKey: purchase.id,
      acceptedStatuses: const {409, 422},
    );
    return decodePurchase(purchase, response);
  }

  Future<Json> order(String id) => _api.get('orders', id: id);

  Future<Json> sync(Json request) => _api.post('sync', request);
}
