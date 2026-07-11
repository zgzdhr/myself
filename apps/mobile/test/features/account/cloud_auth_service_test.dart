import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/cloud_auth_service.dart';

void main() {
  test(
    'disabled cloud auth reports not configured and blocks login calls',
    () async {
      const service = DisabledCloudAuthService();

      expect(service.currentState.isConfigured, isFalse);
      expect(service.currentState.isSignedIn, isFalse);
      expect(service.currentState.displayName, '未配置云端');

      await expectLater(
        service.watchAuthState(),
        emits(const TypeMatcher<CloudAuthState>()),
      );
      expect(
        () => service.sendEmailOtp('user@example.com'),
        throwsA(isA<CloudAuthNotConfiguredException>()),
      );
      expect(
        () => service.deleteAccount(),
        throwsA(isA<CloudAuthNotConfiguredException>()),
      );
    },
  );
}
