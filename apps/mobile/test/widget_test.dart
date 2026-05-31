import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/app_shell.dart';

void main() {
  testWidgets('App shell shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AppShell()));

    expect(find.text('Personal Memory'), findsOneWidget);
    expect(find.text('AI 个人记忆与行动整理系统'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
