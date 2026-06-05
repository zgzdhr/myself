import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';

class LifeEventsScreen extends StatefulWidget {
  const LifeEventsScreen({
    required this.database,
    this.nowProvider = DateTime.now,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  State<LifeEventsScreen> createState() => _LifeEventsScreenState();
}

class _LifeEventsScreenState extends State<LifeEventsScreen> {
  late Future<_LifeEventViewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_LifeEventViewData> _load() async {
    final events = await widget.database.getActiveLifeEvents();
    final ids = events.map((e) => e.sourceExtractedItemId).toList();
    final sourceTexts =
        await widget.database.getSourceTextsByExtractedItemIds(ids);
    return _LifeEventViewData(events: events, sourceTexts: sourceTexts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生活事件')),
      body: FutureBuilder<_LifeEventViewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.events.isEmpty) {
            return const Center(child: Text('暂无生活事件'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final event in data.events)
                _buildEventCard(context, event, data.sourceTexts),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    LifeEvent event,
    Map<String, String> sourceTexts,
  ) {
    final sourceText = sourceTexts[event.sourceExtractedItemId];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.content,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (sourceText != null && sourceText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '来源：$sourceText',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _delete(event),
                  child: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(LifeEvent event) async {
    await widget.database.markLifeEventDeleted(
      id: event.id,
      updatedAt: widget.nowProvider(),
    );
    _refresh();
  }

  void _refresh() {
    setState(() {
      _dataFuture = _load();
    });
  }
}

class _LifeEventViewData {
  const _LifeEventViewData({required this.events, required this.sourceTexts});

  final List<LifeEvent> events;
  final Map<String, String> sourceTexts;
}
