import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/app/dependencies.dart';
import 'package:grocer_mate/app/grocer_mate_app.dart';
import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_event.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await configureDependencies();

  runApp(
    RepositoryProvider<CatalogRepository>.value(
      value: dependencies<CatalogRepository>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppConnection>.value(
            value: dependencies<AppConnection>(),
          ),
          BlocProvider(
            create: (_) =>
                dependencies<CatalogBloc>()..add(const CatalogRefreshed()),
          ),
          BlocProvider(
            create: (_) =>
                dependencies<ShoppingBloc>()..add(const ShopStarted()),
          ),
        ],
        child: GrocerMateApp(market: dependencies()),
      ),
    ),
  );
}
