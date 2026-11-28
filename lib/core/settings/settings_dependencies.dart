import 'package:grocer_mate/core/injection/injector.dart';
import 'package:grocer_mate/core/mock/mock_dependencies.dart';

import 'checkout_settings.dart';

extension SettingsDependencies on Injector {
  CheckoutSettings getCheckoutSettings() =>
      singleton(() => CheckoutSettings(mockMarket));
}
