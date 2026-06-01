import 'package:flutter/material.dart';

import '../../data/parser/parser_client.dart';
import '../../domain/extracted_item.dart';
import '../extracted_items/edit_extracted_item_sheet.dart';
import '../extracted_items/extracted_item_card.dart';
import '../extracted_items/extracted_items_controller.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({
    required this.controller,
    this.header,
    this.afterInput,
    this.onRecordsChanged,
    super.key,
  });

  final ExtractedItemsController controller;
  final Widget? header;
  final Widget? afterInput;
  final VoidCallback? onRecordsChanged;

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  var _isLoading = false;
  String? _errorMessage;
  List<ExtractedItem> _items = const [];
  var _isInputPressed = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(_handleInputFocusChange);
  }

  @override
  void dispose() {
    _inputFocusNode
      ..removeListener(_handleInputFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: ListView(
          children: [
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(height: 20),
            ],
            _TactileInputPanel(
              controller: _textController,
              focusNode: _inputFocusNode,
              isLoading: _isLoading,
              isPressed: _isInputPressed,
              onSubmit: _submit,
              onPressChanged: (isPressed) {
                setState(() {
                  _isInputPressed = isPressed;
                });
              },
            ),
            if (widget.afterInput != null) ...[
              const SizedBox(height: 20),
              widget.afterInput!,
            ],
            if (_isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFF53736A),
                backgroundColor: Color(0xFFE7E0D6),
              ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1D1D1F),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final item in _items)
                ExtractedItemCard(
                  item: item,
                  onConfirm: () => _confirm(item),
                  onEdit: () => _edit(item),
                  onReject: () => _reject(item),
                ),
            ] else if (!_isLoading) ...[
              const SizedBox(height: 20),
              const _PendingEmptyPanel(),
            ],
          ],
        ),
      ),
    );
  }

  void _handleInputFocusChange() {
    if (mounted) {
      setState(() {});
    }
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
        _errorMessage = error.code == 'empty_input'
            ? error.userMessage
            : parserFailureDisplayMessage;
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
    widget.onRecordsChanged?.call();
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
    widget.onRecordsChanged?.call();
  }

  Future<void> _reject(ExtractedItem item) async {
    await widget.controller.rejectExtractedItem(extractedItemId: item.localId);
    _removeItem(item);
    widget.onRecordsChanged?.call();
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

class _TactileInputPanel extends StatelessWidget {
  const _TactileInputPanel({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isPressed,
    required this.onSubmit,
    required this.onPressChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isPressed;
  final VoidCallback onSubmit;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = focusNode.hasFocus || isPressed;

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF53736A) : const Color(0xFFE7E0D6),
            width: isActive ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(isPressed ? 0x0A000000 : 0x18000000),
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
                    color: const Color(0xFFEAF0EC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD5DFD8)),
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFF53736A),
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
                          color: Color(0xFF1D1D1F),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '先把想法放进来',
                        style: TextStyle(
                          color: Color(0xFF8A8278),
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
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 17,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
                hintText: '例如：明天上午联系王总，我今天有点累。',
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
                    backgroundColor: const Color(0xFF1F2A27),
                    foregroundColor: const Color(0xFFFFFCF7),
                    disabledBackgroundColor: const Color(0xFFB9B1A7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
