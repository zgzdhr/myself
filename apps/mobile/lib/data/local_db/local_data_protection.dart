import 'dart:io';

import 'package:flutter/services.dart';

const _localDataProtectionChannel = MethodChannel(
  'com.example.mobile/local_data_protection',
);

Future<void> excludeLocalDatabaseFromDeviceBackup(String databasePath) async {
  if (!Platform.isIOS) return;

  try {
    await _localDataProtectionChannel.invokeMethod<void>('excludeFromBackup', {
      'path': databasePath,
    });
  } on MissingPluginException {
    // The database must remain usable if the host app has not registered the
    // iOS channel yet. The native build verification catches that integration.
  } on PlatformException {
    // Do not block local access to a user's data because a backup exclusion
    // request failed; surface this in native trial verification instead.
  }
}
