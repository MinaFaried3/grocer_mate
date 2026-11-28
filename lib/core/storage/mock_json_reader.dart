import 'dart:convert';

const mockAssetDirectory = 'assets/mock_api';

mixin MockJsonReader {
  Future<String> Function(String) get loadMockAsset;

  final _cache = <String, Future<Object?>>{};

  Future<T> readMockJson<T>(String name) async {
    final read = _cache.putIfAbsent(
      name,
      () async =>
          jsonDecode(await loadMockAsset('$mockAssetDirectory/$name.json')),
    );
    try {
      return (await read) as T;
    } catch (_) {
      if (identical(_cache[name], read)) _cache.remove(name);
      rethrow;
    }
  }
}
