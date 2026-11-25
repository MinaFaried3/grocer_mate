abstract interface class Connection {
  bool get online;
  Stream<bool> get changes;
}

class OfflineException implements Exception {
  const OfflineException();
}
