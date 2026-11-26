enum CheckoutUpdate(final String label) {
  normal('Normal checkout'),
  prices('Price changes'),
  stock('Stock changes'),
  mixed('Price and stock changes'),
}

abstract interface class CheckoutSettings {
  CheckoutUpdate get nextCheckoutUpdate;
  set nextCheckoutUpdate(CheckoutUpdate value);
}
