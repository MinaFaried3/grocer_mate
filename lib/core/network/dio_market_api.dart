import 'dart:convert';

import 'package:dio/dio.dart';

import '../storage/json_fields.dart';
import 'connectivity/offline_exception.dart';
import 'market_api.dart';

class DioMarketApi(final Dio _dio) implements MarketApi {
  static const _timeout = Duration(seconds: 15);

  @override
  Future<T> get<T>(String endpoint, {String? id, Map<String, String>? query}) =>
      _request<T>('GET', endpoint, id: id, query: query);

  @override
  Future<Json> post(
    String endpoint,
    Json body, {
    String? idempotencyKey,
    Set<int> acceptedStatuses = const {},
  }) => _request<Json>(
    'POST',
    endpoint,
    body: body,
    idempotencyKey: idempotencyKey,
    acceptedStatuses: acceptedStatuses,
  );

  Future<T> _request<T>(
    String method,
    String endpoint, {
    String? id,
    Map<String, String>? query,
    Json? body,
    String? idempotencyKey,
    Set<int> acceptedStatuses = const {},
  }) async {
    final path = id == null ? endpoint : '$endpoint/${Uri.encodeComponent(id)}';
    final cancelToken = CancelToken();
    try {
      final response = await _dio
          .request<String>(
            path,
            queryParameters: query,
            data: body,
            cancelToken: cancelToken,
            options: Options(
              method: method,
              contentType: body == null
                  ? null
                  : 'application/json; charset=utf-8',
              headers: idempotencyKey == null
                  ? null
                  : {'Idempotency-Key': idempotencyKey},
            ),
          )
          .timeout(
            _timeout,
            onTimeout: () {
              cancelToken.cancel();
              throw const OfflineException();
            },
          );
      final status = response.statusCode!;
      if ((status < 200 || status >= 300) &&
          !acceptedStatuses.contains(status)) {
        throw ApiException(status, response.data);
      }
      return jsonDecode(response.data ?? '') as T;
    } on DioException catch (error) {
      if (error.type == .connectionError) throw const OfflineException();
      rethrow;
    }
  }

  @override
  void close() => _dio.close();
}
