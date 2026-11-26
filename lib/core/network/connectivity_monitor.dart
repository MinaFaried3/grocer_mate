abstract interface class ConnectivityMonitor {
  Future<bool> checkOnline();
  Stream<bool> get changes;
}
