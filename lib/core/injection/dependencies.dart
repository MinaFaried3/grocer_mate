import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:grocer_mate/core/network/demo/demo_market_client.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/secure_local_storage.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';

import 'get_it_injector.dart';
import 'injector.dart';

const _backendUrl = String.fromEnvironment('GROCER_API_BASE_URL');
final _dependencies = _registerAppDependencies();

/// Shares app startup across calls. Feature instances resolve on demand.
Future<Injector> initializeDependencies() => _dependencies;

Future<Injector> _registerAppDependencies() async {
  final dependencies = GetItInjector();
  // A cold deep link needs the initial status before reading the catalog.
  await dependencies.appConnection.stream.first;
  return dependencies;
}

extension SharedDependencies on Injector {
  MarketApi get marketApi => singleton<MarketApi>(() {
    final baseUrl = Uri.parse(
      _backendUrl.isEmpty ? 'https://grocer.demo' : _backendUrl,
    );
    if (!const {'http', 'https'}.contains(baseUrl.scheme) ||
        baseUrl.host.isEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment) {
      throw ArgumentError('GROCER_API_BASE_URL must be an HTTP(S) base URL.');
    }
    return MarketApi(baseUrl, demoMarketClient ?? http.Client());
  }, dispose: (api) => api.close());

  DemoMarketClient? get demoMarketClient => _backendUrl.isEmpty
      ? singleton(() => DemoMarketClient(localStorage, rootBundle.loadString))
      : null;

  LocalStorage get localStorage => singleton<LocalStorage>(() {
    final secureStorage = SecureLocalStorage();
    return _backendUrl.isEmpty
        ? secureStorage
        : _BackendStorage(secureStorage, _backendUrl);
  });
}

class const _BackendStorage(final LocalStorage store, final String backend)
    implements LocalStorage {
  String _key(String key) => 'backend_${Uri.encodeComponent(backend)}_$key';

  @override
  Future<Map<String, dynamic>?> read(String key) => store.read(_key(key));

  @override
  Future<void> write(String key, Map<String, Object?> value) =>
      store.write(_key(key), value);
}
