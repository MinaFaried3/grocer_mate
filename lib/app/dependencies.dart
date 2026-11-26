import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/storage/json_store.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/domain/catalog.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/shopping.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';

import 'mock_market.dart';

Future<GetIt> configureDependencies() async {
  final dependencies = GetIt.asNewInstance();
  final store = JsonStore(SharedPreferencesAsync());
  final connection = AppConnection(Connectivity());
  await connection.start();

  dependencies.registerSingleton<AppConnection>(
    connection,
    dispose: (connection) => connection.close(),
  );
  dependencies.registerLazySingleton<MockMarket>(
    () => .new(store, dependencies<AppConnection>(), rootBundle),
  );
  dependencies.registerLazySingleton<CatalogRepository>(
    () => CachedCatalog(
      store,
      dependencies<AppConnection>(),
      dependencies<MockMarket>().catalog,
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
      dependencies<MockMarket>(),
      dependencies<AppConnection>(),
    ),
  );

  return dependencies;
}
