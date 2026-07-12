import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_visuals.dart';
import '../../data/local_db/app_database.dart';
import '../../data/plan/plan_client.dart';
import '../../data/review/review_client.dart';
import '../../domain/record_status.dart';
import '../../domain/review_result.dart';
import '../../domain/task_status.dart';
import 'schedule_plan_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    required this.database,
    required this.nowProvider,
    required this.reviewClient,
    required this.planClient,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;
  final ReviewClient reviewClient;
  final PlanClient planClient;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late DateTime _selectedDay;
  late Future<_ReviewDayData> _dayFuture;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = widget.nowProvider();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _dayFuture = _loadDay(_selectedDay);
  }

  Future<_ReviewDayData> _loadDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final tasks = await widget.database.getTasksForRange(
      start: start,
      end: end,
    );
    final states = await widget.database.getShortTermStatesForRange(
      start: start,
      end: end,
    );
    final events = await widget.database.getLifeEventsForRange(
      start: start,
      end: end,
    );
    final profiles = await widget.database.getActiveProfileItems();
    final summary = await widget.database.getSummaryForDay(day);
    final sources = summary == null
        ? <SummarySource>[]
        : await widget.database.getSourcesForSummary(summary.id);
    final schedulePlan = await widget.database.getSchedulePlanForDay(day);
    final scheduleBlocks = schedulePlan == null
        ? <ScheduleBlock>[]
        : await widget.database.getScheduleBlocksForPlan(schedulePlan.id);

    return _ReviewDayData(
      day: start,
      tasks: tasks,
      states: states,
      events: events,
      profileItems: profiles,
      summary: summary,
      sources: sources,
      schedulePlan: schedulePlan,
      scheduleBlocks: scheduleBlocks,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _ReviewHeader(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const SizedBox(
                    height: 40,
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: [
                        Tab(text: '每日复盘'),
                        Tab(text: '时间规划'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Builder(
                      builder: (tabContext) => RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          children: [
                            _ReviewDateSelector(
                              day: _selectedDay,
                              onTap: _chooseReviewDate,
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<_ReviewDayData>(
                              future: _dayFuture,
                              builder: (context, snapshot) {
                                final data = snapshot.data;
                                if (data == null) {
                                  return const _LoadingCard(
                                    label: '正在读取当天记录...',
                                  );
                                }
                                return Column(
                                  children: [
                                    _DayReviewPanel(
                                      data: data,
                                      isGenerating: _isGenerating,
                                      onGenerate: () => _generateReview(data),
                                      onEdit: data.summary == null
                                          ? null
                                          : () => _editSummary(data.summary!),
                                      onDelete: data.summary == null
                                          ? null
                                          : () => _deleteSummary(data.summary!),
                                    ),
                                    const SizedBox(height: 12),
                                    _SchedulePreviewCard(
                                      data: data,
                                      onOpen: () => DefaultTabController.of(
                                        tabContext,
                                      ).animateTo(1),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SchedulePlanScreen(
                      database: widget.database,
                      nowProvider: widget.nowProvider,
                      planClient: widget.planClient,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Future<void> _chooseReviewDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '切换复盘日期',
    );
    if (day != null) _selectDay(day);
  }

  Future<void> _generateReview(_ReviewDayData data) async {
    final note = await _askUserNote();
    if (!mounted || note == null) return;

    setState(() => _isGenerating = true);

    try {
      final result = await widget.reviewClient.generateDailyReview(
        _buildReviewRequest(data, note),
      );
      await _saveReviewResult(data, result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('今日复盘已生成。')));
      await _reload();
    } on ReviewFailure catch (error) {
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

  Future<String?> _askUserNote() {
    return showAppTextPromptSheet(
      context: context,
      title: '补充今天的感受',
      subtitle: '记录真实感受，帮助 AI 生成更贴合你的复盘',
      hintText: '此刻感觉如何？有哪些收获或不足？对接下来的计划有什么想法…',
      confirmLabel: '生成复盘',
      icon: Icons.edit_note_rounded,
    );
  }

  Future<void> _saveReviewResult(
    _ReviewDayData data,
    ReviewResult result,
  ) async {
    final now = widget.nowProvider();
    final summaryId = const Uuid().v4();
    final sourceRefs = result.sourceRefs.isEmpty
        ? data.defaultSourceRefs
        : result.sourceRefs;

    await widget.database.saveDailySummary(
      updatedAt: now,
      summary: Summary(
        id: summaryId,
        summaryType: 'daily_summary',
        title: result.title,
        content: result.dailySummary,
        encouragement: result.encouragement,
        improvementNotes: result.improvementNotes,
        taskGuidance: result.taskGuidance,
        openItemsJson: jsonEncode(result.openItems),
        timeRangeStart: data.day,
        timeRangeEnd: data.day.add(const Duration(days: 1)),
        status: RecordStatus.confirmed.value,
        generatedBy: 'deepseek',
        modelName: null,
        promptVersion: 'review-daily-v1',
        confidence: result.confidence,
        createdAt: now,
        updatedAt: now,
        userEditedAt: null,
        deletedAt: null,
      ),
      sources: [
        for (final source in sourceRefs)
          SummarySourcesCompanion.insert(
            id: const Uuid().v4(),
            summaryId: summaryId,
            sourceTable: source.sourceTable,
            sourceRecordId: source.sourceRecordId,
            sourceStatusAtGeneration: Value(RecordStatus.confirmed.value),
            createdAt: now,
          ),
      ],
    );
  }

  Map<String, Object?> _buildReviewRequest(_ReviewDayData data, String note) {
    return {
      'timezone': 'Asia/Shanghai',
      'review_date': _dateKey(data.day),
      'current_time_iso': widget.nowProvider().toIso8601String(),
      'user_note': note.trim(),
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
      'life_events': [
        for (final event in data.events)
          {'id': event.id, 'content': event.content, 'status': event.status},
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
    };
  }

  Future<void> _editSummary(Summary summary) async {
    final contentController = TextEditingController(text: summary.content);
    final encouragementController = TextEditingController(
      text: summary.encouragement ?? '',
    );
    final improvementController = TextEditingController(
      text: summary.improvementNotes ?? '',
    );
    final guidanceController = TextEditingController(
      text: summary.taskGuidance ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑复盘'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EditField(label: '今日总结', controller: contentController),
                _EditField(label: '鼓励', controller: encouragementController),
                _EditField(label: '不足与改进', controller: improvementController),
                _EditField(label: '任务建议', controller: guidanceController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;
    await widget.database.updateSummaryContent(
      id: summary.id,
      content: contentController.text.trim(),
      encouragement: encouragementController.text.trim(),
      improvementNotes: improvementController.text.trim(),
      taskGuidance: guidanceController.text.trim(),
      updatedAt: widget.nowProvider(),
    );
    await _reload();
  }

  Future<void> _deleteSummary(Summary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除这天复盘？'),
          content: const Text('删除后它不会再参与后续建议，但原始任务、状态和事件不会被删除。'),
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
        );
      },
    );

    if (confirmed != true) return;
    await widget.database.markSummaryDeleted(
      id: summary.id,
      updatedAt: widget.nowProvider(),
    );
    await _reload();
  }

  static String _dateKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }
}

class _ReviewDayData {
  const _ReviewDayData({
    required this.day,
    required this.tasks,
    required this.states,
    required this.events,
    required this.profileItems,
    required this.summary,
    required this.sources,
    required this.schedulePlan,
    required this.scheduleBlocks,
  });

  final DateTime day;
  final List<Task> tasks;
  final List<ShortTermState> states;
  final List<LifeEvent> events;
  final List<ProfileItem> profileItems;
  final Summary? summary;
  final List<SummarySource> sources;
  final SchedulePlan? schedulePlan;
  final List<ScheduleBlock> scheduleBlocks;

  int get sourceCount => tasks.length + states.length + events.length;
  int get completedTaskCount => tasks
      .where((task) => task.taskStatus == TaskStatus.completed.value)
      .length;

  List<ReviewSourceRef> get defaultSourceRefs {
    return [
      for (final task in tasks)
        ReviewSourceRef(sourceTable: 'tasks', sourceRecordId: task.id),
      for (final state in states)
        ReviewSourceRef(
          sourceTable: 'short_term_states',
          sourceRecordId: state.id,
        ),
      for (final event in events)
        ReviewSourceRef(sourceTable: 'life_events', sourceRecordId: event.id),
    ];
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader();

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
                '复盘',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '回顾总结，持续进步',
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
          child: const Icon(Icons.adjust_rounded, color: AppColors.text),
        ),
      ],
    );
  }
}

class _ReviewDateSelector extends StatelessWidget {
  const _ReviewDateSelector({required this.day, required this.onTap});

  final DateTime day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                '${day.year}年${day.month}月${day.day}日',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
              const Spacer(),
              const Text(
                '切换日期',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.textMuted,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulePreviewCard extends StatelessWidget {
  const _SchedulePreviewCard({required this.data, required this.onOpen});

  final _ReviewDayData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final plan = data.schedulePlan;
    final blocks = data.scheduleBlocks;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '时间规划（AI 规划草稿）',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${data.day.month}月${data.day.day}日',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan?.title ?? '这一天还没有时间规划草稿',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan?.overview ?? '可根据当天任务、状态和习惯生成可确认的时间分配方案。',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            if (blocks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final block in blocks.take(5))
                    _PlanBlockPreview(block: block),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: Icon(
                  plan == null
                      ? Icons.auto_awesome_rounded
                      : Icons.grid_view_rounded,
                ),
                label: Text(plan == null ? '生成时间规划' : '查看并编辑时间块'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBlockPreview extends StatelessWidget {
  const _PlanBlockPreview({required this.block});

  final ScheduleBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_shortTime(block.startTime)}–${_shortTime(block.endTime)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static String _shortTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DayReviewPanel extends StatelessWidget {
  const _DayReviewPanel({
    required this.data,
    required this.isGenerating,
    required this.onGenerate,
    required this.onEdit,
    required this.onDelete,
  });

  final _ReviewDayData data;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当天记录汇总',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _ReviewMetricTile(
                    icon: Icons.check_box_rounded,
                    color: AppColors.primary,
                    label: '任务完成',
                    value: '${data.completedTaskCount} / ${data.tasks.length}',
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _ReviewMetricTile(
                    icon: Icons.bolt_rounded,
                    color: AppColors.mint,
                    label: '当前状态',
                    value: '${data.states.length} 条',
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _ReviewMetricTile(
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    color: AppColors.orange,
                    label: '记录条数',
                    value: '${data.events.length} 条',
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _ReviewMetricTile(
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.purple,
                    label: '来源依据',
                    value: '${data.sourceCount} 条',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summary == null)
              _EmptyReviewState(
                sourceCount: data.sourceCount,
                isGenerating: isGenerating,
                onGenerate: onGenerate,
              )
            else ...[
              _ReviewInsightCard(
                title: '今日总结',
                body: summary.content,
                icon: Icons.summarize_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(height: 9),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ReviewInsightCard(
                        title: '鼓励',
                        body: summary.encouragement,
                        icon: Icons.thumb_up_alt_outlined,
                        color: AppColors.mint,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ReviewInsightCard(
                        title: '不足',
                        body: summary.improvementNotes,
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _ReviewInsightCard(
                title: '任务建议',
                body: summary.taskGuidance,
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.primary,
              ),
              _OpenItems(openItemsJson: summary.openItemsJson),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('编辑'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: isGenerating ? null : onGenerate,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(isGenerating ? '生成中' : '重新生成'),
                    ),
                  ),
                  IconButton(
                    tooltip: '删除复盘',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              Text(
                '来源依据 ${data.sources.length} 条',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewMetricTile extends StatelessWidget {
  const _ReviewMetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewInsightCard extends StatelessWidget {
  const _ReviewInsightCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String? body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = body?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 10,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState({
    required this.sourceCount,
    required this.isGenerating,
    required this.onGenerate,
  });

  final int sourceCount;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAE0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这一天还没有复盘',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('当前可用于复盘的任务、状态和事件共 $sourceCount 条。'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isGenerating ? null : onGenerate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(isGenerating ? '生成中...' : '生成这天复盘'),
          ),
        ],
      ),
    );
  }
}

class _OpenItems extends StatelessWidget {
  const _OpenItems({required this.openItemsJson});

  final String openItemsJson;

  @override
  Widget build(BuildContext context) {
    final items = _decodeOpenItems(openItemsJson);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7, bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '未解决事项',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          for (final item in items)
            Text('• $item', style: const TextStyle(fontSize: 10, height: 1.3)),
        ],
      ),
    );
  }

  static List<String> _decodeOpenItems(String value) {
    try {
      return [for (final item in jsonDecode(value) as List) item as String];
    } catch (_) {
      return const [];
    }
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 5,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}
