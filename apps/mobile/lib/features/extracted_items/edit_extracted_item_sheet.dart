import 'package:flutter/material.dart';

import '../../domain/extracted_item.dart';
import '../../domain/item_type.dart';
import '../memory/task_time_formatter.dart';

class EditedExtractedItem {
  const EditedExtractedItem({
    required this.title,
    required this.content,
    this.hasDueTimeEdit = false,
    this.dueTimeText,
    this.dueTime,
  });

  final String? title;
  final String? content;
  final bool hasDueTimeEdit;
  final String? dueTimeText;
  final DateTime? dueTime;
}

class EditExtractedItemSheet extends StatefulWidget {
  const EditExtractedItemSheet({
    required this.item,
    required this.now,
    super.key,
  });

  final ExtractedItem item;
  final DateTime now;

  @override
  State<EditExtractedItemSheet> createState() => _EditExtractedItemSheetState();
}

class _EditExtractedItemSheetState extends State<EditExtractedItemSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  DateTime? _selectedDueTime;
  String? _dueTimeText;
  var _hasDueTimeEdit = false;

  bool get _canEditDueTime => widget.item.type == ItemType.taskCreate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _contentController = TextEditingController(text: widget.item.content);
  }

  Future<void> _pickDate() async {
    final current = _selectedDueTime ?? widget.now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(widget.now.year - 1),
      lastDate: DateTime(widget.now.year + 5),
    );
    if (pickedDate == null) return;

    final time = TimeOfDay.fromDateTime(_selectedDueTime ?? widget.now);
    setState(() {
      _hasDueTimeEdit = true;
      _selectedDueTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
      _dueTimeText ??= '手动选择';
    });
  }

  Future<void> _pickTime() async {
    final current = _selectedDueTime ?? widget.now;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) return;

    setState(() {
      _hasDueTimeEdit = true;
      _selectedDueTime = DateTime(
        current.year,
        current.month,
        current.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _dueTimeText ??= '手动选择';
    });
  }

  void _clearDueTime() {
    setState(() {
      _hasDueTimeEdit = true;
      _selectedDueTime = null;
      _dueTimeText = null;
    });
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
            if (_canEditDueTime) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '任务时间',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formatTaskDueText(
                    dueTime: _selectedDueTime,
                    dueTimeText: _dueTimeText,
                    now: widget.now,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('选择日期'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: const Text('选择时间'),
                  ),
                  TextButton.icon(
                    onPressed: _clearDueTime,
                    icon: const Icon(Icons.clear),
                    label: const Text('清除时间'),
                  ),
                ],
              ),
            ],
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
        hasDueTimeEdit: _canEditDueTime && _hasDueTimeEdit,
        dueTimeText: _canEditDueTime && _hasDueTimeEdit ? _dueTimeText : null,
        dueTime: _canEditDueTime && _hasDueTimeEdit ? _selectedDueTime : null,
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
