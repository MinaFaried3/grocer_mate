class const AppNetworkState({
  required final bool online,
  required final bool simulated,
}) {
  AppNetworkState copyWith({bool? online, bool? simulated}) => .new(
    online: online ?? this.online,
    simulated: simulated ?? this.simulated,
  );

  @override
  bool operator ==(Object other) =>
      other is AppNetworkState &&
      online == other.online &&
      simulated == other.simulated;

  @override
  int get hashCode => Object.hash(online, simulated);
}
