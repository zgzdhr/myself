import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/api/api_access_token_provider.dart';
import 'cloud_auth_service.dart';
import 'cloud_sync_service.dart';
import 'secure_auth_storage.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

bool get isCloudBackendConfigured =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

var _cloudBackendInitialized = false;

bool get isCloudBackendAvailable =>
    isCloudBackendConfigured && _cloudBackendInitialized;

Future<void> initializeCloudBackendFromEnvironment() async {
  if (!isCloudBackendConfigured) {
    return;
  }

  final secureStore = FlutterSecureKeyValueStore(
    createPrivateTrialSecureStorage(),
  );
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseLocalStorage(
        storage: secureStore,
        persistSessionKey: supabasePersistSessionKeyFor(supabaseUrl),
      ),
      pkceAsyncStorage: SecureGotrueAsyncStorage(storage: secureStore),
    ),
  );
  _cloudBackendInitialized = true;
}

final cloudAuthServiceProvider = Provider<CloudAuthService>((ref) {
  if (!isCloudBackendAvailable) {
    return const DisabledCloudAuthService();
  }

  return SupabaseCloudAuthService(Supabase.instance.client);
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  if (!isCloudBackendAvailable) {
    return const DisabledCloudSyncService();
  }

  return SupabaseCloudSyncService(Supabase.instance.client);
});

final apiAccessTokenProvider = Provider<ApiAccessTokenProvider>((ref) {
  if (!isCloudBackendAvailable) {
    return const UnavailableApiAccessTokenProvider();
  }

  return SupabaseApiAccessTokenProvider(Supabase.instance.client);
});
