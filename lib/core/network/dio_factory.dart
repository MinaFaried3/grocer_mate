import 'package:dio/dio.dart';

Dio createDio(String baseUrl) => Dio(
  BaseOptions(
    baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
    headers: {'Accept': 'application/json'},
    responseType: ResponseType.plain,
    validateStatus: (status) => status != null,
  ),
);
