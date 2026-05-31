import 'package:flutter/material.dart';

import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';

class ExtractedItemCard extends StatelessWidget {
  const ExtractedItemCard({
    required this.item,
    this.onConfirm,
    this.onEdit,
    this.onReject,
    super.key,
  });

  final ExtractedItem item;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final title = item.title ?? item.content ?? item.sourceText;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeLabel(item.type),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text('来源：${item.sourceText}'),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in item.tags) Chip(label: Text(tag)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text('置信度 ${(item.confidence * 100).round()}%'),
            if (item.expiresAt != null) ...[
              const SizedBox(height: 8),
              Text('有效期至 ${_formatDate(item.expiresAt!)}'),
            ],
            if (item.type == ItemType.profileCandidate) ...[
              const SizedBox(height: 10),
              const Text(
                '确认后才会成为长期记忆',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(onPressed: onConfirm, child: const Text('确认')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onEdit, child: const Text('编辑')),
                const SizedBox(width: 8),
                TextButton(onPressed: onReject, child: const Text('拒绝')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel(this.type);

  final ItemType type;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          _label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String get _label {
    return switch (type) {
      ItemType.taskCreate => '新任务',
      ItemType.taskUpdate => '任务更新',
      ItemType.shortTermState => '短期状态',
      ItemType.lifeEvent => '生活事件',
      ItemType.generalAnswer => '普通问答',
      ItemType.profileCandidate => '长期画像候选',
    };
  }
}
