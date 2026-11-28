import 'package:grocer_mate/core/mock/mock_market.dart';

import '../models/purchase_request.dart';
import '../models/purchase_response.dart';

class const MockCheckoutSource(final MockMarket _market) {
  Future<PurchaseResponse> purchase(
    PurchaseRequest request, {
    required String idempotencyKey,
  }) async => PurchaseResponse.fromJson(
    await _market.purchase(request.toJson(), key: idempotencyKey),
  );
}
