part of 'input_screen.dart';

class _PendingBatchHeader extends StatelessWidget {
  const _PendingBatchHeader({required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final local = createdAt.toLocal();
    final label =
        '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return Text(
      '整理于 $label',
      style: const TextStyle(
        color: Color(0xFF8A8278),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AssistantReplyPanel extends StatelessWidget {
  const _AssistantReplyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF1D1D1F),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TaskUpdateSelectionSheet extends StatelessWidget {
  const _TaskUpdateSelectionSheet({required this.candidates});

  final List<TaskUpdateCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '请选择要更新的任务',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(candidate.title),
                subtitle: candidate.dueTimeText == null
                    ? null
                    : Text('当前时间：${candidate.dueTimeText}'),
                onTap: () => Navigator.of(context).pop(candidate),
              ),
          ],
        ),
      ),
    );
  }
}

class _TactileInputPanel extends StatelessWidget {
  const _TactileInputPanel({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isPressed,
    required this.onSubmit,
    required this.onPressChanged,
    this.compact = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isPressed;
  final VoidCallback onSubmit;
  final ValueChanged<bool> onPressChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isActive = focusNode.hasFocus || isPressed;

    if (compact) {
      return _CompactInputPanel(
        controller: controller,
        focusNode: focusNode,
        isLoading: isLoading,
        isActive: isActive,
        isPressed: isPressed,
        onSubmit: onSubmit,
        onPressChanged: onPressChanged,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focusNode.requestFocus,
      onTapDown: (_) => onPressChanged(true),
      onTapCancel: () => onPressChanged(false),
      onTapUp: (_) => onPressChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, isPressed ? 1.5 : 0, 0),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? const Color(0xFF2F7DF6) : const Color(0xFFE7EDF7),
            width: isActive ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(isPressed ? 0x0A2F7DF6 : 0x182F7DF6),
              offset: Offset(0, isPressed ? 5 : 16),
              blurRadius: isPressed ? 14 : 28,
            ),
            const BoxShadow(
              color: Color(0x88FFFFFF),
              offset: Offset(0, -1),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8E7FF)),
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFF2F7DF6),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今天想记点什么？',
                        style: TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '任务、状态、经历或一个问题',
                        style: TextStyle(
                          color: Color(0xFF78859D),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 3,
              maxLines: 8,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 17,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
                hintText: '例如：明天下午联系王总，我今天有点累。',
                hintStyle: TextStyle(
                  color: Color(0xFFAAA298),
                  fontSize: 17,
                  height: 1.42,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: _SubtlePulseLine()),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: isLoading ? null : onSubmit,
                  icon: Icon(
                    isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_upward_rounded,
                    size: 18,
                  ),
                  label: Text(isLoading ? '整理中...' : '整理'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2F7DF6),
                    foregroundColor: const Color(0xFFFFFCF7),
                    disabledBackgroundColor: const Color(0xFFB9B1A7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputQuickActions extends StatelessWidget {
  const _InputQuickActions({required this.onSelect, this.compact = false});

  final ValueChanged<String> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.event_note_rounded, Color(0xFF2F7DF6), '记一件事', '记一下：'),
      (Icons.task_alt_rounded, Color(0xFF22C59D), '记任务', '我要做：'),
      (
        Icons.sentiment_satisfied_alt_rounded,
        Color(0xFFFF9F43),
        '记状态',
        '我现在感觉：',
      ),
      (Icons.help_outline_rounded, Color(0xFF8B6FF7), '提问', '我想问：'),
    ];

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onSelect(actions[index].$4),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: compact ? 42 : null,
                padding: EdgeInsets.symmetric(vertical: compact ? 7 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(compact ? 13 : 16),
                  border: Border.all(color: const Color(0xFFE7EDF7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x102F7DF6),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: compact
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            actions[index].$1,
                            color: actions[index].$2,
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              actions[index].$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF33405A),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(
                            actions[index].$1,
                            color: actions[index].$2,
                            size: 20,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            actions[index].$3,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFF33405A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactInputPanel extends StatelessWidget {
  const _CompactInputPanel({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isActive,
    required this.isPressed,
    required this.onSubmit,
    required this.onPressChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isActive;
  final bool isPressed;
  final VoidCallback onSubmit;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focusNode.requestFocus,
      onTapDown: (_) => onPressChanged(true),
      onTapCancel: () => onPressChanged(false),
      onTapUp: (_) => onPressChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 94,
        padding: const EdgeInsets.fromLTRB(15, 12, 10, 9),
        transform: Matrix4.translationValues(0, isPressed ? 1 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF7FB0FF) : const Color(0xFFE7EDF7),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142F7DF6),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(right: 46, bottom: 28),
                hintText: '想记录什么，交给我吧…',
                hintStyle: TextStyle(color: Color(0xFFACB5C4), fontSize: 14),
                filled: false,
                border: InputBorder.none,
              ),
            ),
            Positioned(
              right: 6,
              top: -8,
              child: IconButton(
                tooltip: 'AI 整理',
                onPressed: isLoading ? null : onSubmit,
                icon: Icon(
                  isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.auto_awesome_rounded,
                  color: const Color(0xFF2F7DF6),
                  size: 20,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDE8F8)),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  size: 19,
                  color: Color(0xFF172033),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactResultsSection extends StatelessWidget {
  const _CompactResultsSection({
    required this.autoSavedItems,
    required this.pendingBatches,
    required this.onConfirm,
    required this.onEdit,
    required this.onReject,
  });

  final List<ExtractedItem> autoSavedItems;
  final List<PendingExtractedBatch> pendingBatches;
  final ValueChanged<ExtractedItem> onConfirm;
  final ValueChanged<ExtractedItem> onEdit;
  final ValueChanged<ExtractedItem> onReject;

  @override
  Widget build(BuildContext context) {
    final items = <ExtractedItem>[
      ...autoSavedItems,
      for (final batch in pendingBatches) ...batch.items,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI 整理结果',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Color(0xFF6D9FFF),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              Text(
                '共 ${items.length} 条',
                style: const TextStyle(
                  color: Color(0xFF8A96AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7EDF7)),
            ),
            child: const Text(
              '输入后，任务、状态和记忆会先在这里显示。',
              style: TextStyle(color: Color(0xFF8A96AA), fontSize: 12),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 16) / 3;
              return SizedBox(
                height: 98,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SizedBox(
                      width: cardWidth,
                      child: ExtractedItemCard(
                        item: item,
                        compact: true,
                        onConfirm: () => onConfirm(item),
                        onEdit: () => onEdit(item),
                        onReject: () => onReject(item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PendingEmptyPanel extends StatelessWidget {
  const _PendingEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E0D6)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0EC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5DFD8)),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 18,
              color: Color(0xFF53736A),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '待确认内容',
                  style: TextStyle(
                    color: Color(0xFF1D1D1F),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '整理后的任务、状态和记忆会先放在这里。',
                  style: TextStyle(
                    color: Color(0xFF8A8278),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtlePulseLine extends StatelessWidget {
  const _SubtlePulseLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _PulseSegment(width: 18, opacity: 0.28),
        _PulseSegment(width: 32, opacity: 0.5),
        _PulseSegment(width: 46, opacity: 0.75),
        _PulseSegment(width: 26, opacity: 0.45),
      ],
    );
  }
}

class _PulseSegment extends StatelessWidget {
  const _PulseSegment({required this.width, required this.opacity});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF53736A).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
