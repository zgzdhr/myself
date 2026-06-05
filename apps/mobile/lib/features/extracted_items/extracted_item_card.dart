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
    final isTaskUpdate =
        item.type == ItemType.taskUpdate && taskUpdateIntent != null;
    final taskUpdateButtonLabel = switch (taskUpdateIntent?.resolution) {
      TaskUpdateResolution.needsSelection => '选择任务',
      _ => '确认更新',
    };
    final taskUpdateRejectLabel =
        taskUpdateIntent?.resolution == TaskUpdateResolution.noMatch
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
            if (!isTaskUpdate &&
                item.content != null &&
                item.content != title) ...[
              const SizedBox(height: 8),
              Text(item.content!),
            ],
            const SizedBox(height: 8),
            Text('来源：${item.sourceText}'),
            if (isTaskUpdate) ...[
              const SizedBox(height: 10),
              _TaskUpdateResolutionPanel(intent: taskUpdateIntent),
            ],
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

class _TaskUpdateResolutionPanel extends StatelessWidget {
  const _TaskUpdateResolutionPanel({required this.intent});

  final TaskUpdateIntent intent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6DDD1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: switch (intent.resolution) {
          TaskUpdateResolution.ready => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我理解你想更新：${intent.targetLabel}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(_readyActionText(intent)),
            ],
          ),
          TaskUpdateResolution.needsSelection => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你说的是哪一个任务？',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final candidate in intent.candidates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(candidate.title),
                      if (candidate.dueTimeText != null &&
                          candidate.dueTimeText!.isNotEmpty)
                        Text(
                          '当前时间：${candidate.dueTimeText}',
                          style: textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
            ],
          ),
          TaskUpdateResolution.noMatch => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('我没有找到对应任务。', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('这次不会修改任何任务。'),
            ],
          ),
        },
      ),
    );
  }

  String _readyActionText(TaskUpdateIntent intent) {
    return switch (intent.action) {
      TaskUpdateAction.complete => '将标记为已完成',
      TaskUpdateAction.cancel => '将取消这个任务',
      TaskUpdateAction.delay => '将延期到 ${intent.dueTimeText ?? '新的时间'}',
      TaskUpdateAction.edit => '将更新这个任务',
    };
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
