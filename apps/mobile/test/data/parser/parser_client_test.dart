import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/parser/http_parser_client.dart';
import 'package:mobile/data/parser/mock_parser_client.dart';
import 'package:mobile/data/parser/parser_client.dart';
import 'package:mobile/domain/item_type.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('MockParserClient', () {
    test('returns stable contract objects for the MVP sample input', () async {
      final client = MockParserClient(
        parsedAtProvider: () => DateTime.utc(2026, 5, 31),
      );

      final result = await client.parseInput('明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。');

      expect(result.intentTypes, [
        ItemType.taskCreate,
        ItemType.shortTermState,
        ItemType.profileCandidate,
      ]);
      expect(result.items, hasLength(3));
      expect(result.items[0].type, ItemType.taskCreate);
      expect(result.items[1].type, ItemType.shortTermState);
      expect(result.items[1].hasExpiry, isTrue);
      expect(result.items[2].type, ItemType.profileCandidate);
      expect(result.items[2].needUserConfirm, isTrue);
      expect(result.items[0].localId, 'parsed:0');
    });
  });

  group('HttpParserClient', () {
    test('is the default parser client used by the app', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(parserClientProvider), isA<HttpParserClient>());
    });

    test(
      'default parser base uri accepts API_BASE_URL alias for smoke runs',
      () {
        expect(
          defaultParserBaseUri(
            parserBaseUrl: '',
            apiBaseUrl: 'http://127.0.0.1:8787',
            isAndroid: false,
          ),
          Uri.parse('http://127.0.0.1:8787'),
        );
      },
    );

    test(
      'calls the API proxy parse route and maps JSON into ParseResult',
      () async {
        Uri? requestedUri;
        Map<String, Object?>? requestBody;
        final client = HttpParserClient(
          baseUri: Uri.parse('http://localhost:8787'),
          timezone: 'Asia/Shanghai',
          parsedAtProvider: () => DateTime.utc(2026, 5, 31, 10, 15),
          postJson: (uri, headers, body) async {
            requestedUri = uri;
            requestBody = jsonDecode(body) as Map<String, Object?>;
            expect(headers['Content-Type'], 'application/json');
            return ParserHttpResponse(
              statusCode: 200,
              body: jsonEncode({
                'user_reply': '我帮你整理出了一个任务。',
                'input_summary': '明天联系王总。',
                'intent_types': ['task_create'],
                'items': [
                  {
                    'type': 'task_create',
                    'title': '联系王总',
                    'source_text': '明天联系王总',
                    'tags': ['work'],
                    'confidence': 0.9,
                    'need_user_confirm': true,
                  },
                ],
              }),
            );
          },
        );

        final result = await client.parseInput('明天联系王总');

        expect(requestedUri, Uri.parse('http://localhost:8787/parse'));
        expect(requestBody, {
          'text': '明天联系王总',
          'timezone': 'Asia/Shanghai',
          'current_time_iso': '2026-05-31T10:15:00.000Z',
          'input_style': 'natural_language',
        });
        expect(result.items.single.type, ItemType.taskCreate);
        expect(result.items.single.localId, 'parsed:0');
      },
    );

    test('includes optional location context only when provided', () async {
      Map<String, Object?>? requestBody;
      final client = HttpParserClient(
        baseUri: Uri.parse('http://localhost:8787'),
        timezone: 'Asia/Shanghai',
        parsedAtProvider: () => DateTime.utc(2026, 6, 8, 9),
        locationContextProvider: () => const ParserLocationContext(
          label: '上海市徐汇区',
          latitude: 31.188,
          longitude: 121.436,
          accuracyMeters: 50,
        ),
        postJson: (uri, headers, body) async {
          requestBody = jsonDecode(body) as Map<String, Object?>;
          return ParserHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'user_reply': '我帮你整理出了一个任务。',
              'input_summary': '附近买咖啡。',
              'intent_types': ['task_create'],
              'items': [
                {
                  'type': 'task_create',
                  'title': '买咖啡',
                  'source_text': '附近买咖啡',
                  'tags': ['life'],
                  'confidence': 0.8,
                  'need_user_confirm': true,
                },
              ],
            }),
          );
        },
      );

      await client.parseInput('附近买咖啡');

      expect(requestBody?['location_context'], {
        'label': '上海市徐汇区',
        'latitude': 31.188,
        'longitude': 121.436,
        'accuracy_meters': 50.0,
      });
    });

    test(
      'returns a user-friendly failure when the network request fails',
      () async {
        final client = HttpParserClient(
          baseUri: Uri.parse('http://localhost:8787'),
          postJson: (uri, headers, body) async {
            throw Exception('socket failed with raw host details');
          },
        );

        await expectLater(
          client.parseInput('明天联系王总'),
          throwsA(
            isA<ParserFailure>()
                .having((error) => error.code, 'code', 'network_error')
                .having(
                  (error) => error.userMessage,
                  'userMessage',
                  '暂时无法连接解析服务，请稍后再试。',
                )
                .having(
                  (error) => error.toString(),
                  'toString',
                  isNot(contains('socket failed')),
                ),
          ),
        );
      },
    );
  });
}
