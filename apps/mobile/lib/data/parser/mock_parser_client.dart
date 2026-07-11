import '../../domain/parse_result.dart';
import 'parser_client.dart';

class MockParserClient implements ParserClient {
  const MockParserClient({
    this.parsedAtProvider = DateTime.now,
  });

  final DateTime Function() parsedAtProvider;

  @override
  Future<ParseResult> parseInput(String text) async {
    final parsedAt = parsedAtProvider();

    return ParseResult.fromAiJson(
      parsedAt: parsedAt,
      json: {
        'user_reply': '我帮你整理出了 1 个任务、1 条短期状态和 1 条长期画像候选。',
        'input_summary': '用户提到明天联系王总、今天很累、不喜欢频繁提醒。',
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
            'need_user_confirm': false,
            'due_time_text': '明天上午',
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
            'need_user_confirm': true,
          },
        ],
      },
    );
  }
}
