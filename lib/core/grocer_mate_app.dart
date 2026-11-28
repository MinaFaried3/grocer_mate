import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/routing/app_router.dart';
import 'package:grocer_mate/core/theme/market_theme.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/app/presentation/ui/widgets/offline_banner.dart';

class const GrocerMateApp({super.key}) extends StatefulWidget {
  @override
  State<GrocerMateApp> createState() => _GrocerMateAppState();
}

class _GrocerMateAppState() extends State<GrocerMateApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      //------------ App Connection Provider ---------------
      BlocProvider<AppConnectionCubit>.value(
        value: injector.appConnection,
        child: MaterialApp.router(
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          title: 'GrocerMate',
          theme: MarketThemeFactory.light.build(),
          darkTheme: MarketThemeFactory.dark.build(),
          builder: (context, child) => Column(
            children: [
              //------------ Offline Banner ---------------
              const OfflineBanner(),

              //------------ App Content ---------------
              Expanded(child: child!),
            ],
          ),
        ),
      );
}
