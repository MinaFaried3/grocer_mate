import '../storage/json_fields.dart';

abstract interface class MarketApi {
  Future<T> get<T>(String endpoint, {String? id, Map<String, String>? query});

  Future<Json> post(
    String endpoint,
    Json body, {
    String? idempotencyKey,
    Set<int> acceptedStatuses = const {},
  });

  void close();
}

class const ApiException(final int statusCode, final Object? body)
    implements Exception {
  @override
  String toString() => 'Market API returned HTTP $statusCode';
}
