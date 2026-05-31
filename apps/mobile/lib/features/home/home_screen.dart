import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_db/app_database.dart';
import '../../data/parser/mock_parser_client.dart';
import '../../data/parser/parser_client.dart';
import '../extracted_items/extracted_items_controller.dart';
import 'home_suggestion_service.dart';
import '../input/input_screen.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final parserClientProvider = Provider<ParserClient>((ref) {
  return const MockParserClient();
});

final extractedItemsControllerProvider = Provider<ExtractedItemsController>((
  ref,
) {
  return ExtractedItemsController(
    database: ref.watch(appDatabaseProvider),
    parserClient: ref.watch(parserClientProvider),
  );
});

final homeSuggestionServiceProvider = Provider<HomeSuggestionService>((ref) {
  return const HomeSuggestionService();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _refreshVersion = 0;

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    final suggestionService = ref.watch(homeSuggestionServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Memory')),
      body: InputScreen(
        controller: ref.watch(extractedItemsControllerProvider),
        header: FutureBuilder<HomeSuggestionContext>(
          key: ValueKey(_refreshVersion),
          future: suggestionService.loadContext(
            database: database,
            now: DateTime.now(),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const _HomeLoadingCard();
            }

            final contextData = snapshot.data!;
            final suggestions = suggestionService.buildSuggestions(contextData);

            return _HomeSummary(suggestions: suggestions, context: contextData);
          },
        ),
        onRecordsChanged: () {
          setState(() {
            _refreshVersion += 1;
          });
        },
      ),
    );
  }
}

class _HomeLoadingCard extends StatelessWidget {
  const _HomeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(padding: EdgeInsets.all(16), child: Text('正在整理首页建议…')),
    );
  }
}

class _HomeSummary extends StatelessWidget {
  const _HomeSummary({required this.suggestions, required this.context});

  final List<HomeSuggestion> suggestions;
  final HomeSuggestionContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日建议',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final suggestion in suggestions)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.text,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(suggestion.reason),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        _HomeListSection(
          title: '今日任务',
          emptyText: '暂无今日任务',
          items: [for (final task in this.context.tasks) task.title],
        ),
        const SizedBox(height: 12),
        _HomeListSection(
          title: '当前状态',
          emptyText: '暂无有效短期状态',
          items: [
            for (final state in this.context.shortTermStates) state.content,
          ],
        ),
      ],
    );
  }
}

class _HomeListSection extends StatelessWidget {
  const _HomeListSection({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Text(emptyText)
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $item'),
            ),
      ],
    );
  }
}
