import 'package:flutter_test/flutter_test.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/settings/checkout_settings.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/checkout_repository.dart';
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
    expect(dependencies.isRegistered<AppConnectionCubit>(), isTrue);
    expect(dependencies<AppConnectionCubit>().state.connected, isNotNull);
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
    final repository = dependencies<CatalogRepository>();
    expect(dependencies.isRegistered<CatalogBloc>(), isFalse);

    final catalog = dependencies.createCatalogBloc();
    addTearDown(catalog.close);
    expect(dependencies<CatalogRepository>(), same(repository));
    expect(dependencies.isRegistered<CheckoutRepository>(), isFalse);
    expect(dependencies.isRegistered<CheckoutSettings>(), isFalse);

    final settings = dependencies.getCheckoutSettings();
    expect(settings, isNotNull);
    expect(dependencies.getCheckoutSettings(), same(settings));
  });
}
