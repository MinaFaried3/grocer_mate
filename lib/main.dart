import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/grocer_mate_app.dart';
import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/settings/settings_dependencies.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/catalog/injection/catalog_dependencies.dart';
import 'package:grocer_mate/features/shopping/injection/shopping_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await initializeDependencies();

  runApp(
    BlocProvider<AppConnectionCubit>.value(
      value: dependencies.appConnection,
      child: GrocerMateApp(
        getCheckoutSettings: dependencies.getCheckoutSettings,
        createCatalogBloc: dependencies.createCatalogBloc,
        createProductDetailController:
            dependencies.createProductDetailController,
        createShoppingBloc: dependencies.createShoppingBloc,
      ),
    ),
  );
}
