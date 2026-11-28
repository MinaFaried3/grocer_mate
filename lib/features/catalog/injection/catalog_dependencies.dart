import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/injector.dart';
import 'package:grocer_mate/core/mock/mock_dependencies.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';

import '../data/mock_catalog_repository.dart';
import '../domain/repositories/catalog_repository.dart';
import '../presentation/controllers/catalog_bloc.dart';
import '../presentation/controllers/product_detail_controller.dart';

extension CatalogDependencies on Injector {
  CatalogBloc createCatalogBloc() =>
      factory(() => CatalogBloc(_catalogRepository));

  ProductDetailController createProductDetailController(String id) =>
      factoryWithParameter<ProductDetailController, String>(
        (id) => ProductDetailController(_catalogRepository, id),
        id,
      );

  CatalogRepository get _catalogRepository => singleton<CatalogRepository>(
    () => MockCatalogRepository(localStorage, isOnline, mockMarket),
  );
}
