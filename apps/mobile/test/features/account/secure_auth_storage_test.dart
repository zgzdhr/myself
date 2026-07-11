import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/secure_auth_storage.dart';

void main() {
  test(
    'secure Supabase local storage persists and removes a session',
    () async {
      final store = _MemorySecureStore();
      final storage = SecureSupabaseLocalStorage(
        storage: store,
        persistSessionKey: 'sb-project-auth-token',
      );

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);

      await storage.persistSession('{"access_token":"token"}');
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), '{"access_token":"token"}');

      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    },
  );

  test('secure PKCE storage namespaces verifier values separately', () async {
    final store = _MemorySecureStore();
    final storage = SecureGotrueAsyncStorage(storage: store);

    await storage.setItem(key: 'code-verifier', value: 'verifier');

    expect(await storage.getItem(key: 'code-verifier'), 'verifier');
    expect(await store.read('myself.pkce.code-verifier'), 'verifier');
    await storage.removeItem(key: 'code-verifier');
    expect(await storage.getItem(key: 'code-verifier'), isNull);
  });

  test('uses the Supabase project ref in the secure session key', () {
    expect(
      supabasePersistSessionKeyFor('https://example-ref.supabase.co'),
      'sb-example-ref-auth-token',
    );
  });
}

class _MemorySecureStore implements SecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
