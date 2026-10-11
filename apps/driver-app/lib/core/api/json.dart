/// A decoded JSON object. Every API payload is parsed through these helpers so a
/// shape mismatch fails loudly with the field name, instead of leaking `dynamic`.
typedef JsonMap = Map<String, Object?>;

class JsonShapeError implements Exception {
  JsonShapeError(this.message);
  final String message;
  @override
  String toString() => 'JsonShapeError: $message';
}

extension JsonRead on JsonMap {
  T _get<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    throw JsonShapeError(
      'Expected $key to be $T, got ${value.runtimeType}: $value',
    );
  }

  String str(String key) => _get<String>(key);
  String? strOrNull(String key) => _get<String?>(key);
  bool boolean(String key) => _get<bool>(key);
  int integer(String key) => _get<num>(key).toInt();
  int? intOrNull(String key) => _get<num?>(key)?.toInt();
  double number(String key) => _get<num>(key).toDouble();
  double? numberOrNull(String key) => _get<num?>(key)?.toDouble();
  DateTime date(String key) => DateTime.parse(str(key));
  DateTime? dateOrNull(String key) {
    final value = strOrNull(key);
    return value == null ? null : DateTime.parse(value);
  }

  JsonMap obj(String key) => asJsonMap(this[key], key);
  JsonMap? objOrNull(String key) =>
      this[key] == null ? null : asJsonMap(this[key], key);
  List<JsonMap> objects(String key) =>
      _get<List<Object?>>(key).map((item) => asJsonMap(item, key)).toList();
  List<String> strings(String key) =>
      _get<List<Object?>>(key).map((item) => item as String).toList();
  List<int> integers(String key) =>
      _get<List<Object?>>(key).map((item) => (item! as num).toInt()).toList();
}

JsonMap asJsonMap(Object? value, [String context = 'value']) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  throw JsonShapeError('Expected $context to be an object, got $value');
}

/// A JSON array of objects.
List<JsonMap> jsonList(Object? json) {
  if (json is! List<Object?>) {
    throw JsonShapeError('Expected a list, got $json');
  }
  return json.map(asJsonMap).toList();
}
