import 'package:flutter/material.dart';

import '../../app/app_visuals.dart';
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
    final accent = _accentFor(item.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(item.type), color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeLabel(item.type, accent: accent),
                      const SizedBox(height: 4),
                      _SaveTarget(item.type),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
            Text(
              '来源：${item.sourceText}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
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
            Text(
              '置信度 ${(item.confidence * 100).round()}%',
              style: const TextStyle(color: AppColors.textMuted),
            ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                  if (!isTaskUpdate)
                    OutlinedButton(
                      onPressed: onEdit,
                      child: Text(isAutoSaved ? '修改' : '编辑'),
                    ),
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

  Color _accentFor(ItemType type) => switch (type) {
    ItemType.taskCreate || ItemType.taskUpdate => const Color(0xFFFF5C8A),
    ItemType.shortTermState => AppColors.mint,
    ItemType.lifeEvent => AppColors.orange,
    ItemType.profileCandidate => AppColors.purple,
    ItemType.generalAnswer => AppColors.primary,
  };

  IconData _iconFor(ItemType type) => switch (type) {
    ItemType.taskCreate => Icons.assignment_turned_in_outlined,
    ItemType.taskUpdate => Icons.update_rounded,
    ItemType.shortTermState => Icons.favorite_border_rounded,
    ItemType.lifeEvent => Icons.card_giftcard_rounded,
    ItemType.profileCandidate => Icons.psychology_alt_outlined,
    ItemType.generalAnswer => Icons.chat_bubble_outline_rounded,
  };

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

class _SaveTarget extends StatelessWidget {
  const _SaveTarget(this.type);

  final ItemType type;

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8A8278)),
    );
  }

  String get _text {
    return switch (type) {
      ItemType.taskCreate => '保存到：任务',
      ItemType.shortTermState => '保存到：短期状态',
      ItemType.lifeEvent => '保存到：生活事件',
      ItemType.profileCandidate => '保存到：长期画像；确认后才生效',
      ItemType.taskUpdate => '目标：更新已有任务，不新建记忆',
      ItemType.generalAnswer => '',
    };
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel(this.type, {required this.accent});

  final ItemType type;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          _label,
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
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
