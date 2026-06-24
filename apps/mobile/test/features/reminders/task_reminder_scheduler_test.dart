import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reminders/task_reminder_scheduler.dart';

void main() {
  test(
    'schedules active future tasks and cancels inactive or unscheduled tasks',
    () async {
      final scheduler = _RecordingTaskReminderScheduler();
      final coordinator = TaskReminderCoordinator(scheduler: scheduler);
      final now = DateTime(2026, 6, 17, 10);

      await coordinator.sync(
        taskId: 'task-1',
        title: '联系王总',
        dueTime: DateTime(2026, 6, 17, 15),
        isActive: true,
        now: now,
      );
      await coordinator.sync(
        taskId: 'task-2',
        title: '整理资料',
        dueTime: null,
        isActive: true,
        now: now,
      );
      await coordinator.sync(
        taskId: 'task-3',
        title: '取消会议',
        dueTime: DateTime(2026, 6, 17, 16),
        isActive: false,
        now: now,
      );

      expect(scheduler.scheduled.map((request) => request.taskId), ['task-1']);
      expect(scheduler.cancelled, ['task-2', 'task-3']);
    },
  );

  test(
    'cancels reminders for overdue tasks instead of scheduling stale alerts',
    () async {
      final scheduler = _RecordingTaskReminderScheduler();
      final coordinator = TaskReminderCoordinator(scheduler: scheduler);

      await coordinator.sync(
        taskId: 'task-overdue',
        title: '已过期任务',
        dueTime: DateTime(2026, 6, 17, 9),
        isActive: true,
        now: DateTime(2026, 6, 17, 10),
      );

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelled, ['task-overdue']);
    },
  );
}

class _RecordingTaskReminderScheduler implements TaskReminderScheduler {
  final scheduled = <TaskReminderRequest>[];
  final cancelled = <String>[];

  @override
  Future<bool?> notificationsEnabled() async => true;

  @override
  Future<bool?> requestPermissions() async => true;

  @override
  Future<void> schedule(TaskReminderRequest request) async {
    scheduled.add(request);
  }

  @override
  Future<void> cancel(String taskId) async {
    cancelled.add(taskId);
  }
}
