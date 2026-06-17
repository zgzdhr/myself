import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/extracted_items/task_due_inference.dart';

void main() {
  final now = DateTime(2026, 6, 17, 10);

  test('infers concrete relative dates that are safe for local reminders', () {
    final afterTomorrow = inferTaskDue(text: '后天联系王总', now: now);

    expect(afterTomorrow.dueTimeText, '后天');
    expect(afterTomorrow.dueTime, DateTime(2026, 6, 19, 9));

    final threeDaysLater = inferTaskDue(text: '大后天上午联系王总', now: now);

    expect(threeDaysLater.dueTimeText, '大后天');
    expect(threeDaysLater.dueTime, DateTime(2026, 6, 20, 9));
  });

  test('infers explicit next weekday with day-period clock time', () {
    final result = inferTaskDue(text: '下周一下午三点整理客户资料', now: now);

    expect(result.dueTimeText, '三点');
    expect(result.dueTime, DateTime(2026, 6, 22, 15));
  });

  test('does not invent morning or evening for ambiguous bare clock time', () {
    final result = inferTaskDue(text: '明天七点联系王总', now: now);

    expect(result.dueTimeText, '七点');
    expect(result.dueTime, isNull);
  });

  test('keeps vague future phrases unscheduled', () {
    for (final phrase in ['过会儿', '一会儿', '待会儿', '回头', '有空']) {
      final result = inferTaskDue(text: '$phrase提醒我发资料', now: now);

      expect(result.dueTimeText, isNull, reason: phrase);
      expect(result.dueTime, isNull, reason: phrase);
    }
  });

  test('continues to use same-day implicit time segments', () {
    final result = inferTaskDue(text: '今晚八点出去散步', now: now);

    expect(result.dueTimeText, '八点');
    expect(result.dueTime, DateTime(2026, 6, 17, 20));
  });
}
