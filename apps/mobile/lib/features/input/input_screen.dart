import 'package:flutter/material.dart';

import '../../data/parser/parser_client.dart';
import '../../domain/extracted_item.dart';
import '../extracted_items/edit_extracted_item_sheet.dart';
import '../extracted_items/extracted_item_card.dart';
import '../extracted_items/extracted_items_controller.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({required this.controller, super.key});

  final ExtractedItemsController controller;

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _textController = TextEditingController();
  var _isLoading = false;
  String? _errorMessage;
  List<ExtractedItem> _items = const [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              '万能输入框',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('把任务、状态、经历或偏好直接说出来，我会先整理成待确认卡片。'),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例如：明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: Text(_isLoading ? '整理中…' : '整理'),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '待确认内容',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final item in _items)
                ExtractedItemCard(
                  item: item,
                  onConfirm: () => _confirm(item),
                  onEdit: () => _edit(item),
                  onReject: () => _reject(item),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.controller.submitInput(_textController.text);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = result.items;
      });
    } on ParserFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.userMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirm(ExtractedItem item) async {
    await widget.controller.confirmExtractedItem(extractedItemId: item.localId);
    _removeItem(item);
  }

  Future<void> _edit(ExtractedItem item) async {
    final editedItem = await showModalBottomSheet<EditedExtractedItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditExtractedItemSheet(item: item),
    );

    if (editedItem == null) {
      return;
    }

    await widget.controller.confirmExtractedItem(
      extractedItemId: item.localId,
      editedTitle: editedItem.title,
      editedContent: editedItem.content,
    );
    _removeItem(item);
  }

  Future<void> _reject(ExtractedItem item) async {
    await widget.controller.rejectExtractedItem(extractedItemId: item.localId);
    _removeItem(item);
  }

  void _removeItem(ExtractedItem item) {
    if (!mounted) {
      return;
    }

    setState(() {
      _items = [
        for (final currentItem in _items)
          if (currentItem.localId != item.localId) currentItem,
      ];
    });
  }
}
