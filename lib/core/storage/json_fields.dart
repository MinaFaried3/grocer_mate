typedef Json = Map<String, dynamic>;

String readText(Json json, String key) => requireText(json[key], key);

String requireText(Object? input, String key) {
  if (input case String value when value.trim().isNotEmpty) return value;
  throw FormatException('Expected nonempty text for $key.');
}

int readInt(Json json, String key, {int minimum = 0}) =>
    requireInt(json[key], key, minimum: minimum);

int requireInt(Object? input, String key, {int minimum = 0}) {
  if (input case int value when value >= minimum) return value;
  throw FormatException('Expected an integer of at least $minimum for $key.');
}

int readCents(Json json, String key) => requireCents(json[key], key);

int requireCents(Object? input, String key) {
  if (input case num value when value.isFinite && value >= 0) {
    return (value * 100).round();
  }
  throw FormatException('Expected a nonnegative amount for $key.');
}
