import 'package:flutter/services.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/injector.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';

import '../data/repositories/catalog_repository_impl.dart';
import '../data/sources/catalog_cache_source.dart';
import '../data/sources/mock_catalog_remote_ds.dart';
import '../domain/repositories/catalog_repository.dart';
import '../presentation/controllers/catalog_bloc.dart';
import '../presentation/controllers/product_detail_controller.dart';

extension CatalogDependencies on Injector {
  MockCatalogRemoteDS get mockCatalogRemoteDS => singleton(
    () => MockCatalogRemoteDS(
      rootBundle.loadString,
      marketStore.readAvailability,
    ),
  );

  CatalogBloc createCatalogBloc() =>
      factory(() => CatalogBloc(_catalogRepository));

  ProductDetailController createProductDetailController(String id) =>
      factoryWithParameter<ProductDetailController, String>(
        (id) => ProductDetailController(_catalogRepository, id),
        id,
      );

  CatalogRepository get _catalogRepository => singleton<CatalogRepository>(
    () => CatalogRepositoryImpl(
      CatalogCacheSource(localStorage),
      isOnline,
      mockCatalogRemoteDS,
    ),
  );
}
