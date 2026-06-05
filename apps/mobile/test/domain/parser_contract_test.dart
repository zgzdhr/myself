import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/domain/parse_result.dart';

void main() {
  test('keeps the MVP item type list intentionally small', () {
    expect(ItemType.values, [
      ItemType.taskCreate,
      ItemType.taskUpdate,
      ItemType.shortTermState,
      ItemType.lifeEvent,
      ItemType.generalAnswer,
      ItemType.profileCandidate,
    ]);
  });

  test('maps task, short-term state, and profile candidate from AI JSON', () {
    const rawInput = '明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。';
    final parsedAt = DateTime.utc(2026, 5, 31, 12);

    final result = ParseResult.fromAiJson(
      parsedAt: parsedAt,
      json: {
        'user_reply': '我帮你整理出了 1 个任务、1 条短期状态和 1 条长期画像候选。',
        'input_summary': rawInput,
        'intent_types': [
          'task_create',
          'short_term_state',
          'profile_candidate',
        ],
        'items': [
          {
            'type': 'task_create',
            'title': '联系王总',
            'source_text': '明天上午联系王总',
            'tags': ['work', 'customer'],
            'confidence': 0.9,
            'need_user_confirm': true,
          },
          {
            'type': 'short_term_state',
            'content': '用户今天感觉疲惫',
            'source_text': '我今天很累',
            'tags': ['energy'],
            'confidence': 0.8,
            'need_user_confirm': false,
            'valid_days': 1,
          },
          {
            'type': 'profile_candidate',
            'content': '用户不喜欢太频繁的提醒',
            'source_text': '我不喜欢太频繁的提醒',
            'tags': ['preference', 'reminder'],
            'confidence': 0.86,
            'need_user_confirm': false,
          },
        ],
      },
    );

    expect(result.inputSummary, rawInput);
    expect(result.intentTypes, [
      ItemType.taskCreate,
      ItemType.shortTermState,
      ItemType.profileCandidate,
    ]);
    expect(result.items.map((item) => item.type), [
      ItemType.taskCreate,
      ItemType.shortTermState,
      ItemType.profileCandidate,
    ]);

    final taskItem = result.items[0];
    expect(taskItem.localId, 'parsed:0');
    expect(taskItem.title, '联系王总');
    expect(taskItem.sourceText, '明天上午联系王总');

    final stateItem = result.items[1];
    expect(stateItem.hasExpiry, true);
    expect(stateItem.expiresAt, parsedAt.add(const Duration(days: 1)));

    final profileItem = result.items[2];
    expect(profileItem.needUserConfirm, true);
    expect(profileItem.content, '用户不喜欢太频繁的提醒');
  });
}
