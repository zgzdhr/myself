import 'package:flutter/material.dart';

import '../../domain/extracted_item.dart';

class EditedExtractedItem {
  const EditedExtractedItem({required this.title, required this.content});

  final String? title;
  final String? content;
}

class EditExtractedItemSheet extends StatefulWidget {
  const EditExtractedItemSheet({required this.item, super.key});

  final ExtractedItem item;

  @override
  State<EditExtractedItemSheet> createState() => _EditExtractedItemSheetState();
}

class _EditExtractedItemSheetState extends State<EditExtractedItemSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _contentController = TextEditingController(text: widget.item.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '编辑后确认',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('保存并确认')),
          ],
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      EditedExtractedItem(
        title: _emptyToNull(_titleController.text),
        content: _emptyToNull(_contentController.text),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
