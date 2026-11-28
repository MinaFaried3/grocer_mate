import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:grocer_mate/app/checkout_settings.dart';
import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/network/demo/demo_market_client.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/network/platform_connectivity_monitor.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/secure_local_storage.dart';
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

final Future<GetIt> _dependencyInitialization = _registerDependencies();

/// Initializes the app's dependencies once and shares the result across calls.
Future<GetIt> initializeDependencies() => _dependencyInitialization;

Future<GetIt> _registerDependencies() async {
  final dependencies = GetIt.asNewInstance();
  const backendUrl = String.fromEnvironment('GROCER_API_BASE_URL');
  final secureStorage = SecureLocalStorage();
  final LocalStorage store = backendUrl.isEmpty
      ? secureStorage
      : _BackendStorage(secureStorage, backendUrl);
  final demo = backendUrl.isEmpty
      ? DemoMarketClient(store, rootBundle.loadString)
      : null;
  final baseUrl = Uri.parse(demo == null ? backendUrl : 'https://grocer.demo');
  if (!const {'http', 'https'}.contains(baseUrl.scheme) ||
      baseUrl.host.isEmpty ||
      baseUrl.hasQuery ||
      baseUrl.hasFragment) {
    throw ArgumentError('GROCER_API_BASE_URL must be an HTTP(S) base URL.');
  }
  final api = MarketApi(baseUrl, demo ?? http.Client());
  final connection = AppConnection(PlatformConnectivityMonitor());
  await connection.start();

  dependencies.registerSingleton<AppConnection>(
    connection,
    dispose: (connection) => connection.close(),
  );
  dependencies.registerSingleton<MarketApi>(api, dispose: (api) => api.close());
  if (demo != null) {
    dependencies.registerSingleton<CheckoutSettings>(CheckoutSettings(demo));
  }
  dependencies.registerSingleton<CatalogRemoteDataSource>(
    CatalogRemoteDataSource(api),
  );
  final checkout = ApiCheckoutRepository(api, connection);
  dependencies.registerSingleton<ApiCheckoutRepository>(checkout);
  dependencies.registerSingleton<CheckoutRepository>(checkout);
  dependencies.registerLazySingleton<CatalogRepository>(
    () => CachedCatalog(
      store,
      connection,
      dependencies<CatalogRemoteDataSource>(),
    ),
  );

  dependencies.registerFactory<ShoppingRepository>(
    () => LocalShoppingRepository(store),
  );
  dependencies.registerFactory<CatalogBloc>(
    () => .new(dependencies<CatalogRepository>()),
  );
  dependencies.registerFactoryParam<ProductDetailController, String, void>(
    (id, _) => ProductDetailController(dependencies<CatalogRepository>(), id),
  );
  dependencies.registerFactory<ShoppingBloc>(() {
    final storage = dependencies<ShoppingRepository>();
    return ShoppingBloc(
      storage,
      SubmitPendingPurchase(storage, dependencies<CheckoutRepository>()),
      connection,
      createPurchaseId: const Uuid().v4,
    );
  });

  return dependencies;
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
