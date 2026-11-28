import 'package:equatable/equatable.dart';

class const AppConnectionState({
  required final bool? connected,
  required final bool offlineMode,
}) extends Equatable {
  bool get online => connected == true && !offlineMode;

  @override
  List<Object?> get props => [connected, offlineMode];
}
