import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class CloudAuthState {
  const CloudAuthState({
    required this.isConfigured,
    required this.isSignedIn,
    this.userId,
    this.email,
    this.message,
  });

  const CloudAuthState.notConfigured()
    : isConfigured = false,
      isSignedIn = false,
      userId = null,
      email = null,
      message = 'Supabase 尚未配置';

  final bool isConfigured;
  final bool isSignedIn;
  final String? userId;
  final String? email;
  final String? message;

  String get displayName {
    if (!isConfigured) return '未配置云端';
    if (!isSignedIn) return '未登录';
    return email ?? '已登录账号';
  }

  String get syncLabel {
    if (!isConfigured) return '未配置';
    if (!isSignedIn) return '未登录';
    return '云端已连接';
  }
}

abstract class CloudAuthService {
  const CloudAuthService();

  CloudAuthState get currentState;

  Stream<CloudAuthState> watchAuthState();

  Future<void> sendEmailOtp(String email);

  Future<void> verifyEmailOtp({required String email, required String token});

  Future<void> ensureCloudProfile();

  Future<void> signOut();
}

class DisabledCloudAuthService extends CloudAuthService {
  const DisabledCloudAuthService();

  @override
  CloudAuthState get currentState => const CloudAuthState.notConfigured();

  @override
  Stream<CloudAuthState> watchAuthState() async* {
    yield currentState;
  }

  @override
  Future<void> sendEmailOtp(String email) {
    throw const CloudAuthNotConfiguredException();
  }

  @override
  Future<void> verifyEmailOtp({required String email, required String token}) {
    throw const CloudAuthNotConfiguredException();
  }

  @override
  Future<void> ensureCloudProfile() {
    throw const CloudAuthNotConfiguredException();
  }

  @override
  Future<void> signOut() async {}
}

class SupabaseCloudAuthService extends CloudAuthService {
  const SupabaseCloudAuthService(this._client);

  final SupabaseClient _client;

  @override
  CloudAuthState get currentState =>
      _stateFromSession(_client.auth.currentSession);

  @override
  Stream<CloudAuthState> watchAuthState() async* {
    yield currentState;
    yield* _client.auth.onAuthStateChange.map(
      (state) => _stateFromSession(state.session),
    );
  }

  @override
  Future<void> sendEmailOtp(String email) {
    return _client.auth.signInWithOtp(email: email.trim());
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

  @override
  Future<void> ensureCloudProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const CloudAuthNotSignedInException();
    }

    await _client.from('profiles').upsert({
      'user_id': user.id,
      'email': user.email,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  static CloudAuthState _stateFromSession(Session? session) {
    final user = session?.user;
    if (user == null) {
      return const CloudAuthState(isConfigured: true, isSignedIn: false);
    }

    return CloudAuthState(
      isConfigured: true,
      isSignedIn: true,
      userId: user.id,
      email: user.email,
    );
  }
}

class CloudAuthNotConfiguredException implements Exception {
  const CloudAuthNotConfiguredException();

  @override
  String toString() {
    return 'Supabase 尚未配置。请用 --dart-define 传入 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY。';
  }
}

class CloudAuthNotSignedInException implements Exception {
  const CloudAuthNotSignedInException();

  @override
  String toString() {
    return '用户尚未登录，无法写入云端 profile。';
  }
}
