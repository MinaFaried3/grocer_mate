import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_connection.dart';
import 'data/cached_catalog.dart';
import 'data/local_store.dart';
import 'data/mock_market.dart';
import 'domain/catalog.dart';
import 'presentation/catalog/catalog_bloc.dart';
import 'presentation/catalog/catalog_screen.dart';
import 'presentation/shopping/checkout_sheet.dart';
import 'presentation/shopping/shopping_bloc.dart';
import 'presentation/shopping/shopping_screen.dart';
import 'presentation/widgets/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final connection = AppConnection(Connectivity());
  await connection.start();
  final store = LocalStore(SharedPreferencesAsync());
  final market = MockMarket(store, connection, rootBundle);
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogRepository>(
          create: (_) => CachedCatalog(market, store, connection),
        ),
        RepositoryProvider.value(value: market),
      ],
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
        child: const GrocerMate(),
      ),
    ),
  );
}

class GrocerMate extends StatelessWidget {
  const GrocerMate({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'GrocerMate',
    theme: marketTheme(Brightness.light),
    darkTheme: marketTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    builder: (context, child) =>
        BlocSelector<AppConnection, AppNetworkState, bool>(
          selector: (state) => state.online,
          builder: (context, online) => Column(
            children: [
              if (!online)
                Material(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 17,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Offline mode · browsing the cached catalog',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: child!),
            ],
          ),
        ),
    home: const _MarketHome(),
  );
}

class _MarketHome extends StatefulWidget {
  const _MarketHome();

  @override
  State<_MarketHome> createState() => _MarketHomeState();
}

class _MarketHomeState extends State<_MarketHome> {
  int _tab = 0;

  void _browse() => setState(() => _tab = 0);

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _DemoSettings(),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<AppConnection, AppNetworkState>(
        listenWhen: (before, after) => before.online != after.online,
        listener: (context, _) =>
            context.read<CatalogBloc>().add(const CatalogRefreshed()),
      ),
      BlocListener<ShoppingBloc, ShopState>(
        listenWhen: (before, after) =>
            before.notice != after.notice && after.notice != null,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.notice!),
              duration: const Duration(seconds: 2),
            ),
          ),
      ),
      BlocListener<ShoppingBloc, ShopState>(
        listenWhen: (before, after) =>
            before.review != after.review && after.review != null,
        listener: (context, state) {
          setState(() => _tab = 1);
          unawaited(
            showCheckoutReview(context, state.data!.pending!, state.review!),
          );
        },
      ),
      BlocListener<ShoppingBloc, ShopState>(
        listenWhen: (before, after) =>
            before.data != null &&
            before.data?.lastOrder != after.data?.lastOrder &&
            after.data?.lastOrder != null,
        listener: (context, state) {
          context.read<CatalogBloc>().add(const CatalogRefreshed());
          if (_tab != 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order ${state.data!.lastOrder!.id} placed.'),
              ),
            );
          }
        },
      ),
    ],
    child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _tab == 0 ? 1120 : 680),
            child: IndexedStack(
              index: _tab,
              children: [
                CatalogScreen(onSettings: _settings),
                ShoppingScreen(
                  saved: false,
                  onBrowse: _browse,
                  onSettings: _settings,
                ),
                ShoppingScreen(
                  saved: true,
                  onBrowse: _browse,
                  onSettings: _settings,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          BlocSelector<ShoppingBloc, ShopState, ({int cart, int saved})>(
            selector: (state) => (
              cart:
                  state.data?.cart.fold<int>(
                    0,
                    (total, line) => total + line.quantity,
                  ) ??
                  0,
              saved: state.data?.saved.length ?? 0,
            ),
            builder: (context, count) => NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront_rounded),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Badge.count(
                    count: count.cart,
                    isLabelVisible: count.cart > 0,
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  label: 'Cart',
                ),
                NavigationDestination(
                  icon: Badge.count(
                    count: count.saved,
                    isLabelVisible: count.saved > 0,
                    child: const Icon(Icons.bookmark_border_rounded),
                  ),
                  label: 'Saved',
                ),
              ],
            ),
          ),
    ),
  );
}

class _DemoSettings extends StatefulWidget {
  const _DemoSettings();
  @override
  State<_DemoSettings> createState() => _DemoSettingsState();
}

class _DemoSettingsState extends State<_DemoSettings> {
  @override
  Widget build(BuildContext context) {
    final connection = context.read<AppConnection>();
    final market = context.read<MockMarket>();
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Demo settings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Next checkout scenario', style: theme.textTheme.titleSmall),
            RadioGroup<CheckoutScenario>(
              groupValue: market.scenario,
              onChanged: (value) {
                if (value != null) setState(() => market.scenario = value);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final scenario in CheckoutScenario.values)
                    RadioListTile<CheckoutScenario>(
                      value: scenario,
                      title: Text(scenario.label),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            BlocSelector<AppConnection, AppNetworkState, bool>(
              selector: (state) => state.simulated,
              builder: (context, simulated) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Simulate offline'),
                subtitle: const Text(
                  'Test cached browsing and queued purchases.',
                ),
                value: simulated,
                onChanged: (value) {
                  if (!value) Navigator.of(context).pop();
                  connection.simulateOffline(value);
                },
              ),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
