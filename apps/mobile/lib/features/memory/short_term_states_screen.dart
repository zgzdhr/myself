import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';

class ShortTermStatesScreen extends StatefulWidget {
  const ShortTermStatesScreen({
    required this.database,
    this.nowProvider = DateTime.now,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  State<ShortTermStatesScreen> createState() => _ShortTermStatesScreenState();
}

class _ShortTermStatesScreenState extends State<ShortTermStatesScreen> {
  late Future<_ShortTermStateViewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_ShortTermStateViewData> _load() async {
    final states = await widget.database.getActiveShortTermStates(
      now: widget.nowProvider(),
    );
    final ids = states.map((s) => s.sourceExtractedItemId).toList();
    final sourceTexts =
        await widget.database.getSourceTextsByExtractedItemIds(ids);
    return _ShortTermStateViewData(states: states, sourceTexts: sourceTexts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('短期状态')),
      body: FutureBuilder<_ShortTermStateViewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.states.isEmpty) {
            return const Center(child: Text('暂无短期状态'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final state in data.states)
                _buildStateCard(context, state, data.sourceTexts),
            ],
          );
        },
      ),
    );
  }

  static String _formatValidUntil(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Widget _buildStateCard(
    BuildContext context,
    ShortTermState state,
    Map<String, String> sourceTexts,
  ) {
    final sourceText = sourceTexts[state.sourceExtractedItemId];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.content,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '有效期至：${_formatValidUntil(state.validUntil)}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
            if (sourceText != null && sourceText.isNotEmpty) ...[
              const SizedBox(height: 6),
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
                  onPressed: () => _delete(state),
                  child: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(ShortTermState state) async {
    await widget.database.markShortTermStateDeleted(
      id: state.id,
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

class _ShortTermStateViewData {
  const _ShortTermStateViewData({
    required this.states,
    required this.sourceTexts,
  });

  final List<ShortTermState> states;
  final Map<String, String> sourceTexts;
}
