import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/storage/json_store.dart';
import 'package:grocer_mate/core/theme/market_theme.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/domain/catalog.dart';
import 'package:grocer_mate/features/catalog/presentation/catalog_bloc.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/presentation/shopping_bloc.dart';

import 'market_home.dart';
import 'mock_market.dart';

Future<Widget> createApp() async {
  final connection = AppConnection(Connectivity());
  await connection.start();
  final store = JsonStore(SharedPreferencesAsync());
  final market = MockMarket(store, connection, rootBundle);

  return RepositoryProvider<CatalogRepository>(
    create: (_) => CachedCatalog(store, connection, market.catalog),
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => connection),
        BlocProvider(
          create: (context) =>
              CatalogBloc(context.read<CatalogRepository>())
                ..add(const CatalogRefreshed()),
        ),
        BlocProvider(
          create: (_) =>
              ShoppingBloc(LocalShoppingRepository(store), market, connection)
                ..add(const ShopStarted()),
        ),
      ],
      child: _GrocerMateApp(market: market),
    ),
  );
}

class _GrocerMateApp extends StatelessWidget {
  const _GrocerMateApp({required this.market});

  final MockMarket market;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'GrocerMate',
    theme: marketTheme(Brightness.light),
    darkTheme: marketTheme(Brightness.dark),
    builder: (context, child) => Column(
      children: [
        const _OfflineBanner(),
        Expanded(child: child!),
      ],
    ),
    home: MarketHome(market: market),
  );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final online = context.select(
      (AppConnection connection) => connection.online,
    );
    if (online) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.primaryContainer,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 17,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Offline mode · browsing the cached catalog',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
