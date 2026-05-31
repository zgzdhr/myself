import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';

class ShortTermStatesScreen extends StatelessWidget {
  const ShortTermStatesScreen({
    required this.database,
    this.nowProvider = DateTime.now,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('短期状态')),
      body: FutureBuilder<List<ShortTermState>>(
        future: database.getActiveShortTermStates(now: nowProvider()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final states = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final state in states)
                Card(child: ListTile(title: Text(state.content))),
            ],
          );
        },
      ),
    );
  }
}
