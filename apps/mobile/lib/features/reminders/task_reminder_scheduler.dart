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
