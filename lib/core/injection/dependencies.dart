import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:grocer_mate/core/network/connectivity/platform_connection_checker.dart';
import 'package:grocer_mate/core/network/demo/demo_market_client.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/settings/checkout_settings.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/secure_local_storage.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/data/catalog_remote_data_source.dart';
import 'package:grocer_mate/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/shopping/data/api_checkout_repository.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/checkout_repository.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';

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

extension AppDependencyFactories on Injector {
  AppConnectionCubit get appConnection => singleton(
    () => AppConnectionCubit(const PlatformConnectionChecker()),
    dispose: (connection) => connection.close(),
  );

  CatalogBloc createCatalogBloc() =>
      factory(() => CatalogBloc(_catalogRepository));

  ProductDetailController createProductDetailController(String id) =>
      factoryWithParameter<ProductDetailController, String>(
        (id) => ProductDetailController(_catalogRepository, id),
        id,
      );

  ShoppingBloc createShoppingBloc() => factory(() {
    final storage = singleton<ShoppingRepository>(
      () => LocalShoppingRepository(_storage),
    );
    return ShoppingBloc(
      storage,
      SubmitPendingPurchase(
        storage,
        (purchase) => _checkoutRepository.purchase(purchase),
      ),
      _isOnline,
      connectionChanges: appConnection.changes,
      createPurchaseId: const Uuid().v4,
    );
  });

  CheckoutSettings? getCheckoutSettings() =>
      _backendUrl.isEmpty ? singleton(() => CheckoutSettings(_demoClient)) : null;

  bool _isOnline() => get<AppConnectionCubit>().online;

  CatalogRepository get _catalogRepository => singleton<CatalogRepository>(
    () =>
        CachedCatalog(_storage, _isOnline, CatalogRemoteDataSource(_marketApi)),
  );

  CheckoutRepository get _checkoutRepository => singleton<CheckoutRepository>(
    () => ApiCheckoutRepository(_marketApi, _isOnline),
  );

  MarketApi get _marketApi => singleton<MarketApi>(() {
    final baseUrl = Uri.parse(
      _backendUrl.isEmpty ? 'https://grocer.demo' : _backendUrl,
    );
    if (!const {'http', 'https'}.contains(baseUrl.scheme) ||
        baseUrl.host.isEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment) {
      throw ArgumentError('GROCER_API_BASE_URL must be an HTTP(S) base URL.');
    }
    return MarketApi(
      baseUrl,
      _backendUrl.isEmpty ? _demoClient : http.Client(),
    );
  }, dispose: (api) => api.close());

  DemoMarketClient get _demoClient =>
      singleton(() => DemoMarketClient(_storage, rootBundle.loadString));

  LocalStorage get _storage => singleton<LocalStorage>(() {
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
