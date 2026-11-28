import 'package:flutter_test/flutter_test.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/get_it_injector.dart';
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
    await initializeDependencies();
    addTearDown(injector.reset);

    expect(GetItInjector(), same(injector));
    expect(injector.isRegistered<AppConnectionCubit>(), isTrue);
    expect(injector.appConnection.state.connected, isNotNull);
    expect(injector.isRegistered<LocalStorage>(), isFalse);
    expect(injector.isRegistered<ShoppingBloc>(), isFalse);

    final shopping = injector.createShoppingBloc();
    addTearDown(shopping.close);
    expect(injector.isRegistered<ShoppingBloc>(), isTrue);
    expect(injector.isRegistered<CheckoutRepository>(), isFalse);
    expect(injector.isRegistered<CatalogRepository>(), isFalse);

    final detail = injector.createProductDetailController('milk');
    addTearDown(detail.close);
    expect(injector.isRegistered<ProductDetailController>(), isTrue);
    final repository = injector.get<CatalogRepository>();
    expect(injector.isRegistered<CatalogBloc>(), isFalse);

    final catalog = injector.createCatalogBloc();
    addTearDown(catalog.close);
    expect(injector.get<CatalogRepository>(), same(repository));
    expect(injector.isRegistered<CheckoutRepository>(), isFalse);
    expect(injector.isRegistered<CheckoutSettings>(), isFalse);

    final settings = injector.getCheckoutSettings();
    expect(settings, isNotNull);
    expect(injector.getCheckoutSettings(), same(settings));
  });

  test('resolves each factory request with its own parameter', () {
    final injector = GetItInjector();
    addTearDown(injector.reset);

    String productId(int id) => 'product-$id';

    expect(injector.factoryWithParameter(productId, 1), 'product-1');
    expect(injector.factoryWithParameter(productId, 2), 'product-2');
  });
}
