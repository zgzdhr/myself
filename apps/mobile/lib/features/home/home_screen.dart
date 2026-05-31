import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_db/app_database.dart';
import '../../data/parser/mock_parser_client.dart';
import '../../data/parser/parser_client.dart';
import '../extracted_items/extracted_items_controller.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Memory')),
      body: InputScreen(
        controller: ref.watch(extractedItemsControllerProvider),
      ),
    );
  }
}
