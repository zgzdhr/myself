import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_visuals.dart';
import '../../data/local_db/app_database.dart';
import '../../data/plan/plan_client.dart';
import '../../domain/plan_result.dart';
import '../../domain/record_status.dart';
import '../../domain/task_status.dart';

class SchedulePlanScreen extends StatefulWidget {
  const SchedulePlanScreen({
    required this.database,
    required this.nowProvider,
    required this.planClient,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;
  final PlanClient planClient;

  @override
  State<SchedulePlanScreen> createState() => _SchedulePlanScreenState();
}

class _SchedulePlanScreenState extends State<SchedulePlanScreen> {
  late DateTime _selectedDay;
  late Future<_ScheduleDayData> _dayFuture;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = widget.nowProvider();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _dayFuture = _loadDay(_selectedDay);
  }

  Future<_ScheduleDayData> _loadDay(DateTime day) async {
    final plan = await widget.database.getSchedulePlanForDay(day);
    final blocks = plan == null
        ? <ScheduleBlock>[]
        : await widget.database.getScheduleBlocksForPlan(plan.id);
    final tasks = await widget.database.getSuggestionTasks(now: day);
    final states = await widget.database.getActiveShortTermStates(
      now: widget.nowProvider(),
    );
    final profiles = await widget.database.getActiveProfileItems();
    final summaries = await widget.database.getRecentDailySummariesBeforeOrOn(
      day: day,
    );

    return _ScheduleDayData(
      day: DateTime(day.year, day.month, day.day),
      plan: plan,
      blocks: blocks,
      tasks: tasks,
      states: states,
      profileItems: profiles,
      recentSummaries: summaries,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _DayPickerStrip(selectedDay: _selectedDay, onSelectDay: _selectDay),
          const SizedBox(height: 16),
          FutureBuilder<_ScheduleDayData>(
            future: _dayFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return const _ScheduleCard(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('正在读取时间规划...'),
                  ),
                );
              }
              return _ScheduleDayPanel(
                data: data,
                isGenerating: _isGenerating,
                onGenerate: () => _generatePlan(data),
                onConfirm:
                    data.plan == null ||
                        data.plan!.status == RecordStatus.confirmed.value
                    ? null
                    : () => _confirmPlan(data.plan!),
                onDeletePlan: data.plan == null
                    ? null
                    : () => _deletePlan(data.plan!),
                onEditBlock: _editBlock,
                onDeleteBlock: _deleteBlock,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _dayFuture = _loadDay(_selectedDay);
    });
    await _dayFuture;
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _dayFuture = _loadDay(day);
    });
  }

  Future<void> _generatePlan(_ScheduleDayData data) async {
    final note = await _askUserNote();
    if (!mounted || note == null) return;

    setState(() => _isGenerating = true);

    try {
      final result = await widget.planClient.generateDailyPlan(
        _buildPlanRequest(data, note),
      );
      await _savePlanResult(data, result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('时间规划草稿已生成。')));
      await _reload();
      final refreshed = await _dayFuture;
      if (mounted && refreshed.plan != null) {
        await _showPlanConfirmationSheet(refreshed);
      }
    } on PlanFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _showPlanConfirmationSheet(_ScheduleDayData data) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlanConfirmationSheet(
        data: data,
        onConfirm: () {
          Navigator.of(context).pop();
          _confirmPlan(data.plan!);
        },
        onEdit: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<String?> _askUserNote() {
    return showAppTextPromptSheet(
      context: context,
      title: '补充安排偏好',
      subtitle: '告诉 AI 今天的节奏和必须保留的时间',
      hintText: '例如：上午先轻一点，下午安排重点任务，晚上留半小时复盘。',
      confirmLabel: '生成规划草稿',
      icon: Icons.calendar_month_rounded,
    );
  }

  Map<String, Object?> _buildPlanRequest(_ScheduleDayData data, String note) {
    return {
      'timezone': 'Asia/Shanghai',
      'plan_date': _dateKey(data.day),
      'current_time_iso': widget.nowProvider().toIso8601String(),
      'user_note': note.trim(),
      'day_start_hour': 8,
      'day_end_hour': 22,
      'tasks': [
        for (final task in data.tasks)
          {
            'id': task.id,
            'title': task.title,
            'description': task.description,
            'due_time_text': task.dueTimeText,
            'due_time_iso': task.dueTime?.toIso8601String(),
            'priority': task.priority,
            'task_status': task.taskStatus,
            'status': task.status,
          },
      ],
      'short_term_states': [
        for (final state in data.states)
          {'id': state.id, 'content': state.content, 'status': state.status},
      ],
      'profile_items': [
        for (final profile in data.profileItems.take(6))
          {
            'id': profile.id,
            'content': profile.content,
            'category': profile.category,
            'status': profile.status,
          },
      ],
      'recent_summaries': [
        for (final summary in data.recentSummaries)
          {
            'id': summary.id,
            'title': summary.title,
            'content': summary.content,
            'encouragement': summary.encouragement,
            'improvement_notes': summary.improvementNotes,
            'task_guidance': summary.taskGuidance,
            'time_range_start': summary.timeRangeStart.toIso8601String(),
          },
      ],
    };
  }

  Future<void> _savePlanResult(_ScheduleDayData data, PlanResult result) async {
    final now = widget.nowProvider();
    final planId = const Uuid().v4();
    final blocks = <ScheduleBlocksCompanion>[];
    final sourcesByBlockId = <String, List<ScheduleBlockSourcesCompanion>>{};

    for (var index = 0; index < result.blocks.length; index += 1) {
      final blockResult = result.blocks[index];
      final blockId = const Uuid().v4();
      blocks.add(
        ScheduleBlocksCompanion.insert(
          id: blockId,
          planId: planId,
          title: blockResult.title,
          blockType: blockResult.blockType,
          startTime: blockResult.startTime,
          endTime: blockResult.endTime,
          taskId: Value(blockResult.taskId),
          note: Value(blockResult.note),
          reason: blockResult.reason,
          sortOrder: index,
          status: RecordStatus.pending.value,
          confidence: Value(blockResult.confidence),
          createdAt: now,
          updatedAt: now,
        ),
      );
      sourcesByBlockId[blockId] = [
        for (final source in blockResult.sourceRefs)
          ScheduleBlockSourcesCompanion.insert(
            id: const Uuid().v4(),
            blockId: blockId,
            sourceTable: source.sourceTable,
            sourceRecordId: source.sourceRecordId,
            createdAt: now,
          ),
      ];
    }

    await widget.database.saveSchedulePlan(
      updatedAt: now,
      plan: SchedulePlan(
        id: planId,
        planDate: data.day,
        title: result.title,
        overview: result.overview,
        suggestionsJson: jsonEncode(result.suggestions),
        unscheduledTaskIdsJson: jsonEncode(result.unscheduledTaskIds),
        status: RecordStatus.pending.value,
        generatedBy: 'deepseek',
        modelName: null,
        promptVersion: 'plan-daily-v1',
        confidence: result.confidence,
        createdAt: now,
        updatedAt: now,
        confirmedAt: null,
        userEditedAt: null,
        deletedAt: null,
      ),
      blocks: blocks,
      sourcesByBlockId: sourcesByBlockId,
    );
  }

  Future<void> _confirmPlan(SchedulePlan plan) async {
    await widget.database.confirmSchedulePlan(
      id: plan.id,
      updatedAt: widget.nowProvider(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已确认今天的时间规划。')));
    await _reload();
  }

  Future<void> _deletePlan(SchedulePlan plan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除时间规划？'),
        content: const Text('删除后，这份计划不会再显示，也不会参与后续同步。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await widget.database.markSchedulePlanDeleted(
      id: plan.id,
      updatedAt: widget.nowProvider(),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _editBlock(ScheduleBlock block) async {
    final edited = await _showEditBlockDialog(block);
    if (edited == null) return;

    await widget.database.updateScheduleBlock(
      id: block.id,
      title: edited.title,
      blockType: edited.blockType,
      startTime: edited.startTime,
      endTime: edited.endTime,
      note: edited.note,
      reason: edited.reason,
      updatedAt: widget.nowProvider(),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<_EditableBlock?> _showEditBlockDialog(ScheduleBlock block) {
    final titleController = TextEditingController(text: block.title);
    final noteController = TextEditingController(text: block.note ?? '');
    final reasonController = TextEditingController(text: block.reason);
    var blockType = block.blockType;
    var startTime = block.startTime;
    var endTime = block.endTime;

    return showDialog<_EditableBlock>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickTime({required bool isStart}) async {
              final current = isStart ? startTime : endTime;
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(current),
              );
              if (picked == null) return;
              final next = DateTime(
                current.year,
                current.month,
                current.day,
                picked.hour,
                picked.minute,
              );
              setDialogState(() {
                if (isStart) {
                  startTime = next;
                  if (!endTime.isAfter(startTime)) {
                    endTime = startTime.add(const Duration(minutes: 30));
                  }
                } else {
                  endTime = next;
                }
              });
            }

            return AlertDialog(
              title: const Text('调整时间块'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: '标题'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: blockType,
                      items: const [
                        DropdownMenuItem(value: 'task', child: Text('任务')),
                        DropdownMenuItem(value: 'break', child: Text('休息')),
                        DropdownMenuItem(value: 'buffer', child: Text('缓冲')),
                        DropdownMenuItem(value: 'personal', child: Text('个人')),
                        DropdownMenuItem(value: 'review', child: Text('复盘')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => blockType = value);
                      },
                      decoration: const InputDecoration(labelText: '类型'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickTime(isStart: true),
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(_timeText(startTime)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickTime(isStart: false),
                            icon: const Icon(Icons.flag_rounded),
                            label: Text(_timeText(endTime)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '备注'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '安排原因'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        !endTime.isAfter(startTime)) {
                      return;
                    }
                    Navigator.of(context).pop(
                      _EditableBlock(
                        title: titleController.text.trim(),
                        blockType: blockType,
                        startTime: startTime,
                        endTime: endTime,
                        note: noteController.text.trim(),
                        reason: reasonController.text.trim().isEmpty
                            ? '用户手动调整。'
                            : reasonController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBlock(ScheduleBlock block) async {
    await widget.database.markScheduleBlockDeleted(
      id: block.id,
      updatedAt: widget.nowProvider(),
    );
    if (!mounted) return;
    await _reload();
  }
}

class _PlanConfirmationSheet extends StatelessWidget {
  const _PlanConfirmationSheet({
    required this.data,
    required this.onConfirm,
    required this.onEdit,
  });

  final _ScheduleDayData data;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final plan = data.plan!;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE3EE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    const Expanded(
                      child: Text(
                        'AI 时间规划草稿确认 ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.overview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '今日时间规划草稿 · ${data.blocks.length} 个时间块',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: data.blocks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final block = data.blocks[index];
                      final color = _blockColor(block.blockType);
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: color.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 82,
                              child: Text(
                                '${_timeText(block.startTime)}–${_timeText(block.endTime)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                block.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('确认草稿'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('编辑时间块'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleDayPanel extends StatelessWidget {
  const _ScheduleDayPanel({
    required this.data,
    required this.isGenerating,
    required this.onGenerate,
    required this.onConfirm,
    required this.onDeletePlan,
    required this.onEditBlock,
    required this.onDeleteBlock,
  });

  final _ScheduleDayData data;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback? onConfirm;
  final VoidCallback? onDeletePlan;
  final ValueChanged<ScheduleBlock> onEditBlock;
  final ValueChanged<ScheduleBlock> onDeleteBlock;

  @override
  Widget build(BuildContext context) {
    final plan = data.plan;
    final activeTasks = data.tasks
        .where((task) => task.taskStatus == TaskStatus.active.value)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScheduleCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dateTitle(data.day),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '可参考 $activeTasks 个活跃任务、${data.states.length} 条当前状态、${data.recentSummaries.length} 条近期复盘。',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (plan != null)
                      _StatusChip(
                        label: plan.status == RecordStatus.confirmed.value
                            ? '已确认'
                            : '草稿',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: isGenerating ? null : onGenerate,
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(isGenerating ? '生成中' : '生成规划'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('确认计划'),
                    ),
                    if (plan != null)
                      OutlinedButton.icon(
                        onPressed: onDeletePlan,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('删除'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (plan == null)
          const _EmptyPlanCard()
        else ...[
          _ScheduleCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(plan.overview),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TimeBlockTimeline(
            blocks: data.blocks,
            onEditBlock: onEditBlock,
            onDeleteBlock: onDeleteBlock,
          ),
          const SizedBox(height: 12),
          _SuggestionPanel(plan: plan),
        ],
      ],
    );
  }
}

class _TimeBlockTimeline extends StatelessWidget {
  const _TimeBlockTimeline({
    required this.blocks,
    required this.onEditBlock,
    required this.onDeleteBlock,
  });

  final List<ScheduleBlock> blocks;
  final ValueChanged<ScheduleBlock> onEditBlock;
  final ValueChanged<ScheduleBlock> onDeleteBlock;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const _ScheduleCard(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('这份计划暂时没有时间块。'),
        ),
      );
    }

    return _ScheduleCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            for (final block in blocks)
              _TimeBlockTile(
                block: block,
                onEdit: () => onEditBlock(block),
                onDelete: () => onDeleteBlock(block),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeBlockTile extends StatelessWidget {
  const _TimeBlockTile({
    required this.block,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _blockColor(block.blockType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timeText(block.startTime),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _timeText(block.endTime),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          block.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
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
                  if ((block.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(block.note!),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    block.reason,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({required this.plan});

  final SchedulePlan plan;

  @override
  Widget build(BuildContext context) {
    final suggestions = _decodeStringList(plan.suggestionsJson);
    final unscheduled = _decodeStringList(plan.unscheduledTaskIdsJson);
    if (suggestions.isEmpty && unscheduled.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ScheduleCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestions.isNotEmpty) ...[
              Text(
                '安排提醒',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final suggestion in suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $suggestion'),
                ),
            ],
            if (unscheduled.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '未排入时间块：${unscheduled.length} 个任务',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayPickerStrip extends StatelessWidget {
  const _DayPickerStrip({required this.selectedDay, required this.onSelectDay});

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final start = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
    final days = [for (var i = 0; i < 7; i += 1) start.add(Duration(days: i))];

    return _ScheduleCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '上一周',
                  onPressed: () => onSelectDay(
                    selectedDay.subtract(const Duration(days: 7)),
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${selectedDay.year} 年 ${selectedDay.month} 月',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '下一周',
                  onPressed: () =>
                      onSelectDay(selectedDay.add(const Duration(days: 7))),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _DayButton(
                        day: day,
                        selected: _sameDay(day, selectedDay),
                        onTap: () => onSelectDay(day),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayText(day.weekday),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard();

  @override
  Widget build(BuildContext context) {
    return const _ScheduleCard(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('还没有这一天的时间规划。可以先生成一份 AI 草稿，再手动调整。'),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: child);
  }
}

class _ScheduleDayData {
  const _ScheduleDayData({
    required this.day,
    required this.plan,
    required this.blocks,
    required this.tasks,
    required this.states,
    required this.profileItems,
    required this.recentSummaries,
  });

  final DateTime day;
  final SchedulePlan? plan;
  final List<ScheduleBlock> blocks;
  final List<Task> tasks;
  final List<ShortTermState> states;
  final List<ProfileItem> profileItems;
  final List<Summary> recentSummaries;
}

class _EditableBlock {
  const _EditableBlock({
    required this.title,
    required this.blockType,
    required this.startTime,
    required this.endTime,
    required this.note,
    required this.reason,
  });

  final String title;
  final String blockType;
  final DateTime startTime;
  final DateTime endTime;
  final String note;
  final String reason;
}

String _dateKey(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _dateTitle(DateTime value) {
  return '${value.month} 月 ${value.day} 日 ${_weekdayText(value.weekday)}';
}

String _timeText(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _weekdayText(int weekday) {
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return labels[weekday - 1];
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Color _blockColor(String blockType) {
  switch (blockType) {
    case 'task':
      return AppColors.primary;
    case 'break':
      return AppColors.mint;
    case 'buffer':
      return AppColors.orange;
    case 'review':
      return AppColors.purple;
    case 'personal':
    default:
      return const Color(0xFFFF6FAE);
  }
}

List<String> _decodeStringList(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is String) item,
    ];
  } catch (_) {
    return const [];
  }
}
