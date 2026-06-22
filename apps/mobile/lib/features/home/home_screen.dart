import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_db/app_database.dart';
import '../../data/parser/http_parser_client.dart';
import '../../data/parser/mock_parser_client.dart';
import '../../data/parser/parser_client.dart';
import '../extracted_items/extracted_items_controller.dart';
import '../reminders/task_reminder_scheduler.dart';
import '../settings/user_preference_providers.dart';
import 'home_suggestion_service.dart';
import '../input/input_screen.dart';
import '../memory/memory_screen.dart';

part 'home_screen_widgets.dart';

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
    taskReminderScheduler: ref.watch(taskReminderSchedulerProvider),
    nowProvider: ref.watch(appNowProvider),
  );
});

final taskReminderSchedulerProvider = Provider<TaskReminderScheduler>((ref) {
  return SystemTaskReminderScheduler.instance;
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
    final reviewAffectsHome = ref.watch(reviewAffectsHomeProvider);

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
            includeReviewSummaries: reviewAffectsHome,
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
