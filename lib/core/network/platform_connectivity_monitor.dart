import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_monitor.dart';

class PlatformConnectivityMonitor implements ConnectivityMonitor {
  final _connectivity = Connectivity();

  @override
  Future<bool> checkOnline() async =>
      _hasTransport(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_hasTransport).distinct();

  bool _hasTransport(List<ConnectivityResult> results) =>
      results.any((result) => result != .none);
}
