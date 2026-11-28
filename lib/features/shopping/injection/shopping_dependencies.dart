import 'package:uuid/uuid.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/injector.dart';
import 'package:grocer_mate/core/mock/mock_dependencies.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';

import '../data/api_checkout_repository.dart';
import '../data/local_shopping_repository.dart';
import '../data/mock_checkout_repository.dart';
import '../domain/repositories/checkout_repository.dart';
import '../domain/repositories/shopping_repository.dart';
import '../domain/use_cases/submit_pending_purchase.dart';
import '../presentation/controllers/shopping_bloc.dart';

extension ShoppingDependencies on Injector {
  ShoppingBloc createShoppingBloc() => factory(() {
    final storage = singleton<ShoppingRepository>(
      () => LocalShoppingRepository(localStorage),
    );
    return ShoppingBloc(
      storage,
      SubmitPendingPurchase(
        storage,
        (purchase) => _checkoutRepository.purchase(purchase),
      ),
      isOnline,
      connectionChanges: appConnection.changes,
      createPurchaseId: const Uuid().v4,
    );
  });

  CheckoutRepository get _checkoutRepository => singleton<CheckoutRepository>(
    () => usesMockData
        ? MockCheckoutRepository(mockMarket, isOnline)
        : ApiCheckoutRepository(marketApi, isOnline),
  );
}
