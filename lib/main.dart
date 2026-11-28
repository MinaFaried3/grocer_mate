import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/app/checkout_settings.dart';
import 'package:grocer_mate/app/grocer_mate_app.dart';
import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final getIt = await initializeDependencies();

  runApp(
    BlocProvider<AppConnection>.value(
      value: getIt<AppConnection>(),
      child: GrocerMateApp(
        checkoutSettings: getIt.isRegistered<CheckoutSettings>()
            ? getIt<CheckoutSettings>()
            : null,
        createCatalogBloc: () => getIt<CatalogBloc>(),
        createProductDetailController: (id) =>
            getIt<ProductDetailController>(param1: id),
        createShoppingBloc: () => getIt<ShoppingBloc>(),
      ),
    ),
  );
}
