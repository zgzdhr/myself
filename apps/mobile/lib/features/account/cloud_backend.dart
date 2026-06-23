import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_auth_service.dart';
import 'cloud_sync_service.dart';

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

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
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
