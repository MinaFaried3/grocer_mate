class const AppConnectionState({
  required final bool? connected,
  required final bool offlineMode,
}) {
  bool get online => connected == true && !offlineMode;

  @override
  bool operator ==(Object other) =>
      other is AppConnectionState &&
      connected == other.connected &&
      offlineMode == other.offlineMode;

  @override
  int get hashCode => Object.hash(connected, offlineMode);
}
