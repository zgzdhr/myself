import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    required this.database,
    required this.nowProvider,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late Future<_ReviewOverviewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_ReviewOverviewData> _load() async {
    final now = widget.nowProvider();
    final tasks = await widget.database.getVisibleTasks();
    final states = await widget.database.getActiveShortTermStates(now: now);
    final events = await widget.database.getActiveLifeEvents();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final todayTasks = [
      for (final task in tasks)
        if (task.dueTime != null &&
            !task.dueTime!.isBefore(todayStart) &&
            task.dueTime!.isBefore(tomorrowStart))
          task,
    ];

    return _ReviewOverviewData(
      todayTaskCount: todayTasks.length,
      activeStateCount: states.length,
      lifeEventCount: events.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复盘')),
      body: FutureBuilder<_ReviewOverviewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ReviewHeroCard(
                todayTaskCount: data?.todayTaskCount,
                activeStateCount: data?.activeStateCount,
                lifeEventCount: data?.lifeEventCount,
                onGenerate: () => _showComingSoon('每日复盘生成'),
              ),
              const SizedBox(height: 16),
              _ReviewActionCard(
                icon: Icons.today_rounded,
                title: '今日复盘',
                subtitle: '整理今天的任务、状态和事件，生成一段可编辑总结。',
                trailing: '待接入',
                onTap: () => _showComingSoon('今日复盘'),
              ),
              const SizedBox(height: 10),
              _ReviewActionCard(
                icon: Icons.history_rounded,
                title: '历史复盘',
                subtitle: '之后可以按日期回看每日总结和当时的来源记录。',
                trailing: '待接入',
                onTap: () => _showComingSoon('历史复盘'),
              ),
              const SizedBox(height: 10),
              _ReviewActionCard(
                icon: Icons.auto_awesome_rounded,
                title: '复盘如何影响建议',
                subtitle: '第一版只作为轻上下文，帮助首页给出任务处理建议。',
                trailing: '弱上下文',
                onTap: () => _showComingSoon('复盘建议说明'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$featureName 会在接入 /review 后启用。')));
  }
}

class _ReviewOverviewData {
  const _ReviewOverviewData({
    required this.todayTaskCount,
    required this.activeStateCount,
    required this.lifeEventCount,
  });

  final int todayTaskCount;
  final int activeStateCount;
  final int lifeEventCount;
}

class _ReviewHeroCard extends StatelessWidget {
  const _ReviewHeroCard({
    required this.todayTaskCount,
    required this.activeStateCount,
    required this.lifeEventCount,
    required this.onGenerate,
  });

  final int? todayTaskCount;
  final int? activeStateCount;
  final int? lifeEventCount;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0EC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD5DFD8)),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF53736A),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '今天复盘了吗？',
                    style: TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '系统会先看今天可见的任务、状态和生活事件，再结合你的补充文字生成总结。',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: '今日任务', value: todayTaskCount),
                _MetricChip(label: '当前状态', value: activeStateCount),
                _MetricChip(label: '生活事件', value: lifeEventCount),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('生成今日复盘'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAE0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${value ?? '-'}',
        style: const TextStyle(
          color: Color(0xFF3A3835),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReviewActionCard extends StatelessWidget {
  const _ReviewActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF53736A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF8A8278),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8278)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
