import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';

class LifeEventsScreen extends StatelessWidget {
  const LifeEventsScreen({required this.database, super.key});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生活事件')),
      body: FutureBuilder<List<LifeEvent>>(
        future: database.getActiveLifeEvents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final event in events)
                Card(child: ListTile(title: Text(event.content))),
            ],
          );
        },
      ),
    );
  }
}
