import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_db/app_database.dart';
import '../../data/parser/http_parser_client.dart';
import '../../data/parser/mock_parser_client.dart';
import '../../data/parser/parser_client.dart';
import '../extracted_items/extracted_items_controller.dart';
import 'home_suggestion_service.dart';
import '../input/input_screen.dart';
import '../memory/memory_screen.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final parserClientProvider = Provider<ParserClient>((ref) {
  const parserMode = String.fromEnvironment(
    'PARSER_MODE',
    defaultValue: 'http',
  );

  if (parserMode == 'mock') {
    return const MockParserClient();
  }

  return HttpParserClient(baseUri: defaultParserBaseUri());
});

class DebugNowOverride extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setPreviousDay(DateTime current) {
    state = DateTime(
      current.year,
      current.month,
      current.day - 1,
      current.hour,
      current.minute,
    );
  }

  void setNextDay(DateTime current) {
    state = DateTime(
      current.year,
      current.month,
      current.day + 1,
      current.hour,
      current.minute,
    );
  }

  void clear() {
    state = null;
  }
}

final debugNowOverrideProvider = NotifierProvider<DebugNowOverride, DateTime?>(
  DebugNowOverride.new,
);

final appNowProvider = Provider<DateTime Function()>((ref) {
  final debugNow = ref.watch(debugNowOverrideProvider);
  return () => debugNow ?? DateTime.now();
});

Uri defaultParserBaseUri({
  String parserBaseUrl = const String.fromEnvironment('PARSER_BASE_URL'),
  String apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
  bool? isAndroid,
}) {
  final configuredBaseUrl = parserBaseUrl.isNotEmpty
      ? parserBaseUrl
      : apiBaseUrl;

  if (configuredBaseUrl.isNotEmpty) {
    return Uri.parse(configuredBaseUrl);
  }

  if (isAndroid ?? Platform.isAndroid) {
    return Uri.parse('http://10.0.2.2:8787');
  }

  return Uri.parse('http://127.0.0.1:8787');
}

final extractedItemsControllerProvider = Provider<ExtractedItemsController>((
  ref,
) {
  return ExtractedItemsController(
    database: ref.watch(appDatabaseProvider),
    parserClient: ref.watch(parserClientProvider),
    nowProvider: ref.watch(appNowProvider),
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
    final nowProvider = ref.watch(appNowProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      body: InputScreen(
        controller: ref.watch(extractedItemsControllerProvider),
        header: const _HomeHeader(),
        onRefresh: () async {
          setState(() {
            _refreshVersion += 1;
          });
        },
        afterInput: FutureBuilder<HomeSuggestionContext>(
          key: ValueKey(_refreshVersion),
          future: suggestionService.loadContext(
            database: database,
            now: nowProvider(),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const _HomeLoadingCard();
            }

            final contextData = snapshot.data!;
            final suggestions = suggestionService.buildSuggestions(contextData);

            return _HomeFollowUp(
              suggestions: suggestions,
              contextData: contextData,
              database: database,
              nowProvider: nowProvider,
            );
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_HomeGreeting(), _DebugDateSwitcher()],
    );
  }
}

class _HomeLoadingCard extends StatelessWidget {
  const _HomeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _SurfacePanel(
      child: Text(
        '正在整理今天的线索...',
        style: TextStyle(
          color: Color(0xFF746E66),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          '早上好',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '把今天的想法放在这里，我会帮你整理成行动和记忆。',
          style: TextStyle(
            color: Color(0xFF746E66),
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DebugDateSwitcher extends ConsumerWidget {
  const _DebugDateSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final debugNow = ref.watch(debugNowOverrideProvider);
    final activeDate = debugNow ?? DateTime.now();
    final local = activeDate.toLocal();
    final label =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: _SurfacePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '测试日期',
              style: TextStyle(
                color: Color(0xFF1D1D1F),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: '前一天',
                  onPressed: () {
                    ref
                        .read(debugNowOverrideProvider.notifier)
                        .setPreviousDay(local);
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF3A3835),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '后一天',
                  onPressed: () {
                    ref
                        .read(debugNowOverrideProvider.notifier)
                        .setNextDay(local);
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(debugNowOverrideProvider.notifier).clear();
                  },
                  child: const Text('真实日期'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFollowUp extends StatelessWidget {
  const _HomeFollowUp({
    required this.suggestions,
    required this.contextData,
    required this.database,
    required this.nowProvider,
  });

  final List<HomeSuggestion> suggestions;
  final HomeSuggestionContext contextData;
  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  Widget build(BuildContext context) {
    final primarySuggestion = suggestions.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionEyebrow(
                icon: Icons.auto_awesome_rounded,
                label: 'AI 建议',
              ),
              const SizedBox(height: 12),
              Text(
                primarySuggestion.text,
                style: const TextStyle(
                  color: Color(0xFF1D1D1F),
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                primarySuggestion.reason,
                style: const TextStyle(
                  color: Color(0xFF746E66),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _HomeListSection(
          title: '今日行动',
          emptyText: '暂无今日任务',
          items: [for (final task in contextData.tasks) task.title],
        ),
        const SizedBox(height: 18),
        _MemoryEntryPanel(
          stateCount: contextData.shortTermStates.length,
          profileCount: contextData.profileItems.length,
          database: database,
          nowProvider: nowProvider,
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
    return _SurfacePanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1D1D1F),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                color: Color(0xFF8A8278),
                fontSize: 14,
                height: 1.35,
              ),
            )
          else
            for (final item in items.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: Color(0xFF53736A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF3A3835),
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
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

class _MemoryEntryPanel extends StatelessWidget {
  const _MemoryEntryPanel({
    required this.stateCount,
    required this.profileCount,
    required this.database,
    required this.nowProvider,
  });

  final int stateCount;
  final int profileCount;
  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) =>
                  MemoryScreen(database: database, nowProvider: nowProvider),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
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
                Icons.bookmark_border_rounded,
                color: Color(0xFF53736A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '记忆入口',
                    style: TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '状态 $stateCount 条 · 长期画像 $profileCount 条',
                    style: const TextStyle(
                      color: Color(0xFF8A8278),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8278)),
          ],
        ),
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E0D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 12),
            blurRadius: 24,
          ),
          BoxShadow(
            color: Color(0x66FFFFFF),
            offset: Offset(0, -1),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF53736A)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF53736A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
