import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan/http_plan_client.dart';
import '../data/review/http_review_client.dart';
import '../features/account/cloud_backend.dart';
import '../features/memory/tasks_screen.dart';
import '../features/home/home_screen.dart';
import '../features/review/review_screen.dart';
import '../features/security/app_lock.dart';
import '../features/settings/profile_settings_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Memory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF53736A),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFCF7),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'SF Pro Display',
          bodyColor: const Color(0xFF262626),
          displayColor: const Color(0xFF1D1D1F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F4EE),
          foregroundColor: Color(0xFF1D1D1F),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFCF7),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE7E0D6)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
      home: const AppLockGate(child: _MainNavigationScreen()),
    );
  }
}

class _MainNavigationScreen extends ConsumerStatefulWidget {
  const _MainNavigationScreen();

  @override
  ConsumerState<_MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<_MainNavigationScreen> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    final nowProvider = ref.watch(appNowProvider);
    final taskReminderScheduler = ref.watch(taskReminderSchedulerProvider);
    final cloudAuthService = ref.watch(cloudAuthServiceProvider);
    final cloudSyncService = ref.watch(cloudSyncServiceProvider);
    final apiAccessToken = ref.watch(apiAccessTokenProvider);
    final dataRefreshVersion = ref.watch(appDataRefreshProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          TasksScreen(
            database: database,
            nowProvider: nowProvider,
            taskReminderScheduler: taskReminderScheduler,
            refreshVersion: dataRefreshVersion,
            onRecordsChanged: () {
              ref.read(appDataRefreshProvider.notifier).bump();
            },
          ),
          ReviewScreen(
            database: database,
            nowProvider: nowProvider,
            reviewClient: HttpReviewClient(
              baseUri: defaultParserBaseUri(),
              accessTokenProvider: apiAccessToken,
              requireAuthentication: true,
            ),
            planClient: HttpPlanClient(
              baseUri: defaultParserBaseUri(),
              accessTokenProvider: apiAccessToken,
              requireAuthentication: true,
            ),
          ),
          ProfileSettingsScreen(
            database: database,
            nowProvider: nowProvider,
            parserBaseUri: defaultParserBaseUri(),
            cloudAuthService: cloudAuthService,
            cloudSyncService: cloudSyncService,
            taskReminderScheduler: taskReminderScheduler,
            refreshVersion: dataRefreshVersion,
            onOpenHome: () => _selectDestination(0),
            onOpenTasks: () => _selectDestination(1),
            onOpenReview: () => _selectDestination(2),
            onRecordsChanged: () {
              ref.read(appDataRefreshProvider.notifier).bump();
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_rounded),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: '复盘',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
