import 'package:connectivity_plus/connectivity_plus.dart';

import 'connection_checker.dart';

class PlatformConnectionChecker implements ConnectionChecker {
  const PlatformConnectionChecker();

  @override
  Future<bool> get isConnected async =>
      (await Connectivity().checkConnectivity()).hasConnectivity;

  @override
  Stream<bool> get status async* {
    yield await isConnected;
    yield* Connectivity().onConnectivityChanged.map(
      (result) => result.hasConnectivity,
    );
  }
}
