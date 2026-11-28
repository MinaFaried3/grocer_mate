import 'package:grocer_mate/core/mock/mock_market.dart';

enum CheckoutUpdate(final String label) {
  normal('Normal checkout'),
  prices('Price changes'),
  stock('Stock changes'),
  mixed('Price and stock changes'),
  partial('Partial fulfillment'),
}

class CheckoutSettings(final MockMarket market) {
  CheckoutUpdate get nextCheckoutUpdate =>
      CheckoutUpdate.values.byName(market.checkoutScenario);

  set nextCheckoutUpdate(CheckoutUpdate value) =>
      market.checkoutScenario = value.name;
}
