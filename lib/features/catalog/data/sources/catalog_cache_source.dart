import 'package:grocer_mate/core/storage/local_storage.dart';

import '../models/catalog_cache.dart';

class const CatalogCacheSource(final LocalStorage _store) {
  static const _key = 'catalog_v2';

  Future<CatalogCache?> read() async {
    final json = await _store.read(_key);
    return json == null ? null : CatalogCache.fromJson(json);
  }

  Future<void> write(CatalogCache cache) => _store.write(_key, cache.toJson());
}
