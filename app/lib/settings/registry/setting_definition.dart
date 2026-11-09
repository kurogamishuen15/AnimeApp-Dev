import 'dart:convert';

typedef SettingEncoder<T> = Object? Function(T value);
typedef SettingDecoder<T> = T Function(Object? jsonValue);
typedef SettingValidator<T> = bool Function(T value);

/// Typed contract for one explicitly registered, non-secret preference.
class SettingDefinition<T> {
  SettingDefinition({
    required this.key,
    required this.owner,
    required this.defaultValue,
    required this.encode,
    required this.decode,
    required this.isValid,
  }) {
    if (key.trim().isEmpty || owner.trim().isEmpty) {
      throw ArgumentError('A setting requires a stable key and owner.');
    }
    if (!isValid(defaultValue)) {
      throw ArgumentError('The default value does not satisfy its validator.');
    }
  }

  final String key;
  final String owner;
  final T defaultValue;
  final SettingEncoder<T> encode;
  final SettingDecoder<T> decode;
  final SettingValidator<T> isValid;

  String encodeJson(T value) {
    if (!isValid(value)) {
      throw const FormatException('Setting value failed validation.');
    }
    return jsonEncode(encode(value));
  }

  T decodeJson(String json) {
    final Object? decodedJson = jsonDecode(json);
    final T decodedValue = decode(decodedJson);
    if (!isValid(decodedValue)) {
      throw const FormatException('Stored setting failed validation.');
    }
    return decodedValue;
  }
}
