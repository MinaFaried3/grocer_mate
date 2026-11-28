import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/grocer_mate_app.dart';
import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';

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
