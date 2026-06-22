import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/local_db/app_database.dart';
import '../../data/review/review_client.dart';
import '../../domain/record_status.dart';
import '../../domain/review_result.dart';
import '../../domain/task_status.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    required this.database,
    required this.nowProvider,
    required this.reviewClient,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;
  final ReviewClient reviewClient;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  late Future<_ReviewMonthData> _monthFuture;
  late Future<_ReviewDayData> _dayFuture;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = widget.nowProvider();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _monthFuture = _loadMonth();
    _dayFuture = _loadDay(_selectedDay);
  }

  Future<_ReviewMonthData> _loadMonth() async {
    final start = DateTime(_visibleMonth.year, _visibleMonth.month);
    final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    final summaries = await widget.database.getSummariesForRange(
      start: start,
      end: end,
    );
    return _ReviewMonthData(
      month: start,
      weeks: _buildWeeks(start),
      summariesByDay: {
        for (final summary in summaries)
          _dayKey(summary.timeRangeStart): summary,
      },
    );
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

    return _ReviewDayData(
      day: start,
      tasks: tasks,
      states: states,
      events: events,
      profileItems: profiles,
      summary: summary,
      sources: sources,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复盘')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _MonthHeader(
              month: _visibleMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 12),
            FutureBuilder<_ReviewMonthData>(
              future: _monthFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  return const _LoadingCard(label: '正在整理复盘目录...');
                }
                return _MonthReviewFolders(
                  data: data,
                  selectedDay: _selectedDay,
                  onSelectDay: _selectDay,
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<_ReviewDayData>(
              future: _dayFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  return const _LoadingCard(label: '正在读取当天记录...');
                }
                return _DayReviewPanel(
                  data: data,
                  isGenerating: _isGenerating,
                  onGenerate: () => _generateReview(data),
                  onEdit: data.summary == null
                      ? null
                      : () => _editSummary(data.summary!),
                  onDelete: data.summary == null
                      ? null
                      : () => _deleteSummary(data.summary!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _monthFuture = _loadMonth();
      _dayFuture = _loadDay(_selectedDay);
    });
    await Future.wait([_monthFuture, _dayFuture]);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      _monthFuture = _loadMonth();
      _dayFuture = _loadDay(_selectedDay);
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _dayFuture = _loadDay(day);
    });
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
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('补充今天的感受'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(hintText: '例如：今天有点拖延，但下午状态好一些。'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('生成'),
            ),
          ],
        );
      },
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

  List<_ReviewWeek> _buildWeeks(DateTime month) {
    final end = DateTime(month.year, month.month + 1);
    final weeks = <_ReviewWeek>[];
    var weekStart = month;
    var index = 1;

    while (weekStart.isBefore(end)) {
      final weekEnd = weekStart.add(const Duration(days: 7)).isBefore(end)
          ? weekStart.add(const Duration(days: 7))
          : end;
      weeks.add(
        _ReviewWeek(
          label: '第$index周',
          days: [
            for (
              var day = weekStart;
              day.isBefore(weekEnd);
              day = day.add(const Duration(days: 1))
            )
              day,
          ],
        ),
      );
      weekStart = weekEnd;
      index += 1;
    }

    return weeks;
  }

  static String _dayKey(DateTime day) => _dateKey(day);

  static String _dateKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }
}

class _ReviewMonthData {
  const _ReviewMonthData({
    required this.month,
    required this.weeks,
    required this.summariesByDay,
  });

  final DateTime month;
  final List<_ReviewWeek> weeks;
  final Map<String, Summary> summariesByDay;
}

class _ReviewWeek {
  const _ReviewWeek({required this.label, required this.days});

  final String label;
  final List<DateTime> days;
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
  });

  final DateTime day;
  final List<Task> tasks;
  final List<ShortTermState> states;
  final List<LifeEvent> events;
  final List<ProfileItem> profileItems;
  final Summary? summary;
  final List<SummarySource> sources;

  int get sourceCount => tasks.length + states.length + events.length;

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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '上个月',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            '${month.year}年${month.month}月',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: '下个月',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _MonthReviewFolders extends StatelessWidget {
  const _MonthReviewFolders({
    required this.data,
    required this.selectedDay,
    required this.onSelectDay,
  });

  final _ReviewMonthData data;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final week in data.weeks)
            ExpansionTile(
              initiallyExpanded: week.days.any(_sameDayAsSelected),
              leading: const Icon(
                Icons.folder_rounded,
                color: Color(0xFF53736A),
              ),
              title: Text(
                week.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.25,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      for (final day in week.days)
                        _DayTile(
                          day: day,
                          selected: _sameDay(day, selectedDay),
                          hasSummary: data.summariesByDay.containsKey(
                            _ReviewScreenState._dayKey(day),
                          ),
                          onTap: () => onSelectDay(day),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool _sameDayAsSelected(DateTime day) => _sameDay(day, selectedDay);
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.selected,
    required this.hasSummary,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool hasSummary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF0EC) : const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF53736A) : const Color(0xFFE7E0D6),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Icon(
              hasSummary
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 16,
              color: hasSummary
                  ? const Color(0xFF53736A)
                  : const Color(0xFFB3AAA0),
            ),
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${data.day.month}月${data.day.day}日',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: '任务', value: data.tasks.length),
                _MetricChip(label: '状态', value: data.states.length),
                _MetricChip(label: '事件', value: data.events.length),
              ],
            ),
            const SizedBox(height: 16),
            if (summary == null)
              _EmptyReviewState(
                sourceCount: data.sourceCount,
                isGenerating: isGenerating,
                onGenerate: onGenerate,
              )
            else ...[
              _SummarySection(title: '今日总结', body: summary.content),
              _SummarySection(title: '鼓励', body: summary.encouragement),
              _SummarySection(title: '今天的不足', body: summary.improvementNotes),
              _SummarySection(title: '任务处理建议', body: summary.taskGuidance),
              _OpenItems(openItemsJson: summary.openItemsJson),
              const SizedBox(height: 8),
              Text(
                '来源依据 ${data.sources.length} 条',
                style: const TextStyle(
                  color: Color(0xFF8A8278),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('编辑'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isGenerating ? null : onGenerate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(isGenerating ? '生成中' : '重新生成'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('删除'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _SourcePreview(data: data),
          ],
        ),
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

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final text = body?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(height: 1.35)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('未解决事项', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          for (final item in items) Text('• $item'),
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

class _SourcePreview extends StatelessWidget {
  const _SourcePreview({required this.data});

  final _ReviewDayData data;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text(
        '当天来源记录',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      children: [
        if (data.sourceCount == 0)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('这一天还没有可见任务、状态或生活事件。'),
          ),
        for (final task in data.tasks)
          _SourceLine(icon: _taskIcon(task.taskStatus), label: task.title),
        for (final state in data.states)
          _SourceLine(
            icon: Icons.battery_charging_full_rounded,
            label: state.content,
          ),
        for (final event in data.events)
          _SourceLine(icon: Icons.event_note_rounded, label: event.content),
      ],
    );
  }

  static IconData _taskIcon(String taskStatus) {
    if (taskStatus == TaskStatus.completed.value) {
      return Icons.check_circle_rounded;
    }
    if (taskStatus == TaskStatus.cancelled.value) return Icons.cancel_rounded;
    return Icons.radio_button_checked_rounded;
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF53736A)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAE0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Color(0xFF3A3835),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
