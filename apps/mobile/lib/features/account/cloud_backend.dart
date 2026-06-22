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

Future<void> initializeCloudBackendFromEnvironment() async {
  if (!isCloudBackendConfigured) {
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}

final cloudAuthServiceProvider = Provider<CloudAuthService>((ref) {
  if (!isCloudBackendConfigured) {
    return const DisabledCloudAuthService();
  }

  return SupabaseCloudAuthService(Supabase.instance.client);
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  if (!isCloudBackendConfigured) {
    return const DisabledCloudSyncService();
  }

  return SupabaseCloudSyncService(Supabase.instance.client);
});
