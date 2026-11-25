import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/theme/market_theme.dart';

import 'market_home.dart';
import 'mock_market.dart';
import 'offline_banner.dart';

class const GrocerMateApp({super.key, required final MockMarket market})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'GrocerMate',
    theme: marketTheme(Brightness.light),
    darkTheme: marketTheme(Brightness.dark),
    builder: (context, child) => Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child!),
      ],
    ),
    home: MarketHome(market: market),
  );
}
