import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';
import '../../domain/task_status.dart';
import '../reminders/task_reminder_scheduler.dart';
import 'delete_confirmation.dart';
import 'task_time_formatter.dart';

class TasksScreen extends StatefulWidget {
  TasksScreen({
    required this.database,
    this.nowProvider = DateTime.now,
    TaskReminderScheduler? taskReminderScheduler,
    this.refreshVersion = 0,
    this.onRecordsChanged,
    super.key,
  }) : taskReminderCoordinator = TaskReminderCoordinator(
         scheduler: taskReminderScheduler ?? const NoopTaskReminderScheduler(),
       );

  final AppDatabase database;
  final DateTime Function() nowProvider;
  final TaskReminderCoordinator taskReminderCoordinator;
  final int refreshVersion;
  final VoidCallback? onRecordsChanged;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<_TaskViewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion ||
        oldWidget.database != widget.database) {
      _dataFuture = _load();
    }
  }

  Future<_TaskViewData> _load() async {
    final tasks = await widget.database.getVisibleTasks();
    final ids = tasks.map((t) => t.sourceExtractedItemId).toList();
    final sourceTexts = await widget.database.getSourceTextsByExtractedItemIds(
      ids,
    );
    return _TaskViewData(tasks: tasks, sourceTexts: sourceTexts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务')),
      body: FutureBuilder<_TaskViewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.tasks.isEmpty) {
            return const Center(child: Text('暂无任务'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final task in data.tasks)
                _TaskCard(
                  task: task,
                  sourceText: data.sourceTexts[task.sourceExtractedItemId],
                  now: widget.nowProvider(),
                  onEdit: () => _edit(task),
                  onDelete: () => _delete(task),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(Task task) async {
    final result = await showDialog<_TaskEditResult>(
      context: context,
      builder: (context) => _EditTaskDialog(
        initialTitle: task.title,
        initialDescription: task.description,
        initialDueTimeText: task.dueTimeText,
        initialDueTime: task.dueTime,
        now: widget.nowProvider(),
      ),
    );

    if (result == null) return;

    await widget.database.updateTaskById(
      id: task.id,
      title: result.title,
      description: result.description,
      dueTimeText: result.dueTimeText,
      dueTime: result.dueTime,
      updatedAt: widget.nowProvider(),
    );
    await widget.taskReminderCoordinator.sync(
      taskId: task.id,
      title: result.title,
      dueTime: result.dueTime,
      isActive: TaskStatus.fromValue(task.taskStatus) == TaskStatus.active,
      now: widget.nowProvider(),
    );
    _refresh();
    widget.onRecordsChanged?.call();
  }

  Future<void> _delete(Task task) async {
    final confirmed = await confirmDeleteMemoryRecord(
      context: context,
      title: '删除任务？',
      content: '删除后，这条任务不会再参与首页建议。',
    );
    if (!confirmed) {
      return;
    }

    await widget.database.markTaskDeleted(
      id: task.id,
      updatedAt: widget.nowProvider(),
    );
    await widget.taskReminderCoordinator.sync(
      taskId: task.id,
      title: task.title,
      dueTime: null,
      isActive: false,
      now: widget.nowProvider(),
    );
    _refresh();
    widget.onRecordsChanged?.call();
  }

  void _refresh() {
    setState(() {
      _dataFuture = _load();
    });
  }
}

class _TaskViewData {
  const _TaskViewData({required this.tasks, required this.sourceTexts});

  final List<Task> tasks;
  final Map<String, String> sourceTexts;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.sourceText,
    required this.now,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final String? sourceText;
  final DateTime now;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final taskStatus = TaskStatus.fromValue(task.taskStatus);
    final isDone = taskStatus != TaskStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? Theme.of(context).textTheme.bodyLarge?.color
                                ?.withValues(alpha: 0.55)
                          : null,
                      decoration: taskStatus == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (taskStatus != TaskStatus.active) ...[
                  _TaskStatusBadge(status: taskStatus),
                  const SizedBox(width: 8),
                ],
                _PriorityBadge(priority: task.priority),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    formatTaskDueText(
                      dueTime: task.dueTime,
                      dueTimeText: task.dueTimeText,
                      now: now,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (sourceText != null && sourceText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '来源：$sourceText',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onEdit, child: const Text('编辑')),
                const SizedBox(width: 8),
                TextButton(onPressed: onDelete, child: const Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStatusBadge extends StatelessWidget {
  const _TaskStatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      TaskStatus.active => '待处理',
      TaskStatus.completed => '已完成',
      TaskStatus.cancelled => '已取消',
    };
    final color = switch (status) {
      TaskStatus.active => Theme.of(context).colorScheme.primary,
      TaskStatus.completed => Colors.green,
      TaskStatus.cancelled => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final label = switch (priority) {
      'high' => '高',
      'low' => '低',
      _ => '中',
    };
    final color = switch (priority) {
      'high' => Colors.red,
      'low' => Colors.grey,
      _ => Colors.orange,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskEditResult {
  const _TaskEditResult({
    required this.title,
    this.description,
    this.dueTimeText,
    this.dueTime,
  });

  final String title;
  final String? description;
  final String? dueTimeText;
  final DateTime? dueTime;
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({
    required this.initialTitle,
    required this.now,
    this.initialDescription,
    this.initialDueTimeText,
    this.initialDueTime,
  });

  final String initialTitle;
  final DateTime now;
  final String? initialDescription;
  final String? initialDueTimeText;
  final DateTime? initialDueTime;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  DateTime? _selectedDueTime;
  String? _dueTimeText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _selectedDueTime = widget.initialDueTime;
    _dueTimeText = widget.initialDueTimeText;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = _selectedDueTime ?? widget.now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(widget.now.year - 1),
      lastDate: DateTime(widget.now.year + 5),
    );
    if (pickedDate == null) return;

    final time = TimeOfDay.fromDateTime(_selectedDueTime ?? widget.now);
    setState(() {
      _selectedDueTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final current = _selectedDueTime ?? widget.now;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDueTime = DateTime(
        current.year,
        current.month,
        current.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _clearDueTime() {
    setState(() {
      _selectedDueTime = null;
      _dueTimeText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑任务'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '截止时间',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                formatTaskDueText(
                  dueTime: _selectedDueTime,
                  dueTimeText: _dueTimeText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('选择日期'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: const Text('选择时间'),
                ),
                TextButton.icon(
                  onPressed: _clearDueTime,
                  icon: const Icon(Icons.clear),
                  label: const Text('清除时间'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
            Navigator.of(context).pop(
              _TaskEditResult(
                title: title,
                description: _descController.text.trim().isEmpty
                    ? null
                    : _descController.text.trim(),
                dueTimeText: _dueTimeText,
                dueTime: _selectedDueTime,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
