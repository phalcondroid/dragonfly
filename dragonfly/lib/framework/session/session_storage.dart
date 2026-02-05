import 'dart:convert';

/// Abstract interface for session storage.
///
/// Implement this to provide custom storage backends
/// (SharedPreferences, Hive, SecureStorage, etc.)
abstract class SessionStorage {
  /// Get a string value.
  Future<String?> getString(String key);

  /// Set a string value.
  Future<void> setString(String key, String value);

  /// Get a list of strings.
  Future<List<String>?> getStringList(String key);

  /// Set a list of strings.
  Future<void> setStringList(String key, List<String> value);

  /// Get an integer value.
  Future<int?> getInt(String key);

  /// Set an integer value.
  Future<void> setInt(String key, int value);

  /// Remove a value.
  Future<void> remove(String key);

  /// Clear all session data.
  Future<void> clear();
}

/// In-memory session storage (for testing or non-persistent sessions).
class InMemorySessionStorage implements SessionStorage {
  final Map<String, dynamic> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  Future<List<String>?> getStringList(String key) async =>
      _data[key] as List<String>?;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _data[key] = value;

  @override
  Future<int?> getInt(String key) async => _data[key] as int?;

  @override
  Future<void> setInt(String key, int value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();
}

/// Hive-based session storage implementation.
///
/// Use this with Hive for encrypted, fast local storage.
class HiveSessionStorage implements SessionStorage {
  final dynamic _box; // Hive Box

  HiveSessionStorage(this._box);

  @override
  Future<String?> getString(String key) async => _box.get(key) as String?;

  @override
  Future<void> setString(String key, String value) async =>
      await _box.put(key, value);

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _box.get(key);
    if (value == null) return null;
    if (value is List) return value.cast<String>();
    return null;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      await _box.put(key, value);

  @override
  Future<int?> getInt(String key) async => _box.get(key) as int?;

  @override
  Future<void> setInt(String key, int value) async =>
      await _box.put(key, value);

  @override
  Future<void> remove(String key) async => await _box.delete(key);

  @override
  Future<void> clear() async => await _box.clear();
}

/// JSON-based storage wrapper for storing complex objects.
extension SessionStorageJson on SessionStorage {
  /// Get a JSON-decoded map.
  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Set a JSON-encoded map.
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }
}
