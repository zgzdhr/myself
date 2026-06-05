import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';

class ProfileItemsScreen extends StatefulWidget {
  const ProfileItemsScreen({
    required this.database,
    this.nowProvider = DateTime.now,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  State<ProfileItemsScreen> createState() => _ProfileItemsScreenState();
}

class _ProfileItemsScreenState extends State<ProfileItemsScreen> {
  late Future<_ProfileItemViewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_ProfileItemViewData> _load() async {
    final items = await widget.database.getActiveProfileItems();
    final ids = items.map((p) => p.sourceExtractedItemId).toList();
    final sourceTexts =
        await widget.database.getSourceTextsByExtractedItemIds(ids);
    return _ProfileItemViewData(items: items, sourceTexts: sourceTexts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('长期画像')),
      body: FutureBuilder<_ProfileItemViewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.items.isEmpty) {
            return const Center(child: Text('暂无长期画像'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in data.items)
                _buildProfileCard(context, item, data.sourceTexts),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    ProfileItem item,
    Map<String, String> sourceTexts,
  ) {
    final sourceText = sourceTexts[item.sourceExtractedItemId];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.content,
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
                  onPressed: () => _edit(item),
                  child: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _delete(item),
                  child: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(ProfileItem item) async {
    final editedContent = await showDialog<String>(
      context: context,
      builder: (context) {
        return _EditProfileDialog(initialContent: item.content);
      },
    );

    if (editedContent == null || editedContent.isEmpty) {
      return;
    }

    await widget.database.updateProfileItemContent(
      id: item.id,
      content: editedContent,
      updatedAt: widget.nowProvider(),
    );
    _refresh();
  }

  Future<void> _delete(ProfileItem item) async {
    await widget.database.markProfileItemDeleted(
      id: item.id,
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

class _ProfileItemViewData {
  const _ProfileItemViewData({required this.items, required this.sourceTexts});

  final List<ProfileItem> items;
  final Map<String, String> sourceTexts;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.initialContent});

  final String initialContent;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑长期画像'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
