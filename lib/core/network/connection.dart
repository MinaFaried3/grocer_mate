abstract interface class Connection {
  bool get online;
  Stream<bool> get changes;
}

class const OfflineException() implements Exception;
