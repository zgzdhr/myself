import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TaskReminderRequest {
  const TaskReminderRequest({
    required this.taskId,
    required this.title,
    required this.dueTime,
  });

  final String taskId;
  final String title;
  final DateTime dueTime;
}

abstract interface class TaskReminderScheduler {
  Future<void> schedule(TaskReminderRequest request);

  Future<void> cancel(String taskId);
}

class NoopTaskReminderScheduler implements TaskReminderScheduler {
  const NoopTaskReminderScheduler();

  @override
  Future<void> schedule(TaskReminderRequest request) async {}

  @override
  Future<void> cancel(String taskId) async {}
}

class SystemTaskReminderScheduler implements TaskReminderScheduler {
  SystemTaskReminderScheduler._();

  static final SystemTaskReminderScheduler instance =
      SystemTaskReminderScheduler._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  var _initialized = false;
  var _permissionRequested = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      'ic_stat_task_reminder',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> schedule(TaskReminderRequest request) async {
    await initialize();
    await _requestPermissionsIfNeeded();

    await _notifications.zonedSchedule(
      id: _notificationIdForTask(request.taskId),
      title: '任务提醒',
      body: request.title,
      scheduledDate: tz.TZDateTime.from(request.dueTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          '任务提醒',
          channelDescription: '已确认任务的本地提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'task_reminders'),
      ),
      payload: request.taskId,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(String taskId) async {
    await initialize();
    await _notifications.cancel(id: _notificationIdForTask(taskId));
  }

  Future<void> _requestPermissionsIfNeeded() async {
    if (_permissionRequested || kIsWeb) {
      return;
    }

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    }

    _permissionRequested = true;
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }

    tz.initializeTimeZones();
    if (Platform.isWindows) {
      return;
    }

    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
  }

  int _notificationIdForTask(String taskId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in taskId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class TaskReminderCoordinator {
  const TaskReminderCoordinator({required this.scheduler});

  final TaskReminderScheduler scheduler;

  Future<void> sync({
    required String taskId,
    required String title,
    required DateTime? dueTime,
    required bool isActive,
    required DateTime now,
  }) {
    if (isActive && dueTime != null && dueTime.isAfter(now)) {
      return scheduler.schedule(
        TaskReminderRequest(taskId: taskId, title: title, dueTime: dueTime),
      );
    }

    return scheduler.cancel(taskId);
  }
}
