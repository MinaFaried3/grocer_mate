import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/grocer_mate_app.dart';
import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/network/app_connection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final getIt = await initializeDependencies();

  runApp(
    BlocProvider<AppConnection>.value(
      value: getIt<AppConnection>(),
      child: GrocerMateApp(
        getCheckoutSettings: getIt.getCheckoutSettings,
        createCatalogBloc: getIt.createCatalogBloc,
        createProductDetailController: getIt.createProductDetailController,
        createShoppingBloc: getIt.createShoppingBloc,
      ),
    ),
  );
}
