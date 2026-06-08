import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';
import '../../domain/item_type.dart';
import 'life_events_screen.dart';
import 'privacy_screen.dart';
import 'profile_items_screen.dart';
import 'short_term_states_screen.dart';
import 'task_time_formatter.dart';
import 'tasks_screen.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({
    required this.database,
    this.nowProvider = DateTime.now,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  late Future<_MemoryOverviewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_MemoryOverviewData> _loadData() async {
    final now = widget.nowProvider();
    final db = widget.database;
    final tasks = await db.getActiveTasks();
    final states = await db.getActiveShortTermStates(now: now);
    final events = await db.getActiveLifeEvents();
    final profiles = await db.getActiveProfileItems();
    final pendingTaskCount = await db.countPendingExtractedItemsByType(
      ItemType.taskCreate.apiValue,
    );
    final pendingProfileCount = await db.countPendingExtractedItemsByType(
      ItemType.profileCandidate.apiValue,
    );

    return _MemoryOverviewData(
      tasks: tasks,
      shortTermStates: states,
      lifeEvents: events,
      profileItems: profiles,
      taskUpdatedAt: tasks.isNotEmpty
          ? _latest(tasks.map((t) => t.updatedAt))
          : null,
      stateUpdatedAt: states.isNotEmpty
          ? _latest(states.map((s) => s.updatedAt))
          : null,
      eventUpdatedAt: events.isNotEmpty
          ? _latest(events.map((e) => e.updatedAt))
          : null,
      profileUpdatedAt: profiles.isNotEmpty
          ? _latest(profiles.map((p) => p.updatedAt))
          : null,
      pendingTaskCount: pendingTaskCount,
      pendingProfileCount: pendingProfileCount,
    );
  }

  static DateTime _latest(Iterable<DateTime> dates) {
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记忆管理')),
      body: FutureBuilder<_MemoryOverviewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final now = widget.nowProvider();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: const Text('隐私说明'),
                  subtitle: const Text('了解本地优先、AI 解析和长期画像确认规则'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const PrivacyScreen(),
                      ),
                    );
                  },
                ),
              ),
              _Section(
                title: '任务',
                count: data.tasks.length,
                updatedAt: data.taskUpdatedAt,
                pendingCount: data.pendingTaskCount,
                onViewAll: () => _navigate(
                  TasksScreen(
                    database: widget.database,
                    nowProvider: widget.nowProvider,
                  ),
                ),
                onRecordsChanged: _refresh,
                children: [
                  for (final task in data.tasks.take(3))
                    ListTile(
                      dense: true,
                      title: Text(task.title),
                      subtitle: Text(
                        formatTaskDueText(
                          dueTime: task.dueTime,
                          dueTimeText: task.dueTimeText,
                          now: now,
                        ),
                      ),
                    ),
                ],
              ),
              _Section(
                title: '短期状态',
                count: data.shortTermStates.length,
                updatedAt: data.stateUpdatedAt,
                onViewAll: () => _navigate(
                  ShortTermStatesScreen(
                    database: widget.database,
                    nowProvider: widget.nowProvider,
                  ),
                ),
                onRecordsChanged: _refresh,
                children: [
                  for (final state in data.shortTermStates.take(3))
                    ListTile(dense: true, title: Text(state.content)),
                ],
              ),
              _Section(
                title: '生活事件',
                count: data.lifeEvents.length,
                updatedAt: data.eventUpdatedAt,
                onViewAll: () => _navigate(
                  LifeEventsScreen(
                    database: widget.database,
                    nowProvider: widget.nowProvider,
                  ),
                ),
                onRecordsChanged: _refresh,
                children: [
                  for (final event in data.lifeEvents.take(3))
                    ListTile(dense: true, title: Text(event.content)),
                ],
              ),
              _Section(
                title: '长期画像',
                count: data.profileItems.length,
                updatedAt: data.profileUpdatedAt,
                pendingCount: data.pendingProfileCount,
                pendingLabel: '待确认',
                onViewAll: () => _navigate(
                  ProfileItemsScreen(
                    database: widget.database,
                    nowProvider: widget.nowProvider,
                  ),
                ),
                onRecordsChanged: _refresh,
                children: [
                  for (final profile in data.profileItems.take(3))
                    ListTile(dense: true, title: Text(profile.content)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigate(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => screen));
    _refresh();
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadData();
    });
  }
}

class _MemoryOverviewData {
  const _MemoryOverviewData({
    required this.tasks,
    required this.shortTermStates,
    required this.lifeEvents,
    required this.profileItems,
    this.taskUpdatedAt,
    this.stateUpdatedAt,
    this.eventUpdatedAt,
    this.profileUpdatedAt,
    this.pendingTaskCount = 0,
    this.pendingProfileCount = 0,
  });

  final List<Task> tasks;
  final List<ShortTermState> shortTermStates;
  final List<LifeEvent> lifeEvents;
  final List<ProfileItem> profileItems;
  final DateTime? taskUpdatedAt;
  final DateTime? stateUpdatedAt;
  final DateTime? eventUpdatedAt;
  final DateTime? profileUpdatedAt;
  final int pendingTaskCount;
  final int pendingProfileCount;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.children,
    required this.onViewAll,
    required this.onRecordsChanged,
    this.updatedAt,
    this.pendingCount,
    this.pendingLabel,
  });

  final String title;
  final int count;
  final List<Widget> children;
  final VoidCallback onViewAll;
  final VoidCallback onRecordsChanged;
  final DateTime? updatedAt;
  final int? pendingCount;
  final String? pendingLabel;

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (pendingCount != null && pendingCount! > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFC107)),
                    ),
                    child: Text(
                      '${pendingLabel ?? "待处理"} $pendingCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (count > 3)
                  InkWell(
                    onTap: onViewAll,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '查看全部',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (updatedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '最近更新：${_formatDate(updatedAt!)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8278)),
              ),
            ],
            const SizedBox(height: 8),
            if (children.isEmpty)
              const Text('暂无记录', style: TextStyle(color: Color(0xFF8A8278)))
            else
              ...children,
            if (count > 0)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('管理'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
