enum CheckoutScenario(final String label) {
  normal('Normal checkout'),
  prices('Price changes'),
  stock('Stock changes'),
  mixed('Price and stock changes'),
}

abstract interface class DemoSettings {
  CheckoutScenario get scenario;
  set scenario(CheckoutScenario value);
}
