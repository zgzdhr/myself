# Release signing and application identity

Date: 2026-07-11

## Current gate

Debug and no-codesign builds are available for private verification. Public
release builds are intentionally blocked until a permanent application name,
Android application id, iOS bundle id, and signing identities are chosen.

The previous Android configuration signed release artifacts with the debug
key. That fallback has been removed. A release task now fails if
`android/key.properties` is absent.

## Android signing

1. Copy `apps/mobile/android/key.properties.example` to
   `apps/mobile/android/key.properties`.
2. Create the release keystore outside Git and set its relative path in the
   local properties file.
3. Store the keystore and passwords in a password manager and an offline
   backup. Losing the signing key can prevent future app updates.
4. Build the final AAB only after the permanent application id is set:

```bash
flutter build appbundle --release \
  --dart-define=PARSER_MODE=http \
  --dart-define=PARSER_BASE_URL=https://<secured-api-host> \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=APP_LOCK_ENABLED=true
```

Never commit `key.properties`, a `.jks`/`.keystore` file, or passwords.

## iOS signing

1. Copy `apps/mobile/ios/Flutter/Signing.xcconfig.example` to
   `apps/mobile/ios/Flutter/Signing.xcconfig`.
2. Set the Apple Developer Team ID locally.
3. Choose the same permanent product identity used for the App Store record.
4. Let Xcode manage the certificate/provisioning profile, or configure the
   equivalent protected CI secrets later.

The local signing file is optional for no-codesign verification and ignored by
Git. Certificates and provisioning profiles must stay in Keychain or the CI
secret store.
