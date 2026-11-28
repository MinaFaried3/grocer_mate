abstract interface class ConnectionChecker {
  Future<bool> get isConnected;

  /// Emits the current connection status, followed by updates.
  Stream<bool> get status;
}
