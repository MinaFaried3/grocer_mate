import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
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

const _backendUrl = String.fromEnvironment('GROCER_API_BASE_URL');
final _dependencies = _registerAppDependencies();

/// Shares app startup across calls. Feature instances resolve on demand.
Future<GetIt> initializeDependencies() => _dependencies;

Future<GetIt> _registerAppDependencies() async {
  final dependencies = GetIt.asNewInstance();
  final connection = AppConnectionCubit(const PlatformConnectionChecker());
  // A cold deep link needs the initial status before reading the catalog.
  await connection.stream.first;
  dependencies.registerSingleton<AppConnectionCubit>(
    connection,
    dispose: (connection) => connection.close(),
  );
  return dependencies;
}

extension AppDependencyFactories on GetIt {
  CatalogBloc createCatalogBloc() {
    if (!isRegistered<CatalogBloc>()) {
      registerFactory<CatalogBloc>(() => CatalogBloc(_catalogRepository));
    }
    return get<CatalogBloc>();
  }

  ProductDetailController createProductDetailController(String id) {
    if (!isRegistered<ProductDetailController>()) {
      registerFactoryParam<ProductDetailController, String, void>(
        (id, _) => ProductDetailController(_catalogRepository, id),
      );
    }
    return get<ProductDetailController>(param1: id);
  }

  ShoppingBloc createShoppingBloc() {
    if (!isRegistered<ShoppingBloc>()) {
      registerFactory<ShoppingBloc>(() {
        final connection = get<AppConnectionCubit>();
        final storage = _shared<ShoppingRepository>(
          () => LocalShoppingRepository(_storage),
        );
        return ShoppingBloc(
          storage,
          SubmitPendingPurchase(
            storage,
            (purchase) => _checkoutRepository.purchase(purchase),
          ),
          () => connection.online,
          connectionChanges: connection.changes,
          createPurchaseId: const Uuid().v4,
        );
      });
    }
    return get<ShoppingBloc>();
  }

  CheckoutSettings? getCheckoutSettings() =>
      _backendUrl.isEmpty ? _shared(() => CheckoutSettings(_demoClient)) : null;

  CatalogRepository get _catalogRepository => _shared<CatalogRepository>(
    () => CachedCatalog(
      _storage,
      () => get<AppConnectionCubit>().online,
      CatalogRemoteDataSource(_marketApi),
    ),
  );

  CheckoutRepository get _checkoutRepository => _shared<CheckoutRepository>(
    () => ApiCheckoutRepository(
      _marketApi,
      () => get<AppConnectionCubit>().online,
    ),
  );

  MarketApi get _marketApi => _shared<MarketApi>(() {
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
      _shared(() => DemoMarketClient(_storage, rootBundle.loadString));

  LocalStorage get _storage => _shared<LocalStorage>(() {
    final secureStorage = SecureLocalStorage();
    return _backendUrl.isEmpty
        ? secureStorage
        : _BackendStorage(secureStorage, _backendUrl);
  });

  T _shared<T extends Object>(
    T Function() create, {
    FutureOr<void> Function(T)? dispose,
  }) {
    if (!isRegistered<T>()) registerLazySingleton<T>(create, dispose: dispose);
    return get<T>();
  }
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
