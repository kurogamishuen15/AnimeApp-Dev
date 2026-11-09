import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import 'setting_definition.dart';

/// Validates unique definitions and resolves them without exposing storage.
class SettingsRegistry {
  SettingsRegistry();
  final Map<String, Object> _definitions = {};

  void register<T>(SettingDefinition<T> definition) {
    if (_definitions.containsKey(definition.key)) {
      throw ArgumentError('Duplicate setting key.');
    }
    _definitions[definition.key] = definition;
  }

  Result<SettingDefinition<T>> resolve<T>(SettingDefinition<T> definition) {
    final Object? registered = _definitions[definition.key];
    if (registered is! SettingDefinition<T> ||
        !identical(registered, definition)) {
      return const Failure(
        ValidationAppError('Setting is not registered with this definition.'),
      );
    }
    return Success(registered);
  }
}
