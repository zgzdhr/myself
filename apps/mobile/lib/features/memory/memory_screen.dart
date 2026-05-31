import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';
import 'privacy_screen.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({
    required this.database,
    this.nowProvider = DateTime.now,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记忆管理')),
      body: FutureBuilder<_MemoryOverviewData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

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
                emptyText: '暂无任务记忆',
                children: [
                  for (final task in data.tasks)
                    ListTile(title: Text(task.title)),
                ],
              ),
              _Section(
                title: '短期状态',
                emptyText: '暂无短期状态',
                children: [
                  for (final state in data.shortTermStates)
                    ListTile(title: Text(state.content)),
                ],
              ),
              _Section(
                title: '生活事件',
                emptyText: '暂无生活事件',
                children: [
                  for (final event in data.lifeEvents)
                    ListTile(title: Text(event.content)),
                ],
              ),
              _Section(
                title: '长期画像',
                emptyText: '暂无长期画像',
                children: [
                  for (final profile in data.profileItems)
                    ListTile(title: Text(profile.content)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_MemoryOverviewData> _loadData() async {
    return _MemoryOverviewData(
      tasks: await database.getActiveTasks(),
      shortTermStates: await database.getActiveShortTermStates(
        now: nowProvider(),
      ),
      lifeEvents: await database.getActiveLifeEvents(),
      profileItems: await database.getActiveProfileItems(),
    );
  }
}

class _MemoryOverviewData {
  const _MemoryOverviewData({
    required this.tasks,
    required this.shortTermStates,
    required this.lifeEvents,
    required this.profileItems,
  });

  final List<Task> tasks;
  final List<ShortTermState> shortTermStates;
  final List<LifeEvent> lifeEvents;
  final List<ProfileItem> profileItems;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (children.isEmpty) Text(emptyText) else ...children,
          ],
        ),
      ),
    );
  }
}
