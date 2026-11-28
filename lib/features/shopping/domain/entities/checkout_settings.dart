enum CheckoutUpdate(final String label) {
  normal('Normal checkout'),
  prices('Price changes'),
  stock('Stock changes'),
  mixed('Price and stock changes'),
  partial('Partial fulfillment'),
}

class CheckoutSettings {
  CheckoutSettings({this.scenario = 'normal'});

  String scenario;

  CheckoutUpdate get nextCheckoutUpdate =>
      CheckoutUpdate.values.byName(scenario);

  set nextCheckoutUpdate(CheckoutUpdate value) => scenario = value.name;
}
