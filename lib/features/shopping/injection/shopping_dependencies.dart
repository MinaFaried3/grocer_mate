import 'package:uuid/uuid.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/injector.dart';
import 'package:grocer_mate/core/mock/mock_dependencies.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';

import '../data/repositories/local_shopping_repository.dart';
import '../data/repositories/mock_checkout_repository.dart';
import '../data/sources/local_shopping_source.dart';
import '../data/sources/mock_checkout_source.dart';
import '../domain/repositories/checkout_repository.dart';
import '../domain/repositories/shopping_repository.dart';
import '../domain/use_cases/submit_pending_purchase.dart';
import '../presentation/controllers/shopping_bloc.dart';

extension ShoppingDependencies on Injector {
  ShoppingBloc createShoppingBloc() => factory(() {
    final repo = singleton<ShoppingRepository>(
      () => LocalShoppingRepository(LocalShoppingSource(localStorage)),
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
    () => MockCheckoutRepository(MockCheckoutSource(mockMarket), isOnline),
  );
}
