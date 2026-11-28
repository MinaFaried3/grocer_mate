import 'package:flutter/services.dart';

import '../injection/dependencies.dart';
import '../injection/injector.dart';
import 'mock_market.dart';

extension MockDependencies on Injector {
  MockMarket get mockMarket =>
      singleton(() => MockMarket(localStorage, rootBundle.loadString));
}
