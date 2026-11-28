import 'package:grocer_mate/core/network/dio_factory.dart';
import 'package:grocer_mate/core/network/dio_market_api.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/secure_local_storage.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';

import 'get_it_injector.dart';
import 'injector.dart';

const _backendUrl = String.fromEnvironment('GROCER_API_BASE_URL');
final Injector injector = GetItInjector();

/// Shares app startup across calls. Feature instances resolve on demand.
Future<void> initializeDependencies() async {
  // A cold deep link needs the initial status before reading the catalog.
  await injector.appConnection.stream.first;
}

extension SharedDependencies on Injector {
  bool get usesMockData => _backendUrl.isEmpty;

  MarketApi get marketApi => singleton<MarketApi>(
    () => DioMarketApi(createDio(_backendUrl)),
    dispose: (api) => api.close(),
  );

  LocalStorage get localStorage =>
      singleton<LocalStorage>(SecureLocalStorage.new);
}
