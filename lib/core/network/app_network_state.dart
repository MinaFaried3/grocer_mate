class const AppNetworkState({
  required final bool online,
  required final bool offlineMode,
}) {
  AppNetworkState copyWith({bool? online, bool? offlineMode}) => .new(
    online: online ?? this.online,
    offlineMode: offlineMode ?? this.offlineMode,
  );

  @override
  bool operator ==(Object other) =>
      other is AppNetworkState &&
      online == other.online &&
      offlineMode == other.offlineMode;

  @override
  int get hashCode => Object.hash(online, offlineMode);
}
