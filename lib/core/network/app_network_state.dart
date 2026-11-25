class AppNetworkState {
  const AppNetworkState({required this.online, required this.simulated});

  final bool online;
  final bool simulated;

  AppNetworkState copyWith({bool? online, bool? simulated}) => AppNetworkState(
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
