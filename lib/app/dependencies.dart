import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/network/platform_connectivity_monitor.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/secure_local_storage.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/data/catalog_remote_data_source.dart';
import 'package:grocer_mate/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/checkout_repository.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';

import 'demo_settings.dart';
import 'mock_market.dart';

Future<GetIt> configureDependencies() async {
  final dependencies = GetIt.asNewInstance();
  final LocalStorage store = SecureLocalStorage();
  final connection = AppConnection(PlatformConnectivityMonitor());
  await connection.start();
  final market = MockMarket(store, connection, rootBundle);

  dependencies.registerSingleton<AppConnection>(
    connection,
    dispose: (connection) => connection.close(),
  );
  dependencies.registerSingleton<DemoSettings>(market);
  dependencies.registerSingleton<CatalogRemoteDataSource>(market);
  dependencies.registerSingleton<CheckoutRepository>(market);
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
  dependencies.registerFactory<ShoppingBloc>(
    () => .new(
      dependencies<ShoppingRepository>(),
      dependencies<CheckoutRepository>(),
      connection,
      createPurchaseId: const Uuid().v4,
    ),
  );

  return dependencies;
}
