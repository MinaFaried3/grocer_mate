import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_network_state.dart';
import 'connection.dart';

class AppConnection extends Cubit<AppNetworkState> implements Connection {
  AppConnection(this._connectivity)
    : super(const AppNetworkState(online: true, simulated: false));

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _hasTransport = true;

  @override
  bool get online => state.online;

  @override
  Stream<bool> get changes => stream.map((value) => value.online).distinct();

  Future<void> start() async {
    try {
      _hasTransport = _connected(await _connectivity.checkConnectivity());
      _publish(state.simulated);
      _subscription = _connectivity.onConnectivityChanged.listen((value) {
        _hasTransport = _connected(value);
        _publish(state.simulated);
      }, onError: (Object _) {});
    } catch (_) {
      // The mock service remains usable if the platform has no monitor.
    }
  }

  bool _connected(List<ConnectivityResult> value) =>
      value.any((result) => result != ConnectivityResult.none);

  void simulateOffline(bool value) => _publish(value);

  void _publish(bool simulated) => emit(
    state.copyWith(online: _hasTransport && !simulated, simulated: simulated),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
