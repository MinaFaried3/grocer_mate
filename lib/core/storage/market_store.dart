import 'json_fields.dart';
import 'local_storage.dart';

class const MarketStore(final LocalStorage _storage) {
  static const _key = 'local_market_v1';

  Future<Json> read() async => await _storage.read(_key) ?? {};

  Future<Map> readAvailability() async =>
      (await read())['availability'] as Map? ?? const {};

  Future<void> write(Json market) => _storage.write(_key, market);
}
