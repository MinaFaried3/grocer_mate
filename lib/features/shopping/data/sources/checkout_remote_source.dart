import '../models/purchase_request.dart';
import '../models/purchase_response.dart';

abstract interface class CheckoutRemoteSource {
  Future<PurchaseResponse> purchase(
    PurchaseRequest request, {
    required String idempotencyKey,
  });
}
