import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'features/account/cloud_backend.dart';
import 'features/reminders/task_reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeCloudBackendFromEnvironment();
  await SystemTaskReminderScheduler.instance.initialize();
  runApp(const ProviderScope(child: AppShell()));
}
