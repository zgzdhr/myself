import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'features/account/cloud_backend.dart';
import 'features/reminders/task_reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeBeforeFirstFrame();
  runApp(const ProviderScope(child: AppShell()));
}

Future<void> _initializeBeforeFirstFrame() async {
  await _tryInitialize(
    label: 'cloud backend',
    timeout: const Duration(seconds: 8),
    action: initializeCloudBackendFromEnvironment,
  );
  await _tryInitialize(
    label: 'task reminders',
    timeout: const Duration(seconds: 5),
    action: SystemTaskReminderScheduler.instance.initialize,
  );
}

Future<void> _tryInitialize({
  required String label,
  required Duration timeout,
  required Future<void> Function() action,
}) async {
  try {
    await action().timeout(timeout);
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'app startup',
        context: ErrorDescription('while initializing $label'),
      ),
    );
  }
}
