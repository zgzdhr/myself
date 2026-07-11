import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

const appLockEnabled = bool.fromEnvironment(
  'APP_LOCK_ENABLED',
  defaultValue: kReleaseMode,
);

enum AppLockResult { unlocked, denied, unavailable }

abstract interface class AppLockService {
  Future<AppLockResult> unlock();
}

class LocalDeviceAppLockService implements AppLockService {
  LocalDeviceAppLockService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<AppLockResult> unlock() async {
    try {
      if (!await _localAuthentication.isDeviceSupported()) {
        return AppLockResult.unavailable;
      }

      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: '请验证身份后继续使用个人记忆与行动整理。',
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate ? AppLockResult.unlocked : AppLockResult.denied;
    } on LocalAuthException {
      return AppLockResult.unavailable;
    } catch (_) {
      return AppLockResult.unavailable;
    }
  }
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    required this.child,
    this.enabled = appLockEnabled,
    this.appLockService,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final AppLockService? appLockService;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late final AppLockService _appLockService;
  late bool _isLocked;
  var _isVerifying = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLockService = widget.appLockService ?? LocalDeviceAppLockService();
    _isLocked = widget.enabled;
    if (_isLocked) {
      _unlock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled || !mounted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setState(() {
        _isLocked = true;
        _message = null;
      });
    }
  }

  Future<void> _unlock() async {
    if (!widget.enabled || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _message = null;
    });
    final result = await _appLockService.unlock();
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      switch (result) {
        case AppLockResult.unlocked:
          _isLocked = false;
        case AppLockResult.denied:
          _isLocked = true;
          _message = '未完成设备验证，请重试。';
        case AppLockResult.unavailable:
          _isLocked = true;
          _message = '此设备没有可用的屏幕锁或生物识别验证。请先在系统设置中启用后再使用。';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !_isLocked) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 44),
              const SizedBox(height: 16),
              Text(
                '请先解锁',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text('你的任务、状态和个人记忆会在设备验证后显示。', textAlign: TextAlign.center),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isVerifying ? null : _unlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: Text(_isVerifying ? '正在验证…' : '使用设备验证解锁'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
