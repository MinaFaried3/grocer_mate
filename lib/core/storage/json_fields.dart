typedef Json = Map<String, dynamic>;

String readText(Map<String, dynamic> json, String key) {
  if (json[key] case String value when value.trim().isNotEmpty) return value;
  throw FormatException('Expected nonempty text for $key.');
}

int readInt(Map<String, dynamic> json, String key, {int minimum = 0}) {
  if (json[key] case int value when value >= minimum) return value;
  throw FormatException('Expected an integer of at least $minimum for $key.');
}

int readCents(Map<String, dynamic> json, String key) {
  if (json[key] case num value when value.isFinite && value >= 0) {
    return (value * 100).round();
  }
  throw FormatException('Expected a nonnegative amount for $key.');
}
