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
import 'app_visuals.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Memory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'SF Pro Display',
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primarySoft,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
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
      backgroundColor: AppColors.background,
      extendBody: false,
      body: AppBackdrop(
        child: IndexedStack(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4694FF), Color(0xFF1768ED)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x552F7DF6),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          tooltip: '快速记录',
          onPressed: () => _selectDestination(0),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: _AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectDestination,
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _AppBottomNavigation extends StatelessWidget {
  const _AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 66,
      padding: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 12,
      shadowColor: const Color(0x223B82F6),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: '首页',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.checklist_rounded,
              selectedIcon: Icons.task_alt_rounded,
              label: '任务',
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            child: _NavItem(
              icon: Icons.pie_chart_outline_rounded,
              selectedIcon: Icons.pie_chart_rounded,
              label: '复盘',
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: '我的',
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return InkResponse(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
