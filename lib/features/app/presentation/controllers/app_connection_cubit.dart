import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/network/connectivity/connection_checker.dart';

import 'app_connection_state.dart';

class AppConnectionCubit(ConnectionChecker checker)
    extends Cubit<AppConnectionState> {
  this : super(const .new(connected: null, offlineMode: false)) {
    _subscription = checker.status.listen(
      _setConnected,
      onError: (Object _) {
        // The local market remains usable if the platform has no checker.
        if (state.connected == null) _setConnected(true);
      },
    );
  }

  late final StreamSubscription<bool> _subscription;

  bool get online => state.online;

  Stream<bool> get changes => stream.map((value) => value.online).distinct();

  void setOfflineMode(bool value) =>
      emit(AppConnectionState(connected: state.connected, offlineMode: value));

  void _setConnected(bool connected) => emit(
    AppConnectionState(connected: connected, offlineMode: state.offlineMode),
  );

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
