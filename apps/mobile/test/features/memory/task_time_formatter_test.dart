import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/memory/task_time_formatter.dart';

void main() {
  test('formats concrete due time with original time text', () {
    expect(
      formatTaskDueText(dueTime: DateTime(2026, 6, 8, 19), dueTimeText: '今晚'),
      '6月8日 19:00｜原文：今晚',
    );
  });

  test('shows uncertain original time when concrete due time is missing', () {
    expect(formatTaskDueText(dueTimeText: '回头'), '时间待明确｜原文：回头');
  });

  test('shows unscheduled when no time information exists', () {
    expect(formatTaskDueText(), '未设时间');
  });
}
