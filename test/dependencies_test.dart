import 'package:flutter_test/flutter_test.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/get_it_injector.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/settings/checkout_settings.dart';
import 'package:grocer_mate/core/settings/settings_dependencies.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:grocer_mate/features/catalog/injection/catalog_dependencies.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/checkout_repository.dart';
import 'package:grocer_mate/features/shopping/injection/shopping_dependencies.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shares startup and registers feature dependencies on demand', () async {
    final startup = initializeDependencies();
    final concurrentStartup = initializeDependencies();
    final dependencies = await startup;
    addTearDown(dependencies.reset);

    expect(concurrentStartup, same(startup));
    expect(await initializeDependencies(), same(dependencies));
    expect(GetItInjector(), same(dependencies));
    expect(dependencies.isRegistered<AppConnectionCubit>(), isTrue);
    expect(dependencies.appConnection.state.connected, isNotNull);
    expect(dependencies.isRegistered<LocalStorage>(), isFalse);
    expect(dependencies.isRegistered<MarketApi>(), isFalse);
    expect(dependencies.isRegistered<ShoppingBloc>(), isFalse);

    final shopping = dependencies.createShoppingBloc();
    addTearDown(shopping.close);
    expect(dependencies.isRegistered<ShoppingBloc>(), isTrue);
    expect(dependencies.isRegistered<CheckoutRepository>(), isFalse);
    expect(dependencies.isRegistered<MarketApi>(), isFalse);
    expect(dependencies.isRegistered<CatalogRepository>(), isFalse);

    final detail = dependencies.createProductDetailController('milk');
    addTearDown(detail.close);
    expect(dependencies.isRegistered<ProductDetailController>(), isTrue);
    final repository = dependencies.get<CatalogRepository>();
    expect(dependencies.isRegistered<CatalogBloc>(), isFalse);

    final catalog = dependencies.createCatalogBloc();
    addTearDown(catalog.close);
    expect(dependencies.get<CatalogRepository>(), same(repository));
    expect(dependencies.isRegistered<CheckoutRepository>(), isFalse);
    expect(dependencies.isRegistered<MarketApi>(), isFalse);
    expect(dependencies.isRegistered<CheckoutSettings>(), isFalse);

    final settings = dependencies.getCheckoutSettings();
    expect(settings, isNotNull);
    expect(dependencies.getCheckoutSettings(), same(settings));
  });

  test('resolves each factory request with its own parameter', () {
    final injector = GetItInjector();
    addTearDown(injector.reset);

    String productId(int id) => 'product-$id';

    expect(injector.factoryWithParameter(productId, 1), 'product-1');
    expect(injector.factoryWithParameter(productId, 2), 'product-2');
  });
}
