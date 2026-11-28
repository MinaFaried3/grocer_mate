import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/injector.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';
import 'package:grocer_mate/features/catalog/injection/catalog_dependencies.dart';

import '../data/repositories/shopping_repository_impl.dart';
import '../data/repositories/checkout_repository_impl.dart';
import '../data/sources/local_shopping_source.dart';
import '../data/sources/mock_checkout_remote_ds.dart';
import '../domain/entities/checkout_settings.dart';
import '../domain/repositories/checkout_repository.dart';
import '../domain/repositories/shopping_repository.dart';
import '../domain/use_cases/submit_pending_purchase.dart';
import '../presentation/controllers/shopping_bloc.dart';

extension ShoppingDependencies on Injector {
  CheckoutSettings getCheckoutSettings() =>
      singleton(() => _checkoutSource.settings);

  MockCheckoutRemoteDS get _checkoutSource => singleton(
    () => MockCheckoutRemoteDS(
      rootBundle.loadString,
      marketStore,
      mockCatalogRemoteDS,
      settings: CheckoutSettings(),
    ),
  );

  ShoppingBloc createShoppingBloc() => factory(() {
    final repo = singleton<ShoppingRepository>(
      () => ShoppingRepositoryImpl(LocalShoppingSource(localStorage)),
    );
    return ShoppingBloc(
      repo,
      SubmitPendingPurchase(
        repo,
        (purchase) => _checkoutRepository.purchase(purchase),
      ),
      isOnline,
      connectionChanges: appConnection.changes,
      createPurchaseId: const Uuid().v4,
    );
  });

  CheckoutRepository get _checkoutRepository => singleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(_checkoutSource, isOnline),
  );
}
