import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/security/app_lock.dart';

void main() {
  testWidgets('keeps app content hidden until device unlock succeeds', (
    tester,
  ) async {
    final service = _FakeAppLockService([
      AppLockResult.denied,
      AppLockResult.unlocked,
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: AppLockGate(
          enabled: true,
          appLockService: service,
          child: const Text('PRIVATE_CONTENT'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRIVATE_CONTENT'), findsNothing);
    expect(find.text('未完成设备验证，请重试。'), findsOneWidget);

    await tester.tap(find.text('使用设备验证解锁'));
    await tester.pumpAndSettle();

    expect(find.text('PRIVATE_CONTENT'), findsOneWidget);
  });

  testWidgets('relocks before backgrounding and stays locked on resume', (
    tester,
  ) async {
    final service = _FakeAppLockService([
      AppLockResult.unlocked,
      AppLockResult.unlocked,
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: AppLockGate(
          enabled: true,
          appLockService: service,
          child: const Text('PRIVATE_CONTENT'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE_CONTENT'), findsOneWidget);

    // Mobile platforms enter `inactive` before `paused`. Locking here lets the
    // framework replace sensitive content before the OS captures a task-switcher
    // snapshot; pumping a frame after `paused` is intentionally disabled.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.text('PRIVATE_CONTENT'), findsNothing);
    expect(find.text('请先解锁'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('PRIVATE_CONTENT'), findsNothing);
    expect(find.text('请先解锁'), findsOneWidget);
  });
}

class _FakeAppLockService implements AppLockService {
  _FakeAppLockService(this.results);

  final List<AppLockResult> results;

  @override
  Future<AppLockResult> unlock() async {
    return results.removeAt(0);
  }
}
