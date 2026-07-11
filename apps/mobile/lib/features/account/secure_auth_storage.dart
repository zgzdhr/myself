import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write({required String key, required String value});

  Future<void> delete(String key);

  Future<bool> containsKey(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage({
    required this.storage,
    required this.persistSessionKey,
  });

  final SecureKeyValueStore storage;
  final String persistSessionKey;

  @override
  Future<String?> accessToken() => storage.read(persistSessionKey);

  @override
  Future<bool> hasAccessToken() => storage.containsKey(persistSessionKey);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) {
    return storage.write(key: persistSessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() => storage.delete(persistSessionKey);
}

class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  SecureGotrueAsyncStorage({
    required this.storage,
    this.keyPrefix = 'myself.pkce.',
  });

  final SecureKeyValueStore storage;
  final String keyPrefix;

  @override
  Future<String?> getItem({required String key}) => storage.read(_key(key));

  @override
  Future<void> removeItem({required String key}) {
    return storage.delete(_key(key));
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return storage.write(key: _key(key), value: value);
  }

  String _key(String key) => '$keyPrefix$key';
}

FlutterSecureStorage createPrivateTrialSecureStorage() {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageNamespace: 'myself.auth',
      migrateWithBackup: false,
    ),
    iOptions: IOSOptions(
      accountName: 'myself.auth',
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );
}

String supabasePersistSessionKeyFor(String supabaseUrl) {
  final projectRef = Uri.parse(supabaseUrl).host.split('.').first;
  return 'sb-$projectRef-auth-token';
}
