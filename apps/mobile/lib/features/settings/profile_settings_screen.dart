import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_visuals.dart';
import '../../data/api/api_error_code.dart';
import '../../data/local_db/app_database.dart';
import '../../domain/item_type.dart';
import '../account/cloud_auth_service.dart';
import '../account/cloud_restore_service.dart';
import '../account/cloud_sync_service.dart';
import '../memory/delete_confirmation.dart';
import '../memory/memory_screen.dart';
import '../memory/privacy_screen.dart';
import '../reminders/task_reminder_scheduler.dart';
import 'user_preference_providers.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({
    required this.database,
    required this.nowProvider,
    required this.parserBaseUri,
    required this.cloudAuthService,
    required this.cloudSyncService,
    required this.taskReminderScheduler,
    required this.onOpenHome,
    required this.onOpenTasks,
    required this.onOpenReview,
    required this.onRecordsChanged,
    this.refreshVersion = 0,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;
  final Uri parserBaseUri;
  final CloudAuthService cloudAuthService;
  final CloudSyncService cloudSyncService;
  final TaskReminderScheduler taskReminderScheduler;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenReview;
  final VoidCallback onRecordsChanged;
  final int refreshVersion;

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  static const _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  late Future<_ProfileOverviewData> _dataFuture;
  var _taskReminderEnabled = false;
  bool? _apiAvailable;
  var _isCheckingApi = false;
  String? _cloudProfileSyncError;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
    _loadTaskReminderPermission();
  }

  @override
  void didUpdateWidget(covariant ProfileSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion ||
        oldWidget.database != widget.database) {
      _dataFuture = _load();
    }
  }

  Future<_ProfileOverviewData> _load() async {
    final now = widget.nowProvider();
    final tasks = await widget.database.getActiveTasks();
    final states = await widget.database.getActiveShortTermStates(now: now);
    final events = await widget.database.getActiveLifeEvents();
    final profiles = await widget.database.getActiveProfileItems();
    final todaySummary = await widget.database.getSummaryForDay(now);
    final pendingTasks = await widget.database.countPendingExtractedItemsByType(
      ItemType.taskCreate.apiValue,
    );
    final pendingProfiles = await widget.database
        .countPendingExtractedItemsByType(ItemType.profileCandidate.apiValue);

    return _ProfileOverviewData(
      taskCount: tasks.length,
      activeStateCount: states.length,
      lifeEventCount: events.length,
      profileCount: profiles.length,
      pendingCount: pendingTasks + pendingProfiles,
      hasTodaySummary: todaySummary != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewAffectsHome = ref.watch(reviewAffectsHomeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<CloudAuthState>(
        stream: widget.cloudAuthService.watchAuthState(),
        initialData: widget.cloudAuthService.currentState,
        builder: (context, authSnapshot) {
          final authState =
              authSnapshot.data ?? widget.cloudAuthService.currentState;

          return FutureBuilder<_ProfileOverviewData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  SafeArea(
                    bottom: false,
                    child: _ProfileHeader(
                      authState: authState,
                      onLogin: _openEmailOtpSignIn,
                      onSettings: () => _showAccountActions(authState),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _TodayOverviewCard(data: data),
                  const SizedBox(height: 10),
                  _QuickActions(
                    onNotifications: _requestNotificationPermission,
                    onSync: () => _syncCloudProfileNow(authState),
                    onPrivacy: () => _openPrivacy(),
                    onMemory: _openMemory,
                  ),
                  const SizedBox(height: 12),
                  _SettingsSection(
                    title: '账号与同步',
                    children: [
                      _SettingsTile(
                        icon: Icons.sync_rounded,
                        title: '立即同步到云端',
                        subtitle: _syncSubtitle(authState),
                        trailingText: authState.syncLabel,
                        onTap: () => _syncCloudProfileNow(authState),
                      ),
                      if (authState.isSignedIn)
                        _SettingsTile(
                          icon: Icons.cloud_download_outlined,
                          title: '从云端恢复到本机',
                          subtitle: '先预览数量，再按 ID 合并；本机较新的记录和本地日历不会被覆盖。',
                          onTap: () => _previewAndRestoreCloudCopy(),
                        ),
                      _SettingsTile(
                        icon: Icons.phone_android_rounded,
                        title: '当前设备',
                        subtitle: _taskReminderEnabled
                            ? '本机通知权限已开启，本地数据可离线使用。'
                            : '本机通知权限未开启或无法读取。',
                        trailingText: defaultTargetPlatform.name,
                        onTap: () => _openDetail(
                          title: '当前设备',
                          description:
                              '当前设备使用本地 SQLite 保存运行数据，并由系统通知负责有具体时间的任务提醒。Android 已关闭系统备份；数据库暂未加密，请继续使用设备锁屏保护。云端同步目前是手动单向同步：本机 → Supabase。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.storage_rounded,
                        title: '数据存储位置说明',
                        subtitle: '说明哪些数据在本地，哪些会进入云端，哪些会发给 AI。',
                        onTap: () => _openDetail(
                          title: '数据存储位置说明',
                          description:
                              '任务、状态、事件、画像和复盘先保存在本地 SQLite。登录后点击“立即同步到云端”，这些记录会按账号 user_id 单向写入 Supabase。日历排期、每日重复和久坐会话明确只保存在本机；当前不会从云端自动合并回本机。',
                        ),
                      ),
                      if (authState.isSignedIn)
                        _SettingsTile(
                          icon: Icons.delete_forever_outlined,
                          title: '删除云端副本',
                          subtitle: '只删除此账号在 Supabase 的副本，本机数据不会改变。',
                          onTap: () => _confirmAndDeleteCloudCopy(),
                        ),
                      if (authState.isSignedIn)
                        _SettingsTile(
                          icon: Icons.person_remove_outlined,
                          title: '永久注销云端账号',
                          subtitle: '删除 Supabase 登录账号及其全部云端数据；本机数据保留。',
                          onTap: () => _confirmAndDeleteAccount(),
                        ),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: '退出登录',
                        subtitle: authState.isSignedIn
                            ? '退出账号不会删除本地缓存或云端数据。'
                            : '当前没有已登录账号。',
                        trailingText: authState.isSignedIn ? null : '未登录',
                        onTap: authState.isSignedIn ? () => _signOut() : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsSection(
                    title: '提醒与任务',
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_active_rounded,
                        title: '通知权限',
                        subtitle: _taskReminderEnabled
                            ? '已允许通知；带未来具体时间的任务会按时提醒。'
                            : '点击申请系统通知权限。',
                        trailingText: _taskReminderEnabled ? '已开启' : '未开启',
                        onTap: _requestNotificationPermission,
                      ),
                      _SettingsTile(
                        icon: Icons.task_alt_rounded,
                        title: '查看和管理任务',
                        subtitle: '编辑时间、完成、取消或删除任务。',
                        onTap: widget.onOpenTasks,
                      ),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: '当前提醒规则',
                        subtitle: '只提醒已确认、未完成、未取消且带未来时间的任务。',
                        onTap: () => _openDetail(
                          title: '当前提醒规则',
                          description:
                              '任务提醒由手机本地系统安排。创建或编辑带具体未来时间的任务时会安排提醒；完成、取消、删除任务或清除任务时间时，会取消对应提醒。当前没有提前 5/10/30 分钟和每日复盘提醒，所以页面不再展示无效开关。',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsSection(
                    title: '复盘设置',
                    children: [
                      _SettingsTile(
                        icon: Icons.today_rounded,
                        title: '打开每日复盘',
                        subtitle: '生成、编辑、重新生成或删除当天复盘。',
                        trailingText: data?.hasTodaySummary == true
                            ? '今日已生成'
                            : '今日未生成',
                        onTap: widget.onOpenReview,
                      ),
                      _SettingsTile(
                        icon: Icons.history_rounded,
                        title: '历史复盘与时间规划',
                        subtitle: '按月份、周和日期查看复盘，也可切换到时间规划。',
                        onTap: widget.onOpenReview,
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        secondary: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: AppColors.purple,
                        ),
                        title: const Text(
                          '复盘结果参与首页建议',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        value: reviewAffectsHome,
                        onChanged: (value) {
                          ref
                              .read(reviewAffectsHomeProvider.notifier)
                              .setEnabled(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsSection(
                    title: 'AI 与记忆',
                    children: [
                      _SettingsTile(
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI 工作方式',
                        subtitle: '了解整理、复盘和时间规划分别使用哪些数据。',
                        onTap: () => _openDetail(
                          title: 'AI 工作方式',
                          description:
                              '“整理”把当前输入解析成任务、状态、事件或画像候选；“复盘”读取当天可见记录和你的补充文字；“时间规划”读取任务、状态、已确认画像和近期复盘。三个入口都经过独立 schema 校验，AI 不会静默修改任务或把单日复盘变成长期画像。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.bookmark_border_rounded,
                        title: '记忆管理',
                        subtitle: '查看任务、状态、生活事件和长期画像。',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => MemoryScreen(
                              database: widget.database,
                              nowProvider: widget.nowProvider,
                            ),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.pending_actions_rounded,
                        title: '待确认内容',
                        subtitle: '回到首页查看并确认最近的解析结果。',
                        trailingText: '${data?.pendingCount ?? '-'} 条',
                        onTap: widget.onOpenHome,
                      ),
                      _SettingsTile(
                        icon: Icons.visibility_outlined,
                        title: '查看建议依据',
                        subtitle: '首页 AI 建议可展开查看任务、状态、画像和近期复盘依据。',
                        onTap: widget.onOpenHome,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsSection(
                    title: '隐私与数据',
                    children: [
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: '隐私说明',
                        subtitle: '了解本地优先、AI 上传和长期画像确认规则。',
                        onTap: _openPrivacy,
                      ),
                      _SettingsTile(
                        icon: Icons.cloud_upload_outlined,
                        title: 'API 上传说明',
                        subtitle: '说明哪些内容会被发给 DeepSeek 解析或复盘。',
                        onTap: () => _openDetail(
                          title: 'API 上传说明',
                          description:
                              '整理时上传当前输入和时间上下文；复盘时上传当天可见任务、状态、事件和你的补充文字；时间规划会上传相关任务、状态、已确认画像和近期复盘。被删除记录和未确认画像不会作为有效事实使用。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.bug_report_outlined,
                        title: '日志与调试信息',
                        subtitle: '用于排查 API 和解析问题，默认不展示用户原文。',
                        onTap: () => _openDetail(
                          title: '日志与调试信息',
                          description:
                              '当前 API 错误日志只记录请求编号、错误类型和状态码，避免把用户原始输入写进服务端日志。',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsSection(
                    title: 'App 与帮助',
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: '关于 App',
                        subtitle: '一个个人记忆与行动整理 App。',
                        onTap: () => _openDetail(
                          title: '关于 App',
                          description:
                              '这个 App 帮你把自然语言整理成任务、状态、生活事件和可确认的长期画像，并提供每日复盘、时间规划和有来源依据的首页建议。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.new_releases_outlined,
                        title: '当前版本',
                        subtitle: _appVersion,
                        trailingText: kDebugMode ? 'Debug' : 'Release',
                        onTap: () => _openDetail(
                          title: '当前版本',
                          description:
                              '版本：$_appVersion\n构建类型：${kDebugMode ? 'Debug 调试包' : 'Release 正式包'}\n平台：${defaultTargetPlatform.name}',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.api_rounded,
                        title: 'API 连接状态',
                        subtitle: widget.parserBaseUri.toString(),
                        trailingText: _isCheckingApi
                            ? '检查中'
                            : _apiAvailable == null
                            ? '点击检测'
                            : _apiAvailable!
                            ? '可连接'
                            : '不可连接',
                        onTap: _checkApiConnection,
                      ),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: '使用帮助',
                        subtitle: '查看当前四个主要入口分别做什么。',
                        onTap: () => _openDetail(
                          title: '使用帮助',
                          description:
                              '首页：输入自然语言、确认整理结果、查看今日行动和建议依据。\n\n任务：编辑、完成、取消和删除任务。\n\n复盘：生成每日复盘，并创建可编辑的时间规划。\n\n我的：登录同步、通知权限、记忆控制和运行状态。',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _syncSubtitle(CloudAuthState authState) {
    if (!authState.isConfigured) {
      return '云端账号尚未配置，当前只能使用本地数据。';
    }
    if (!authState.isSignedIn) {
      return 'Supabase 已配置，登录后可使用账号数据。';
    }
    if (_cloudProfileSyncError != null) {
      return '账号已连接，但云端同步失败：$_cloudProfileSyncError';
    }
    return '账号已连接。点击后会把本机任务、记忆和复盘单向写入云端；日历排期仍只留在本机。';
  }

  Future<void> _showAccountActions(CloudAuthState authState) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(authState.isSignedIn ? '切换登录账号' : '登录 / 注册'),
              onTap: () => Navigator.of(context).pop('login'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync_rounded),
              title: const Text('立即同步到云端'),
              onTap: () => Navigator.of(context).pop('sync'),
            ),
            if (authState.isSignedIn) ...[
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('从云端恢复到本机'),
                onTap: () => Navigator.of(context).pop('restore'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('删除云端副本'),
                onTap: () => Navigator.of(context).pop('delete_cloud'),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('退出登录'),
                onTap: () => Navigator.of(context).pop('sign_out'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.danger,
                ),
                title: const Text(
                  '永久注销云端账号',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => Navigator.of(context).pop('delete_account'),
              ),
            ],
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'login':
        await _openEmailOtpSignIn();
        break;
      case 'sync':
        await _syncCloudProfileNow(authState);
        break;
      case 'restore':
        await _previewAndRestoreCloudCopy();
        break;
      case 'delete_cloud':
        await _confirmAndDeleteCloudCopy();
        break;
      case 'sign_out':
        await _signOut();
        break;
      case 'delete_account':
        await _confirmAndDeleteAccount();
        break;
    }
  }

  Future<void> _syncCloudProfileNow(CloudAuthState authState) async {
    if (!authState.isConfigured) {
      _openDetail(title: '数据与同步', description: '当前构建没有配置 Supabase，暂时只能使用本地数据。');
      return;
    }

    if (!authState.isSignedIn) {
      _openDetail(
        title: '数据与同步',
        description: '请先登录账号。登录本身不会上传本机记录；登录后可自行选择“立即同步到云端”。',
      );
      return;
    }

    try {
      await widget.cloudAuthService.ensureCloudProfile();
      final result = await widget.cloudSyncService.syncFromLocal(
        widget.database,
      );
      if (!mounted) return;
      setState(() {
        _cloudProfileSyncError = null;
        _dataFuture = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('云端同步完成，共 ${result.totalCount} 条本地记录。')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _cloudProfileSyncError = _friendlyCloudSyncError(error));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('云端写入失败：$_cloudProfileSyncError')));
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await widget.taskReminderScheduler.requestPermissions();
    if (!mounted) return;

    setState(() => _taskReminderEnabled = granted != false);
    final message = granted == false
        ? '三星系统没有授予通知权限。请打开“设置 → 应用 → 本 App → 通知”后手动允许。'
        : '任务提醒已开启。创建带具体时间的任务后，会按任务时间提醒。';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkApiConnection() async {
    if (_isCheckingApi) return;
    if (isUnconfiguredApiUri(widget.parserBaseUri)) {
      setState(() => _apiAvailable = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('此测试包尚未配置安全的 AI 服务地址。')));
      }
      return;
    }
    setState(() => _isCheckingApi = true);
    final client = HttpClient();
    try {
      final healthUri = widget.parserBaseUri.resolve('/health');
      final request = await client
          .getUrl(healthUri)
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      await response.drain<void>();
      if (!mounted) return;
      setState(() => _apiAvailable = response.statusCode == 200);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode == 200
                ? 'API 可以连接，整理、复盘和时间规划可使用。'
                : 'API 返回 ${response.statusCode}，当前服务不可用。',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiAvailable = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法连接 API，请检查网络或服务地址。')));
    } finally {
      client.close(force: true);
      if (mounted) {
        setState(() => _isCheckingApi = false);
      }
    }
  }

  Future<void> _loadTaskReminderPermission() async {
    final enabled = await widget.taskReminderScheduler.notificationsEnabled();
    if (!mounted || enabled == null) return;
    setState(() => _taskReminderEnabled = enabled);
  }

  String _friendlyCloudSyncError(Object error) {
    if (error is CloudAuthNotConfiguredException) {
      return '当前构建没有配置 Supabase。';
    }
    if (error is CloudAuthNotSignedInException) {
      return '请先登录账号。';
    }
    final message = error.toString();
    if (message.contains('permission denied') ||
        message.contains('row-level security') ||
        message.contains('42501')) {
      return '云端表权限不足，已检查 RLS / GRANT 配置。';
    }
    if (message.contains('Failed host lookup') ||
        message.contains('SocketException') ||
        message.contains('Network is unreachable')) {
      return '当前网络无法连接 Supabase，请检查网络或 VPN。';
    }
    return message.length > 160 ? '${message.substring(0, 160)}...' : message;
  }

  Future<void> _openEmailOtpSignIn() async {
    if (!widget.cloudAuthService.currentState.isConfigured) {
      _openDetail(
        title: '邮箱验证码登录',
        description:
            '当前构建没有配置 Supabase。请在运行或构建时传入 --dart-define=SUPABASE_URL=你的项目地址 和 --dart-define=SUPABASE_PUBLISHABLE_KEY=你的 publishable key。',
      );
      return;
    }

    final signedIn = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _EmailOtpSignInSheet(authService: widget.cloudAuthService),
    );

    if (!mounted) return;
    if (signedIn == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录成功，账号已连接。')));
    }
  }

  Future<void> _signOut() async {
    await widget.cloudAuthService.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已退出登录。')));
  }

  Future<void> _confirmAndDeleteCloudCopy() async {
    final confirmed = await confirmDeleteMemoryRecord(
      context: context,
      title: '删除云端副本？',
      content:
          '这会永久删除当前账号在 Supabase 中已同步的任务、记忆、复盘和旧版日历数据。本机 SQLite 数据不会删除；之后如果再次点击同步，本机数据会重新写入云端。',
    );
    if (!confirmed || !mounted) return;

    try {
      await widget.cloudSyncService.deleteCloudCopy();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('云端副本已删除；本机数据未受影响。')));
    } catch (error) {
      if (!mounted) return;
      final message = _friendlyCloudSyncError(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除云端副本失败：$message')));
    }
  }

  Future<void> _previewAndRestoreCloudCopy() async {
    try {
      final preview = await widget.cloudSyncService.previewCloudRestore();
      if (!mounted) return;
      if (preview.totalCount == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前账号没有可恢复的云端记录。')));
        return;
      }

      final confirmed = await _confirmCloudRestore(preview);
      if (!confirmed || !mounted) return;

      final result = await widget.cloudSyncService.restoreFromCloud(
        widget.database,
      );
      if (!mounted) return;
      setState(() => _dataFuture = _load());
      widget.onRecordsChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '云端恢复完成：写入 ${result.restoredCount} 条，保留本机已有/较新记录 ${result.preservedLocalCount} 条。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = _friendlyCloudSyncError(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('云端恢复失败：$message')));
    }
  }

  Future<bool> _confirmCloudRestore(CloudRestorePreview preview) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从云端恢复到本机？'),
        content: Text(
          '云端共有 ${preview.totalCount} 条记录：任务 ${preview.taskCount} 条、状态 ${preview.shortTermStateCount} 条、事件 ${preview.lifeEventCount} 条、画像 ${preview.profileItemCount} 条、复盘 ${preview.summaryCount} 条。\n\n'
          '恢复按稳定 ID 合并，云端较新时才更新；本机较新的记录会保留。日历排期、重复任务和久坐数据始终只留在本机，不会被云端覆盖。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('开始恢复'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await confirmDeleteMemoryRecord(
      context: context,
      title: '永久注销云端账号？',
      content:
          '这会删除当前 Supabase 登录账号、全部云端副本和所有云端会话，无法撤销。本机 SQLite 数据不会删除，你仍可离线查看；以后如需 AI，可重新注册账号。',
    );
    if (!confirmed || !mounted) return;

    try {
      await widget.cloudAuthService.deleteAccount();
      if (!mounted) return;
      setState(() => _cloudProfileSyncError = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('云端账号与云端数据已永久删除；本机数据未受影响。')));
    } catch (error) {
      if (!mounted) return;
      final message = _friendlyCloudSyncError(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('注销云端账号失败：$message')));
    }
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const PrivacyScreen()),
    );
  }

  void _openMemory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MemoryScreen(
          database: widget.database,
          nowProvider: widget.nowProvider,
        ),
      ),
    );
  }

  void _openDetail({required String title, required String description}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            _SettingsDetailScreen(title: title, description: description),
      ),
    );
  }
}

class _ProfileOverviewData {
  const _ProfileOverviewData({
    required this.taskCount,
    required this.activeStateCount,
    required this.lifeEventCount,
    required this.profileCount,
    required this.pendingCount,
    required this.hasTodaySummary,
  });

  final int taskCount;
  final int activeStateCount;
  final int lifeEventCount;
  final int profileCount;
  final int pendingCount;
  final bool hasTodaySummary;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.authState,
    required this.onLogin,
    required this.onSettings,
  });

  final CloudAuthState authState;
  final VoidCallback onLogin;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final signedIn = authState.isSignedIn;
    return Row(
      children: [
        const AppAssistantAvatar(size: 54),
        const SizedBox(width: 14),
        Expanded(
          child: InkWell(
            onTap: onLogin,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signedIn ? authState.displayName : '登录 / 注册',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    signedIn ? '账号已连接，继续你的记忆之旅' : '登录后开启你的记忆之旅 ✨',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            tooltip: '账号与高级设置',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined, size: 21),
          ),
        ),
      ],
    );
  }
}

class _EmailOtpSignInSheet extends StatefulWidget {
  const _EmailOtpSignInSheet({required this.authService});

  final CloudAuthService authService;

  @override
  State<_EmailOtpSignInSheet> createState() => _EmailOtpSignInSheetState();
}

class _EmailOtpSignInSheetState extends State<_EmailOtpSignInSheet> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  var _isSending = false;
  var _isVerifying = false;
  var _otpSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '邮箱验证码登录',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            '输入邮箱后，Supabase 会发送一次性验证码。第一版只做邮箱登录，不做密码和第三方登录。',
            style: TextStyle(color: Color(0xFF746E66), height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '邮箱',
              hintText: 'name@example.com',
            ),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '验证码',
                hintText: '输入邮箱中的 6 位验证码',
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _isSending ? null : _sendOtp,
                  child: Text(_otpSent ? '重新发送验证码' : '发送验证码'),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    child: const Text('完成登录'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _errorMessage = '请输入有效邮箱。');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.sendEmailOtp(email);
      if (!mounted) return;
      setState(() => _otpSent = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    if (token.length < 4) {
      setState(() => _errorMessage = '请输入邮箱里的验证码。');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.verifyEmailOtp(email: email, token: token);
      await widget.authService.ensureCloudProfile();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  String _friendlyAuthError(Object error) {
    if (error is CloudAuthNotConfiguredException) {
      return '当前构建还没有配置 Supabase。';
    }
    return '登录失败，请检查邮箱、验证码和网络后重试。';
  }
}

class _TodayOverviewCard extends StatelessWidget {
  const _TodayOverviewCard({required this.data});

  final _ProfileOverviewData? data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日概览',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OverviewPill(
                    icon: Icons.task_alt_rounded,
                    color: AppColors.primary,
                    label: '待办任务',
                    value: data?.taskCount,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _OverviewPill(
                    icon: Icons.monitor_heart_outlined,
                    color: AppColors.mint,
                    label: '记录条数',
                    value: data == null
                        ? null
                        : data!.activeStateCount + data!.lifeEventCount,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _OverviewPill(
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.orange,
                    label: '待确认',
                    value: data?.pendingCount,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _OverviewPill(
                    icon: Icons.psychology_alt_outlined,
                    color: AppColors.purple,
                    label: '长期记忆',
                    value: data?.profileCount,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({
    required this.icon,
    required this.color,
    required this.label,
    this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 6),
          Text(
            '${value ?? '-'}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onNotifications,
    required this.onSync,
    required this.onPrivacy,
    required this.onMemory,
  });

  final VoidCallback onNotifications;
  final VoidCallback onSync;
  final VoidCallback onPrivacy;
  final VoidCallback onMemory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.notifications_active_rounded,
            label: '通知',
            onTap: onNotifications,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.cloud_sync_rounded,
            label: '同步',
            onTap: onSync,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.privacy_tip_outlined,
            label: '隐私',
            onTap: onPrivacy,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.psychology_alt_outlined,
            label: '记忆',
            onTap: onMemory,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 3),
            ...children.take(title == '复盘设置' ? 3 : 2),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 3),
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      subtitle: null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 128),
            child: Text(
              trailingText ?? subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SettingsDetailScreen extends StatelessWidget {
  const _SettingsDetailScreen({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF3A3835),
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
