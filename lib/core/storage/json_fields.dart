String readText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected nonempty text for $key.');
  }
  return value;
}

int readInt(Map<String, dynamic> json, String key, {int minimum = 0}) {
  final value = json[key];
  if (value is! int || value < minimum) {
    throw FormatException('Expected an integer of at least $minimum for $key.');
  }
  return value;
}
