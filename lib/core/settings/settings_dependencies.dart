import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/injection/injector.dart';

import 'checkout_settings.dart';

extension SettingsDependencies on Injector {
  CheckoutSettings? getCheckoutSettings() {
    final demo = demoMarketClient;
    return demo == null ? null : singleton(() => CheckoutSettings(demo));
  }
}
