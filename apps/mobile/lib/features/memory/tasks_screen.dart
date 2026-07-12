import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;

import '../../app/app_visuals.dart';
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
  late Future<_CalendarData> _dataFuture;
  late DateTime _selectedDay;
  var _mode = _CalendarMode.month;
  var _taskFilter = _TaskFilter.all;

  @override
  void initState() {
    super.initState();
    final now = widget.nowProvider();
    _selectedDay = DateTime(now.year, now.month, now.day);
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

  Future<_CalendarData> _load() async {
    final now = widget.nowProvider();
    await widget.database.generateDueRecurringTaskInstances(now: now);

    final monthStart = DateTime(_selectedDay.year, _selectedDay.month);
    final monthEnd = DateTime(_selectedDay.year, _selectedDay.month + 1);
    final weekStart = _selectedDay.subtract(
      Duration(days: _selectedDay.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));
    final rangeStart = monthStart.isBefore(weekStart) ? monthStart : weekStart;
    final rangeEnd = monthEnd.isAfter(weekEnd) ? monthEnd : weekEnd;

    final tasks = await widget.database.getTasksForRange(
      start: rangeStart,
      end: rangeEnd,
    );
    final blocks = await widget.database.getScheduleBlocksForRange(
      start: rangeStart,
      end: rangeEnd,
    );
    final sessions = await widget.database.getSedentarySessionsForRange(
      start: rangeStart,
      end: rangeEnd,
    );

    return _CalendarData(
      monthStart: monthStart,
      weekStart: weekStart,
      tasks: tasks,
      blocks: blocks,
      sessions: sessions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<_CalendarData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _TaskPageHeader(onAdd: () => _createTask(_selectedDay)),
                  const SizedBox(height: 16),
                  _CalendarToolbar(
                    mode: _mode,
                    onModeChanged: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 10),
                  if (_mode == _CalendarMode.month) ...[
                    _MonthCalendar(
                      data: data,
                      selectedDay: _selectedDay,
                      onSelectDay: _selectDay,
                      onPrevious: _goPrevious,
                      onNext: _goNext,
                      onToday: _goToday,
                    ),
                    const SizedBox(height: 10),
                    _CompactDayTimeline(
                      day: _selectedDay,
                      tasks: data.tasksForDay(_selectedDay),
                      blocks: data.blocksForDay(_selectedDay),
                      sessions: data.sessionsForDay(_selectedDay),
                      now: widget.nowProvider(),
                      onAddTask: () => _createTask(_selectedDay),
                      onEditTask: _edit,
                      onDeleteTask: _delete,
                    ),
                    const SizedBox(height: 10),
                    _TaskListSection(
                      tasks: data.tasks,
                      now: widget.nowProvider(),
                      filter: _taskFilter,
                      onFilterChanged: (value) {
                        setState(() => _taskFilter = value);
                      },
                      onToggleStatus: _toggleTaskStatus,
                      onEdit: _edit,
                      onDelete: _delete,
                    ),
                  ] else
                    _WeekCalendar(
                      data: data,
                      selectedDay: _selectedDay,
                      onSelectDay: _selectDay,
                      onDrop: _moveCalendarItem,
                      onAddTask: _createTask,
                      onEditTask: _edit,
                      onDeleteTask: _delete,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createTask([DateTime? targetDay]) async {
    final day = targetDay ?? _selectedDay;
    final result = await showModalBottomSheet<_TaskEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTaskDialog(
        title: '新增任务',
        initialTitle: '',
        initialStartTime: day.add(const Duration(hours: 9)),
        initialEndTime: day.add(const Duration(hours: 10)),
        now: widget.nowProvider(),
        allowRepeat: true,
      ),
    );
    if (result == null) return;

    final now = widget.nowProvider();
    if (result.repeatDaily) {
      final rule = await widget.database.createDailyRecurringTaskRule(
        title: result.title,
        description: result.description,
        startDate: result.repeatStartDate ?? result.startTime ?? _selectedDay,
        endDate: result.repeatEndDate,
        hour: (result.startTime ?? now).hour,
        minute: (result.startTime ?? now).minute,
        now: now,
      );
      final generated = await widget.database.getTasksForRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 8)),
      );
      for (final task in generated.where(
        (task) => task.recurrenceRuleId == rule.id,
      )) {
        await _syncReminder(task);
      }
    } else {
      final task = await widget.database.createManualTask(
        title: result.title,
        description: result.description,
        startTime: result.startTime,
        endTime: result.endTime,
        dueTimeText: result.dueTimeText,
        dueTime: result.startTime,
        now: now,
      );
      await _syncReminder(task);
    }

    _refresh();
    widget.onRecordsChanged?.call();
  }

  Future<void> _edit(Task task) async {
    final result = await showModalBottomSheet<_TaskEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTaskDialog(
        title: '编辑任务',
        initialTitle: task.title,
        initialDescription: task.description,
        initialDueTimeText: task.dueTimeText,
        initialStartTime: task.startTime ?? task.dueTime,
        initialEndTime:
            task.endTime ??
            (task.startTime ?? task.dueTime)?.add(const Duration(hours: 1)),
        now: widget.nowProvider(),
      ),
    );
    if (result == null) return;

    await widget.database.updateTaskById(
      id: task.id,
      title: Value(result.title),
      description: Value(result.description),
      startTime: Value(result.startTime),
      endTime: Value(result.endTime),
      dueTimeText: Value(result.dueTimeText),
      dueTime: Value(result.startTime),
      updatedAt: widget.nowProvider(),
    );
    await widget.taskReminderCoordinator.sync(
      taskId: task.id,
      title: result.title,
      dueTime: result.startTime,
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
      content: task.recurrenceRuleId == null
          ? '删除后，这条任务不会再参与首页建议。'
          : '删除后，这一天的重复任务不会自动补回。',
    );
    if (!confirmed) return;

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

  Future<void> _toggleTaskStatus(Task task) async {
    final now = widget.nowProvider();
    final status = TaskStatus.fromValue(task.taskStatus);
    if (status == TaskStatus.active) {
      await widget.database.markTaskCompleted(id: task.id, updatedAt: now);
      await widget.taskReminderCoordinator.sync(
        taskId: task.id,
        title: task.title,
        dueTime: null,
        isActive: false,
        now: now,
      );
    } else {
      await widget.database.markTaskActive(id: task.id, updatedAt: now);
      await widget.taskReminderCoordinator.sync(
        taskId: task.id,
        title: task.title,
        dueTime: _taskScheduledStartTime(task),
        isActive: true,
        now: now,
      );
    }
    _refresh();
    widget.onRecordsChanged?.call();
  }

  Future<void> _moveCalendarItem(_CalendarDrop drop) async {
    final now = widget.nowProvider();
    if (drop.item.task != null) {
      final task = drop.item.task!;
      await widget.database.updateTaskDueTimeOnly(
        id: task.id,
        dueTime: drop.start,
        updatedAt: now,
      );
      await widget.taskReminderCoordinator.sync(
        taskId: task.id,
        title: task.title,
        dueTime: drop.start,
        isActive: TaskStatus.fromValue(task.taskStatus) == TaskStatus.active,
        now: now,
      );
    } else if (drop.item.block != null) {
      final block = drop.item.block!;
      final duration = block.endTime.difference(block.startTime);
      await widget.database.updateScheduleBlockTimes(
        id: block.id,
        startTime: drop.start,
        endTime: drop.start.add(duration),
        updatedAt: now,
      );
    }
    _refresh();
    widget.onRecordsChanged?.call();
  }

  Future<void> _syncReminder(Task task) {
    return widget.taskReminderCoordinator.sync(
      taskId: task.id,
      title: task.title,
      dueTime: _taskScheduledStartTime(task),
      isActive: TaskStatus.fromValue(task.taskStatus) == TaskStatus.active,
      now: widget.nowProvider(),
    );
  }

  Future<void> _reload() async {
    _refresh();
    await _dataFuture;
  }

  void _refresh() {
    setState(() {
      _dataFuture = _load();
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = DateTime(day.year, day.month, day.day);
      _dataFuture = _load();
    });
  }

  void _goPrevious() {
    final next = _mode == _CalendarMode.month
        ? DateTime(_selectedDay.year, _selectedDay.month - 1, 1)
        : _selectedDay.subtract(const Duration(days: 7));
    _selectDay(next);
  }

  void _goNext() {
    final next = _mode == _CalendarMode.month
        ? DateTime(_selectedDay.year, _selectedDay.month + 1, 1)
        : _selectedDay.add(const Duration(days: 7));
    _selectDay(next);
  }

  void _goToday() {
    final now = widget.nowProvider();
    _selectDay(DateTime(now.year, now.month, now.day));
  }
}

enum _CalendarMode { month, week }

enum _TaskFilter { all, active, completed, cancelled }

class _TaskPageHeader extends StatelessWidget {
  const _TaskPageHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppAssistantAvatar(size: 42),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '任务',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '有计划的行动，成就更好的自己',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            tooltip: '新增任务',
            onPressed: onAdd,
            icon: const Icon(Icons.adjust_rounded, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

class _CalendarData {
  const _CalendarData({
    required this.monthStart,
    required this.weekStart,
    required this.tasks,
    required this.blocks,
    required this.sessions,
  });

  final DateTime monthStart;
  final DateTime weekStart;
  final List<Task> tasks;
  final List<ScheduleBlock> blocks;
  final List<SedentarySession> sessions;

  List<Task> tasksForDay(DateTime day) {
    return tasks.where((task) {
      final time = _taskStartTime(task);
      return _isSameDay(time, day);
    }).toList();
  }

  List<ScheduleBlock> blocksForDay(DateTime day) {
    return blocks.where((block) => _isSameDay(block.startTime, day)).toList();
  }

  List<SedentarySession> sessionsForDay(DateTime day) {
    return sessions
        .where((session) => _isSameDay(session.startedAt, day))
        .toList();
  }
}

class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({required this.mode, required this.onModeChanged});

  final _CalendarMode mode;
  final ValueChanged<_CalendarMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_CalendarMode>(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFFF3F6FB),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          segments: const [
            ButtonSegment(
              value: _CalendarMode.month,
              icon: Icon(Icons.calendar_month_rounded),
              label: Text('月视图'),
            ),
            ButtonSegment(
              value: _CalendarMode.week,
              icon: Icon(Icons.view_week_rounded),
              label: Text('周视图'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) => onModeChanged(value.single),
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.data,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final _CalendarData data;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final firstGridDay = data.monthStart.subtract(
      Duration(days: data.monthStart.weekday % 7),
    );
    final days = [
      for (var i = 0; i < 42; i += 1) firstGridDay.add(Duration(days: i)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '上个月',
                  visualDensity: VisualDensity.compact,
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                ),
                Text(
                  '${selectedDay.year}年${selectedDay.month}月',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: '下个月',
                  visualDensity: VisualDensity.compact,
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onToday,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      side: const BorderSide(color: Color(0xFFD7E5FB)),
                    ),
                    child: const Text('回到今天', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in ['日', '一', '二', '三', '四', '五', '六'])
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 1,
              crossAxisSpacing: 2,
              childAspectRatio: 2.3,
              children: [
                for (final day in days)
                  _MonthDayCell(
                    day: day,
                    inMonth: day.month == data.monthStart.month,
                    selected: _isSameDay(day, selectedDay),
                    taskCount: data.tasksForDay(day).length,
                    recurringCount: data
                        .tasksForDay(day)
                        .where((task) => task.recurrenceRuleId != null)
                        .length,
                    blockCount: data.blocksForDay(day).length,
                    sedentaryCount: data.sessionsForDay(day).length,
                    onTap: () => onSelectDay(day),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CalendarLegendDot(color: AppColors.mint, label: '普通任务'),
                SizedBox(width: 16),
                _CalendarLegendDot(color: AppColors.orange, label: '每日重复'),
                SizedBox(width: 16),
                _CalendarLegendDot(color: AppColors.purple, label: 'AI 时间规划'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.taskCount,
    required this.recurringCount,
    required this.blockCount,
    required this.sedentaryCount,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final int taskCount;
  final int recurringCount;
  final int blockCount;
  final int sedentaryCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : inMonth
                    ? AppColors.text
                    : const Color(0xFFB9C3D3),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TinyDot(
                  color: AppColors.mint,
                  enabled: taskCount - recurringCount > 0,
                ),
                _TinyDot(color: AppColors.orange, enabled: recurringCount > 0),
                _TinyDot(color: AppColors.purple, enabled: blockCount > 0),
                _TinyDot(color: Colors.amber, enabled: sedentaryCount > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
      ],
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({
    required this.data,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onDrop,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final _CalendarData data;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<_CalendarDrop> onDrop;
  final ValueChanged<DateTime> onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (var i = 0; i < 7; i += 1) data.weekStart.add(Duration(days: i)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekDateStrip(
          days: days,
          selectedDay: selectedDay,
          data: data,
          onSelectDay: onSelectDay,
        ),
        const SizedBox(height: 12),
        _WeekDayTimeline(
          day: selectedDay,
          tasks: data.tasksForDay(selectedDay),
          blocks: data.blocksForDay(selectedDay),
          sessions: data.sessionsForDay(selectedDay),
          onDrop: onDrop,
          onEditTask: onEditTask,
          onDeleteTask: onDeleteTask,
        ),
        const SizedBox(height: 14),
        _ManualAddTaskBar(
          day: selectedDay,
          onTap: () => onAddTask(selectedDay),
        ),
      ],
    );
  }
}

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({
    required this.days,
    required this.selectedDay,
    required this.data,
    required this.onSelectDay,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final _CalendarData data;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _WeekDateCell(
                    day: day,
                    selected: _isSameDay(day, selectedDay),
                    taskCount: data.tasksForDay(day).length,
                    blockCount: data.blocksForDay(day).length,
                    sedentaryCount: data.sessionsForDay(day).length,
                    onTap: () => onSelectDay(day),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekDateCell extends StatelessWidget {
  const _WeekDateCell({
    required this.day,
    required this.selected,
    required this.taskCount,
    required this.blockCount,
    required this.sedentaryCount,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final int taskCount;
  final int blockCount;
  final int sedentaryCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasItems = taskCount + blockCount + sedentaryCount > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.10) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              _weekdayShortName(day),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: day.weekday == DateTime.sunday
                    ? Colors.redAccent
                    : day.weekday == DateTime.saturday
                    ? Colors.blue
                    : const Color(0xFF5F5A53),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF111111) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF1D1D1F),
                ),
              ),
            ),
            const SizedBox(height: 5),
            if (hasItems)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TinyDot(color: Colors.teal, enabled: taskCount > 0),
                  _TinyDot(color: Colors.indigo, enabled: blockCount > 0),
                  _TinyDot(color: Colors.amber, enabled: sedentaryCount > 0),
                ],
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

class _WeekDayTimeline extends StatelessWidget {
  const _WeekDayTimeline({
    required this.day,
    required this.tasks,
    required this.blocks,
    required this.sessions,
    required this.onDrop,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final DateTime day;
  final List<Task> tasks;
  final List<ScheduleBlock> blocks;
  final List<SedentarySession> sessions;
  final ValueChanged<_CalendarDrop> onDrop;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final sortedItems = [
      for (final task in tasks) _CalendarItem.task(task),
      for (final block in blocks) _CalendarItem.block(block),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final visibleHours = _visibleHoursFor(day, sortedItems, sessions);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_weekdayName(day)} ${day.month}/${day.day} 时间轴',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.drag_indicator_rounded,
                    size: 18,
                    color: Color(0xFF8A8278),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                for (final hour in visibleHours)
                  _TimelineHourRow(
                    day: day,
                    hour: hour,
                    items: sortedItems
                        .where((item) => _hourForItem(item) == hour)
                        .toList(),
                    sessions: sessions
                        .where((session) => session.startedAt.hour == hour)
                        .toList(),
                    onDrop: onDrop,
                    onEditTask: onEditTask,
                    onDeleteTask: onDeleteTask,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineHourRow extends StatelessWidget {
  const _TimelineHourRow({
    required this.day,
    required this.hour,
    required this.items,
    required this.sessions,
    required this.onDrop,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final DateTime day;
  final int hour;
  final List<_CalendarItem> items;
  final List<SedentarySession> sessions;
  final ValueChanged<_CalendarDrop> onDrop;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final hasContent = items.isNotEmpty || sessions.isNotEmpty;
    return DragTarget<_CalendarItem>(
      onAcceptWithDetails: (details) {
        onDrop(
          _CalendarDrop(
            item: details.data,
            start: DateTime(day.year, day.month, day.day, hour),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return Container(
          constraints: const BoxConstraints(minHeight: 74),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _hourLabel(hour),
                        style: const TextStyle(
                          color: Color(0xFF817A70),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hour == 8)
                        const Text(
                          '上午',
                          style: TextStyle(
                            color: Color(0xFF9A9288),
                            fontSize: 12,
                          ),
                        )
                      else if (hour == 12)
                        const Text(
                          '下午',
                          style: TextStyle(
                            color: Color(0xFF9A9288),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 15,
                      left: 0,
                      right: 0,
                      child: const SizedBox(
                        height: 1,
                        child: CustomPaint(
                          painter: _DottedLinePainter(color: Color(0xFFE2DDD5)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
                      child: hasContent
                          ? Column(
                              children: [
                                for (final item in items)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _DraggableCalendarItem(
                                      item: item,
                                      onEditTask: onEditTask,
                                      onDeleteTask: onDeleteTask,
                                    ),
                                  ),
                                for (final session in sessions)
                                  _SedentaryTile(session: session),
                              ],
                            )
                          : const SizedBox(height: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ManualAddTaskBar extends StatelessWidget {
  const _ManualAddTaskBar({required this.day, required this.onTap});

  final DateTime day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE7E0D6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  offset: Offset(0, 8),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '在 ${day.month} 月 ${day.day} 日添加',
                    style: const TextStyle(
                      color: Color(0xFF8A8278),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.add_rounded, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyDot extends StatelessWidget {
  const _TinyDot({required this.color, required this.enabled});

  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: enabled ? color : Colors.transparent,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 3, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DraggableCalendarItem extends StatelessWidget {
  const _DraggableCalendarItem({
    required this.item,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final _CalendarItem item;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final child = item.task == null
        ? _ScheduleBlockTile(block: item.block!)
        : _CompactTaskTile(
            task: item.task!,
            onEdit: () => onEditTask(item.task!),
            onDelete: () => onDeleteTask(item.task!),
          );

    return LongPressDraggable<_CalendarItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 260, child: child),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: child),
      child: child,
    );
  }
}

class _CompactDayTimeline extends StatelessWidget {
  const _CompactDayTimeline({
    required this.day,
    required this.tasks,
    required this.blocks,
    required this.sessions,
    required this.now,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final DateTime day;
  final List<Task> tasks;
  final List<ScheduleBlock> blocks;
  final List<SedentarySession> sessions;
  final DateTime now;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final entries = <_CompactTimelineEntry>[
      for (final task in tasks) _CompactTimelineEntry.task(task),
      for (final block in blocks) _CompactTimelineEntry.block(block),
    ]..sort((a, b) => a.start.compareTo(b.start));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${day.month}月${day.day}日 ${_weekdayName(day)}',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_isSameDay(day, now))
                  const _SmallPill(label: '今天', color: AppColors.primary),
                const SizedBox(width: 6),
                SizedBox(
                  height: 30,
                  child: FilledButton.icon(
                    onPressed: onAddTask,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('新增任务'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (_isSameDay(day, now)) ...[
              Row(
                children: [
                  Text(
                    _timeText(now),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Divider(color: Colors.redAccent, height: 1),
                  ),
                ],
              ),
              const SizedBox(height: 5),
            ],
            if (entries.isEmpty && sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '这一天暂无任务或时间规划。',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              )
            else ...[
              for (final entry in entries.take(5))
                _CompactTimelineRow(
                  entry: entry,
                  onEditTask: onEditTask,
                  onDeleteTask: onDeleteTask,
                ),
              for (final session in sessions.take(1))
                _CompactTimelineSedentaryRow(session: session),
            ],
            const SizedBox(height: 5),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CalendarLegendDot(color: AppColors.primary, label: '普通任务'),
                SizedBox(width: 14),
                _CalendarLegendDot(color: AppColors.mint, label: '每日重复'),
                SizedBox(width: 14),
                _CalendarLegendDot(color: AppColors.purple, label: 'AI 时间规划'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTimelineEntry {
  const _CompactTimelineEntry._({this.task, this.block, required this.start});

  factory _CompactTimelineEntry.task(Task task) =>
      _CompactTimelineEntry._(task: task, start: _taskStartTime(task));

  factory _CompactTimelineEntry.block(ScheduleBlock block) =>
      _CompactTimelineEntry._(block: block, start: block.startTime);

  final Task? task;
  final ScheduleBlock? block;
  final DateTime start;
}

class _CompactTimelineRow extends StatelessWidget {
  const _CompactTimelineRow({
    required this.entry,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final _CompactTimelineEntry entry;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final block = entry.block;
    final color = block != null
        ? AppColors.purple
        : task!.recurrenceRuleId != null
        ? AppColors.mint
        : AppColors.primary;
    final title = block?.title ?? task!.title;
    final time = block != null
        ? '${_timeText(block.startTime)}-${_timeText(block.endTime)}'
        : _taskTimeRangeText(task!);

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(width: 4, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (task != null)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 17,
              onSelected: (value) {
                if (value == 'edit') onEditTask(task);
                if (value == 'delete') onDeleteTask(task);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _CompactTimelineSedentaryRow extends StatelessWidget {
  const _CompactTimelineSedentaryRow({required this.session});

  final SedentarySession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.self_improvement_rounded,
            color: AppColors.orange,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${_timeText(session.startedAt)} 久坐会话',
              style: const TextStyle(color: AppColors.text, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskListSection extends StatelessWidget {
  const _TaskListSection({
    required this.tasks,
    required this.now,
    required this.filter,
    required this.onFilterChanged,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Task> tasks;
  final DateTime now;
  final _TaskFilter filter;
  final ValueChanged<_TaskFilter> onFilterChanged;
  final ValueChanged<Task> onToggleStatus;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    final visible = tasks.where((task) {
      final status = TaskStatus.fromValue(task.taskStatus);
      return switch (filter) {
        _TaskFilter.all => true,
        _TaskFilter.active => status == TaskStatus.active,
        _TaskFilter.completed => status == TaskStatus.completed,
        _TaskFilter.cancelled => status == TaskStatus.cancelled,
      };
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务列表',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TaskFilterChip(
                    label: '全部 ${tasks.length}',
                    selected: filter == _TaskFilter.all,
                    onTap: () => onFilterChanged(_TaskFilter.all),
                  ),
                  _TaskFilterChip(
                    label: '进行中',
                    selected: filter == _TaskFilter.active,
                    onTap: () => onFilterChanged(_TaskFilter.active),
                  ),
                  _TaskFilterChip(
                    label: '已完成',
                    selected: filter == _TaskFilter.completed,
                    onTap: () => onFilterChanged(_TaskFilter.completed),
                  ),
                  _TaskFilterChip(
                    label: '已取消',
                    selected: filter == _TaskFilter.cancelled,
                    onTap: () => onFilterChanged(_TaskFilter.cancelled),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '当前筛选下没有任务。',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              )
            else
              for (final task in visible.take(8))
                _TaskListRow(
                  task: task,
                  now: now,
                  onToggleStatus: () => onToggleStatus(task),
                  onEdit: () => onEdit(task),
                  onDelete: () => onDelete(task),
                ),
          ],
        ),
      ),
    );
  }
}

class _TaskFilterChip extends StatelessWidget {
  const _TaskFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskListRow extends StatelessWidget {
  const _TaskListRow({
    required this.task,
    required this.now,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = TaskStatus.fromValue(task.taskStatus);
    final active = status == TaskStatus.active;
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              active ? Icons.circle_outlined : Icons.check_circle_rounded,
              color: active ? AppColors.textMuted : AppColors.mint,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: active ? '完成' : '恢复',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleStatus,
            icon: Icon(
              active
                  ? Icons.check_circle_outline_rounded
                  : Icons.replay_rounded,
              color: active ? AppColors.mint : AppColors.primary,
              size: 18,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? AppColors.text : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          decoration: status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _TaskStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _taskTimeRangeText(task, now: now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '编辑',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: '删除',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTaskTile extends StatelessWidget {
  const _CompactTaskTile({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final taskStatus = TaskStatus.fromValue(task.taskStatus);
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_taskTimeRangeText(task)} ${task.title}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: taskStatus == TaskStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (task.recurrenceRuleId != null)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.repeat_rounded, size: 16),
            ),
          IconButton(
            tooltip: '编辑',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '删除',
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ScheduleBlockTile extends StatelessWidget {
  const _ScheduleBlockTile({required this.block});

  final ScheduleBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.view_timeline_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_timeText(block.startTime)}-${_timeText(block.endTime)} ${block.title}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((block.note ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(block.note!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SedentaryTile extends StatelessWidget {
  const _SedentaryTile({required this.session});

  final SedentarySession session;

  @override
  Widget build(BuildContext context) {
    final ended = session.endedAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Icon(Icons.self_improvement_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ended == null
                  ? '${_timeText(session.startedAt)} 开始久坐，${_timeText(session.reminderAt)} 提醒活动'
                  : '${_timeText(session.startedAt)}-${_timeText(ended)} 久坐会话',
            ),
          ),
        ],
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

    return _SmallPill(label: label, color: color);
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaskEditResult {
  const _TaskEditResult({
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.dueTimeText,
    this.repeatDaily = false,
    this.repeatStartDate,
    this.repeatEndDate,
  });

  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? dueTimeText;
  final bool repeatDaily;
  final DateTime? repeatStartDate;
  final DateTime? repeatEndDate;
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({
    required this.title,
    required this.initialTitle,
    required this.now,
    this.initialDescription,
    this.initialDueTimeText,
    this.initialStartTime,
    this.initialEndTime,
    this.allowRepeat = false,
  });

  final String title;
  final String initialTitle;
  final DateTime now;
  final String? initialDescription;
  final String? initialDueTimeText;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final bool allowRepeat;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;
  String? _dueTimeText;
  bool _repeatDaily = false;
  DateTime? _repeatStartDate;
  DateTime? _repeatEndDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _selectedStartTime = widget.initialStartTime;
    _selectedEndTime =
        widget.initialEndTime ??
        widget.initialStartTime?.add(const Duration(hours: 1));
    _dueTimeText = widget.initialDueTimeText;
    final date = widget.initialStartTime ?? widget.now;
    _repeatStartDate = DateTime(date.year, date.month, date.day);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = _selectedStartTime ?? widget.now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(widget.now.year - 1),
      lastDate: DateTime(widget.now.year + 5),
    );
    if (pickedDate == null) return;

    final defaultStart = _selectedStartTime ?? _defaultStartTime();
    final startTime = TimeOfDay.fromDateTime(defaultStart);
    final endTime = TimeOfDay.fromDateTime(
      _selectedEndTime ?? defaultStart.add(const Duration(hours: 1)),
    );
    setState(() {
      _selectedStartTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        startTime.hour,
        startTime.minute,
      );
      _selectedEndTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        endTime.hour,
        endTime.minute,
      );
      _repeatStartDate ??= DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    if (_selectedStartTime == null) {
      _selectedStartTime = _defaultStartTime();
      _selectedEndTime = _selectedStartTime!.add(const Duration(hours: 1));
    }
    final current = isStart
        ? _selectedStartTime!
        : (_selectedEndTime ??
              _selectedStartTime!.add(const Duration(hours: 1)));
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) return;

    setState(() {
      final pickedDateTime = DateTime(
        current.year,
        current.month,
        current.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (isStart) {
        _selectedStartTime = pickedDateTime;
        if (_selectedEndTime == null ||
            !_selectedEndTime!.isAfter(pickedDateTime)) {
          _selectedEndTime = pickedDateTime.add(const Duration(hours: 1));
        }
      } else {
        _selectedEndTime = pickedDateTime.isAfter(_selectedStartTime!)
            ? pickedDateTime
            : _selectedStartTime!.add(const Duration(hours: 1));
      }
    });
  }

  DateTime _defaultStartTime() {
    final base = widget.initialStartTime ?? widget.now;
    return DateTime(base.year, base.month, base.day, 9);
  }

  DateTime? _normalizedEndTime() {
    final start = _selectedStartTime;
    final end = _selectedEndTime;
    if (start == null) return null;
    if (end == null || !end.isAfter(start)) {
      return start.add(const Duration(hours: 1));
    }
    return end;
  }

  Future<void> _pickRepeatDate({required bool isStart}) async {
    final initial = isStart
        ? (_repeatStartDate ?? widget.now)
        : (_repeatEndDate ?? _repeatStartDate ?? widget.now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(widget.now.year - 1),
      lastDate: DateTime(widget.now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      final day = DateTime(picked.year, picked.month, picked.day);
      if (isStart) {
        _repeatStartDate = day;
      } else {
        _repeatEndDate = day;
      }
    });
  }

  void _clearDueTime() {
    setState(() {
      _selectedStartTime = null;
      _selectedEndTime = null;
      _dueTimeText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE3EE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(onPressed: _save, child: const Text('保存')),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TaskTypeChip(
                                icon: Icons.task_alt_rounded,
                                label: '普通任务',
                                selected: !_repeatDaily,
                                onTap: () =>
                                    setState(() => _repeatDaily = false),
                              ),
                            ),
                            if (widget.allowRepeat) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TaskTypeChip(
                                  icon: Icons.event_repeat_rounded,
                                  label: '每日重复任务',
                                  selected: _repeatDaily,
                                  onTap: () =>
                                      setState(() => _repeatDaily = true),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: '任务标题',
                            hintText: '输入任务标题…',
                            filled: true,
                            fillColor: Color(0xFFF8FAFE),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: '备注',
                            hintText: '添加备注（可选）…',
                            filled: true,
                            fillColor: Color(0xFFF8FAFE),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DialogSectionLabel(
                          label: _repeatDaily ? '每天时间段' : '任务时间段',
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _rangeText(
                              _selectedStartTime,
                              _normalizedEndTime(),
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
                              onPressed: () => _pickTime(isStart: true),
                              icon: const Icon(Icons.schedule),
                              label: const Text('开始时间'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickTime(isStart: false),
                              icon: const Icon(Icons.schedule_outlined),
                              label: const Text('结束时间'),
                            ),
                            TextButton.icon(
                              onPressed: _clearDueTime,
                              icon: const Icon(Icons.clear),
                              label: const Text('清除时间'),
                            ),
                          ],
                        ),
                        if (widget.allowRepeat && _repeatDaily) ...[
                          const SizedBox(height: 12),
                          ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickRepeatDate(isStart: true),
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(
                                      '开始 ${_dateText(_repeatStartDate)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickRepeatDate(isStart: false),
                                    icon: const Icon(Icons.flag_rounded),
                                    label: Text(
                                      _repeatEndDate == null
                                          ? '无结束'
                                          : '结束 ${_dateText(_repeatEndDate)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () =>
                                    setState(() => _repeatEndDate = null),
                                icon: const Icon(Icons.all_inclusive_rounded),
                                label: const Text('设为无结束日期'),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('保存任务'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final startTime = _selectedStartTime;
    final endTime = _normalizedEndTime();
    final dueTimeText = startTime == null
        ? _dueTimeText
        : _rangeText(startTime, endTime);
    Navigator.of(context).pop(
      _TaskEditResult(
        title: title,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        dueTimeText: dueTimeText,
        repeatDaily: _repeatDaily,
        repeatStartDate: _repeatStartDate,
        repeatEndDate: _repeatEndDate,
      ),
    );
  }
}

class _TaskTypeChip extends StatelessWidget {
  const _TaskTypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : const Color(0xFFF8FAFE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogSectionLabel extends StatelessWidget {
  const _DialogSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _CalendarItem {
  const _CalendarItem.task(this.task) : block = null;

  const _CalendarItem.block(this.block) : task = null;

  final Task? task;
  final ScheduleBlock? block;

  DateTime get start => task == null ? block!.startTime : _taskStartTime(task!);
}

class _CalendarDrop {
  const _CalendarDrop({required this.item, required this.start});

  final _CalendarItem item;
  final DateTime start;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _weekdayName(DateTime day) {
  return switch (day.weekday) {
    DateTime.monday => '周一',
    DateTime.tuesday => '周二',
    DateTime.wednesday => '周三',
    DateTime.thursday => '周四',
    DateTime.friday => '周五',
    DateTime.saturday => '周六',
    _ => '周日',
  };
}

String _weekdayShortName(DateTime day) {
  return switch (day.weekday) {
    DateTime.monday => '一',
    DateTime.tuesday => '二',
    DateTime.wednesday => '三',
    DateTime.thursday => '四',
    DateTime.friday => '五',
    DateTime.saturday => '六',
    _ => '日',
  };
}

List<int> _visibleHoursFor(
  DateTime day,
  List<_CalendarItem> items,
  List<SedentarySession> sessions,
) {
  final hours = <int>{for (var hour = 8; hour <= 22; hour += 1) hour};
  for (final item in items) {
    hours.add(_hourForItem(item));
  }
  for (final session in sessions) {
    hours.add(session.startedAt.hour);
  }
  return hours.where((hour) => hour >= 0 && hour <= 23).toList()..sort();
}

int _hourForItem(_CalendarItem item) {
  return item.task == null
      ? item.block!.startTime.hour
      : _taskStartTime(item.task!).hour;
}

String _hourLabel(int hour) {
  final display = hour <= 12 ? hour : hour - 12;
  return '$display';
}

String _dateText(DateTime? day) {
  if (day == null) return '未选';
  return '${day.month}/${day.day}';
}

DateTime _taskStartTime(Task task) {
  return task.startTime ?? task.dueTime ?? task.createdAt;
}

DateTime? _taskScheduledStartTime(Task task) {
  return task.startTime ?? task.dueTime;
}

DateTime? _taskEndTime(Task task) {
  return task.endTime;
}

String _taskTimeRangeText(Task task, {DateTime? now}) {
  final start = _taskStartTime(task);
  final end = _taskEndTime(task);
  if (task.startTime != null) {
    return _rangeText(start, end);
  }
  return formatTaskDueText(
    dueTime: task.dueTime,
    dueTimeText: task.dueTimeText,
    now: now,
  );
}

String _rangeText(DateTime? start, DateTime? end) {
  if (start == null) return '未安排时间';
  if (end == null) {
    return '${start.month}月${start.day}日 ${_timeText(start)}';
  }
  final sameDay = _isSameDay(start, end);
  if (sameDay) {
    return '${start.month}月${start.day}日 ${_timeText(start)}-${_timeText(end)}';
  }
  return '${start.month}月${start.day}日 ${_timeText(start)} - '
      '${end.month}月${end.day}日 ${_timeText(end)}';
}

String _timeText(DateTime? time) {
  if (time == null) return '未定';
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
