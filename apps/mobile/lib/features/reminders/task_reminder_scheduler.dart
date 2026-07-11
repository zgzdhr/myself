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
    this.notificationTitle = '任务提醒',
    this.channelId = 'task_reminders',
    this.channelName = '任务提醒',
    this.channelDescription = '已确认任务的本地提醒',
  });

  final String taskId;
  final String title;
  final DateTime dueTime;
  final String notificationTitle;
  final String channelId;
  final String channelName;
  final String channelDescription;
}

abstract interface class TaskReminderScheduler {
  Future<bool?> notificationsEnabled();

  Future<bool?> requestPermissions();

  Future<void> schedule(TaskReminderRequest request);

  Future<void> cancel(String taskId);
}

class NoopTaskReminderScheduler implements TaskReminderScheduler {
  const NoopTaskReminderScheduler();

  @override
  Future<bool?> notificationsEnabled() async => false;

  @override
  Future<bool?> requestPermissions() async => false;

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
  Future<bool?> notificationsEnabled() async {
    await initialize();
    if (kIsWeb) {
      return null;
    }
    if (Platform.isAndroid) {
      return _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    }
    return null;
  }

  @override
  Future<bool?> requestPermissions() async {
    await initialize();
    final granted = await _requestPermissionsIfNeeded(force: true);
    return granted ?? notificationsEnabled();
  }

  @override
  Future<void> schedule(TaskReminderRequest request) async {
    await initialize();
    await _requestPermissionsIfNeeded();

    await _notifications.zonedSchedule(
      id: _notificationIdForTask(request.taskId),
      title: request.notificationTitle,
      body: request.title,
      scheduledDate: tz.TZDateTime.from(request.dueTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          request.channelId,
          request.channelName,
          channelDescription: request.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: request.channelId),
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

  Future<bool?> _requestPermissionsIfNeeded({bool force = false}) async {
    if ((!force && _permissionRequested) || kIsWeb) {
      return null;
    }

    bool? granted;
    if (Platform.isAndroid) {
      granted = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      granted = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    }

    _permissionRequested = true;
    return granted;
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

class SedentaryReminderCoordinator {
  const SedentaryReminderCoordinator({required this.scheduler});

  final TaskReminderScheduler scheduler;

  Future<void> schedule({
    required String sessionId,
    required DateTime reminderAt,
    required DateTime now,
  }) {
    if (!reminderAt.isAfter(now)) {
      return scheduler.cancel(_notificationKey(sessionId));
    }

    return scheduler.schedule(
      TaskReminderRequest(
        taskId: _notificationKey(sessionId),
        notificationTitle: '久坐提醒',
        title: '已经坐了大约 1 小时，可以站起来活动一下。',
        dueTime: reminderAt,
        channelId: 'sedentary_reminders',
        channelName: '久坐提醒',
        channelDescription: '手动久坐会话的活动提醒',
      ),
    );
  }

  Future<void> cancel(String sessionId) {
    return scheduler.cancel(_notificationKey(sessionId));
  }

  String _notificationKey(String sessionId) => 'sedentary:$sessionId';
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
