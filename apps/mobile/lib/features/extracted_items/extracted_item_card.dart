import 'package:flutter/material.dart';

import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';
import '../../domain/record_status.dart';
import 'extracted_items_controller.dart';

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
    final isAutoSaved = item.status == RecordStatus.confirmed;
    final taskUpdateIntent = item.taskUpdateIntent;
    final isTaskUpdate = item.type == ItemType.taskUpdate && taskUpdateIntent != null;
    final taskUpdateButtonLabel = switch (taskUpdateIntent?.resolution) {
      TaskUpdateResolution.needsSelection => '选择任务',
      _ => '确认更新',
    };
    final taskUpdateRejectLabel = taskUpdateIntent?.resolution == TaskUpdateResolution.noMatch
        ? '关闭'
        : '拒绝';

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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (item.content != null && item.content != title) ...[
              const SizedBox(height: 8),
              Text(item.content!),
            ],
            const SizedBox(height: 8),
            Text('来源：${item.sourceText}'),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final tag in item.tags) Chip(label: Text(tag))],
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
            if (isAutoSaved) ...[
              const SizedBox(height: 10),
              const Text(
                ExtractedItemsController.autoSaveHint,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (isTaskUpdate &&
                    taskUpdateIntent.resolution != TaskUpdateResolution.noMatch)
                  FilledButton(
                    onPressed: onConfirm,
                    child: Text(taskUpdateButtonLabel),
                  ),
                if (!isTaskUpdate && !isAutoSaved)
                  FilledButton(onPressed: onConfirm, child: const Text('确认')),
                if ((isTaskUpdate &&
                        taskUpdateIntent.resolution !=
                            TaskUpdateResolution.noMatch) ||
                    (!isTaskUpdate && !isAutoSaved))
                  const SizedBox(width: 8),
                if (!isTaskUpdate)
                  OutlinedButton(
                    onPressed: onEdit,
                    child: Text(isAutoSaved ? '修改' : '编辑'),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onReject,
                  child: Text(
                    isTaskUpdate
                        ? taskUpdateRejectLabel
                        : (isAutoSaved ? '撤销' : '拒绝'),
                  ),
                ),
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
