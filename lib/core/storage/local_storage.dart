abstract interface class LocalStorage {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, Object?> value);
}
