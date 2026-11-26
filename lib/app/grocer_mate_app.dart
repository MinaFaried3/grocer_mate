import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/theme/market_theme.dart';

import 'app_router.dart';
import 'checkout_settings.dart';
import 'offline_banner.dart';

class const GrocerMateApp({
  super.key,
  required final CheckoutSettings checkoutSettings,
}) extends StatefulWidget {
  @override
  State<GrocerMateApp> createState() => _GrocerMateAppState();
}

class _GrocerMateAppState() extends State<GrocerMateApp> {
  late final GoRouter _router = createAppRouter(widget.checkoutSettings);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: _router,
    debugShowCheckedModeBanner: false,
    title: 'GrocerMate',
    theme: MarketThemeFactory.light.build(),
    darkTheme: MarketThemeFactory.dark.build(),
    builder: (context, child) => Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child!),
      ],
    ),
  );
}
