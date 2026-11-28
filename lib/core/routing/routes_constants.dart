import 'package:flutter/widgets.dart';

abstract final class RoutesConstants {
  //------------ Navigator Keys ---------------
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final marketNavigatorKey = GlobalKey<NavigatorState>();
  static final shellNavigatorKey = GlobalKey<NavigatorState>();

  //------------ Route Paths & Names ---------------
  static const browse = '/';
  static const product = 'products/:id';
  static const productName = 'product';
  static const cart = '/cart';
  static const saved = '/saved';

  //------------ Route Helpers ---------------
  static String productPath(String id) => '/products/$id';
}
