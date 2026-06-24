import 'package:flutter/material.dart';

import '../../data/parser/parser_client.dart';
import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';
import '../../domain/record_status.dart';
import '../extracted_items/edit_extracted_item_sheet.dart';
import '../extracted_items/extracted_item_card.dart';
import '../extracted_items/extracted_items_controller.dart';

part 'input_screen_widgets.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({
    required this.controller,
    this.header,
    this.afterInput,
    this.onRecordsChanged,
    this.onRefresh,
    super.key,
  });

  final ExtractedItemsController controller;
  final Widget? header;
  final Widget? afterInput;
  final VoidCallback? onRecordsChanged;
  final Future<void> Function()? onRefresh;

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  var _isLoading = false;
  String? _errorMessage;
  String? _assistantReply;
  List<ExtractedItem> _currentAutoSavedItems = const [];
  List<PendingExtractedBatch> _pendingBatches = const [];
  var _isInputPressed = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(_handleInputFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPendingBatches();
    });
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
    final listView = ListView(
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
        if (_assistantReply != null) ...[
          const SizedBox(height: 20),
          _AssistantReplyPanel(message: _assistantReply!),
        ],
        if (_currentAutoSavedItems.isNotEmpty ||
            _pendingBatches.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            _currentAutoSavedItems.isNotEmpty && _pendingBatches.isEmpty
                ? '已整理内容'
                : '整理结果',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1D1D1F),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in _currentAutoSavedItems)
            ExtractedItemCard(
              item: item,
              onConfirm: () => _confirm(item),
              onEdit: () => _edit(item),
              onReject: () => _reject(item),
            ),
          for (final batch in _pendingBatches) ...[
            _PendingBatchHeader(createdAt: batch.createdAt),
            const SizedBox(height: 8),
            for (final item in batch.items)
              ExtractedItemCard(
                item: item,
                onConfirm: () => _confirm(item),
                onEdit: () => _edit(item),
                onReject: () => _reject(item),
              ),
            const SizedBox(height: 10),
          ],
        ],
        if (widget.afterInput != null) ...[
          const SizedBox(height: 20),
          widget.afterInput!,
        ],
        if (_currentAutoSavedItems.isEmpty &&
            _pendingBatches.isEmpty &&
            !_isLoading &&
            _assistantReply == null &&
            _errorMessage == null) ...[
          const SizedBox(height: 20),
          const _PendingEmptyPanel(),
        ],
      ],
    );

    final scrollable = widget.onRefresh != null
        ? RefreshIndicator(onRefresh: widget.onRefresh!, child: listView)
        : listView;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: scrollable,
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
      _assistantReply = null;
    });

    try {
      final result = await widget.controller.submitInput(_textController.text);

      if (!mounted) {
        return;
      }

      setState(() {
        _assistantReply = result.parseResult.userReply;
        _currentAutoSavedItems = [
          for (final item in result.items)
            if (item.status == RecordStatus.confirmed) item,
        ];
      });
      await _refreshPendingBatches();
      _showAutoSavedFeedback(result.items);
      if (result.items.isNotEmpty) {
        widget.onRecordsChanged?.call();
      }
    } on ParserFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _assistantReply = null;
        _errorMessage =
            (error.code == 'empty_input' || error.code == 'input_too_long')
            ? error.userMessage
            : '$parserFailureDisplayMessage\n原因：${_safeParserFailureDetail(error)}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAutoSavedFeedback(List<ExtractedItem> items) {
    final autoSavedTasks = [
      for (final item in items)
        if (item.status == RecordStatus.confirmed &&
            item.type == ItemType.taskCreate)
          item.title ?? item.content ?? item.sourceText,
    ];
    if (autoSavedTasks.isEmpty || !mounted) {
      return;
    }

    final label = autoSavedTasks.take(2).join('、');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已纳入行动：$label')));
  }

  String _safeParserFailureDetail(ParserFailure error) {
    return switch (error.code) {
      'network_error' => '暂时无法连接解析服务，请检查网络或后端地址。',
      'network_timeout' => '解析服务响应超时，请稍后再试。',
      'parser_service_error' => '解析服务暂时不可用，请稍后再试。',
      'invalid_response' => '解析结果格式异常，请稍后再试。',
      _ => '整理失败，请稍后再试。',
    };
  }

  Future<void> _confirm(ExtractedItem item) async {
    if (item.type == ItemType.taskUpdate) {
      await _confirmTaskUpdate(item);
      return;
    }

    if (item.status == RecordStatus.confirmed) {
      return;
    }

    await widget.controller.confirmExtractedItem(extractedItemId: item.localId);
    await _refreshPendingBatches();
    widget.onRecordsChanged?.call();
  }

  Future<void> _confirmTaskUpdate(ExtractedItem item) async {
    final firstResult = await widget.controller.applyTaskUpdate(item: item);

    if (!mounted) {
      return;
    }

    if (firstResult.state == TaskUpdateExecutionState.applied) {
      await _refreshPendingBatches();
      widget.onRecordsChanged?.call();
      return;
    }

    if (firstResult.state == TaskUpdateExecutionState.noMatch) {
      return;
    }

    final selectedTask = await showModalBottomSheet<TaskUpdateCandidate>(
      context: context,
      builder: (context) =>
          _TaskUpdateSelectionSheet(candidates: firstResult.candidates),
    );

    if (selectedTask == null) {
      return;
    }

    final finalResult = await widget.controller.applyTaskUpdate(
      item: item,
      selectedTaskId: selectedTask.id,
    );

    if (!mounted) {
      return;
    }

    if (finalResult.state == TaskUpdateExecutionState.applied) {
      await _refreshPendingBatches();
      widget.onRecordsChanged?.call();
    }
  }

  Future<void> _edit(ExtractedItem item) async {
    final editedItem = await showModalBottomSheet<EditedExtractedItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditExtractedItemSheet(
        item: item,
        now: widget.controller.nowProvider(),
      ),
    );

    if (editedItem == null) {
      return;
    }

    if (item.status == RecordStatus.confirmed) {
      await widget.controller.editAutoSavedExtractedItem(
        extractedItemId: item.localId,
        editedTitle: editedItem.title,
        editedContent: editedItem.content,
        hasEditedDueTime: editedItem.hasDueTimeEdit,
        editedDueTimeText: editedItem.dueTimeText,
        editedDueTime: editedItem.dueTime,
      );
    } else {
      await widget.controller.confirmExtractedItem(
        extractedItemId: item.localId,
        editedTitle: editedItem.title,
        editedContent: editedItem.content,
        hasEditedDueTime: editedItem.hasDueTimeEdit,
        editedDueTimeText: editedItem.dueTimeText,
        editedDueTime: editedItem.dueTime,
      );
    }
    await _refreshPendingBatches();
    widget.onRecordsChanged?.call();
  }

  Future<void> _reject(ExtractedItem item) async {
    if (item.status == RecordStatus.confirmed) {
      await widget.controller.undoAutoSavedExtractedItem(
        extractedItemId: item.localId,
      );
      _removeCurrentAutoSavedItem(item);
    } else {
      await widget.controller.rejectExtractedItem(
        extractedItemId: item.localId,
      );
    }
    await _refreshPendingBatches();
    widget.onRecordsChanged?.call();
  }

  Future<void> _refreshPendingBatches() async {
    final batches = await widget.controller.getRecentPendingBatches();
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingBatches = batches;
    });
  }

  void _removeCurrentAutoSavedItem(ExtractedItem item) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentAutoSavedItems = [
        for (final currentItem in _currentAutoSavedItems)
          if (currentItem.localId != item.localId) currentItem,
      ];
    });
  }
}
