import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_network_state.dart';
import 'connection.dart';
import 'connectivity_monitor.dart';

class AppConnection(final ConnectivityMonitor _monitor)
    extends Cubit<AppNetworkState>
    implements Connection {
  this : super(const .new(online: true, offlineMode: false));

  StreamSubscription<bool>? _subscription;
  bool _hasTransport = true;

  @override
  bool get online => state.online;

  @override
  Stream<bool> get changes => stream.map((value) => value.online).distinct();

  Future<void> start() async {
    try {
      _hasTransport = await _monitor.checkOnline();
      _publish(state.offlineMode);
      _subscription = _monitor.changes.listen((value) {
        _hasTransport = value;
        _publish(state.offlineMode);
      }, onError: (Object _) {});
    } catch (_) {
      // The local market remains usable if the platform has no monitor.
    }
  }

  void setOfflineMode(bool value) => _publish(value);

  void _publish(bool offlineMode) => emit(
    state.copyWith(
      online: _hasTransport && !offlineMode,
      offlineMode: offlineMode,
    ),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
