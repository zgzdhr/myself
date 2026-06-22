import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/local_db/app_database.dart';
import '../../domain/item_type.dart';
import '../account/cloud_auth_service.dart';
import '../account/cloud_sync_service.dart';
import '../memory/memory_screen.dart';
import '../memory/privacy_screen.dart';
import '../memory/profile_items_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    required this.database,
    required this.nowProvider,
    required this.parserBaseUri,
    required this.cloudAuthService,
    required this.cloudSyncService,
    super.key,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;
  final Uri parserBaseUri;
  final CloudAuthService cloudAuthService;
  final CloudSyncService cloudSyncService;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  late Future<_ProfileOverviewData> _dataFuture;
  var _reviewAffectsHome = true;
  var _taskReminderEnabled = true;
  var _dailyPlanReminderEnabled = false;
  var _dailyReviewReminderEnabled = false;
  var _defaultReminderLeadMinutes = 0;
  String? _lastSyncedCloudProfileUserId;
  String? _cloudProfileSyncError;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_ProfileOverviewData> _load() async {
    final now = widget.nowProvider();
    final tasks = await widget.database.getVisibleTasks();
    final states = await widget.database.getActiveShortTermStates(now: now);
    final events = await widget.database.getActiveLifeEvents();
    final profiles = await widget.database.getActiveProfileItems();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: StreamBuilder<CloudAuthState>(
        stream: widget.cloudAuthService.watchAuthState(),
        initialData: widget.cloudAuthService.currentState,
        builder: (context, authSnapshot) {
          final authState =
              authSnapshot.data ?? widget.cloudAuthService.currentState;
          _syncCloudProfileIfNeeded(authState);

          return FutureBuilder<_ProfileOverviewData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _AccountCard(
                    authState: authState,
                    onLogin: () => _openEmailOtpSignIn(),
                    onSignOut: authState.isSignedIn ? _signOut : null,
                  ),
                  const SizedBox(height: 14),
                  _TodayOverviewCard(data: data),
                  const SizedBox(height: 14),
                  _QuickActions(
                    onNotifications: () => _openDetail(
                      title: '通知设置',
                      description: '任务提醒已经接入系统通知。后续会在这里配置提前量、每日计划和复盘提醒。',
                    ),
                    onSync: () => _syncCloudProfileNow(authState),
                    onPrivacy: () => _openPrivacy(),
                    onAi: () => _openDetail(
                      title: 'AI 设置',
                      description:
                          '解析继续走结构化模型，复盘计划使用 DeepSeek v4-pro。第一版只展示用途，不开放复杂参数。',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: '账号与同步',
                    children: [
                      _SettingsTile(
                        icon: Icons.login_rounded,
                        title: '登录 / 注册',
                        subtitle: authState.isConfigured
                            ? '使用邮箱验证码登录，先不做第三方登录。'
                            : '需要先配置 Supabase URL 和 publishable key。',
                        trailingText: authState.isConfigured ? '邮箱验证码' : '未配置',
                        onTap: () => _openEmailOtpSignIn(),
                      ),
                      _SettingsTile(
                        icon: Icons.sync_rounded,
                        title: '同步状态',
                        subtitle: _syncSubtitle(authState),
                        trailingText: authState.syncLabel,
                        onTap: () => _syncCloudProfileNow(authState),
                      ),
                      _SettingsTile(
                        icon: Icons.cloud_sync_rounded,
                        title: '手动同步',
                        subtitle: '第一版先完成账号和云端表合同，记录双向同步后续再接。',
                        trailingText: authState.isSignedIn ? '待同步' : '需登录',
                        onTap: () => _showComingSoon('手动同步'),
                      ),
                      _SettingsTile(
                        icon: Icons.phone_android_rounded,
                        title: '当前设备',
                        subtitle: '这台手机上的本地缓存和系统通知配置。',
                        trailingText: defaultTargetPlatform.name,
                        onTap: () => _openDetail(
                          title: '当前设备',
                          description: '后续登录后，这里会显示设备同步状态和最近同步时间。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.storage_rounded,
                        title: '数据存储位置说明',
                        subtitle: '说明哪些数据在本地，哪些会进入云端，哪些会发给 AI。',
                        onTap: () => _openDetail(
                          title: '数据存储位置说明',
                          description:
                              '当前任务、状态、事件和画像仍保存在本地 SQLite。Phase 5A 已确定云端目标表和 RLS 边界，登录后数据会按 user_id 归属到云端表；第一版不做复杂离线冲突合并。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: '退出登录',
                        subtitle: authState.isSignedIn
                            ? '退出账号不会删除本地缓存或云端数据。'
                            : '当前没有已登录账号。',
                        trailingText: authState.isSignedIn ? null : '未登录',
                        onTap: authState.isSignedIn
                            ? _signOut
                            : () => _showComingSoon('退出登录'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: '提醒与任务',
                    children: [
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.notifications_active_rounded,
                        ),
                        title: const Text('任务提醒'),
                        subtitle: const Text('只在任务快开始时提醒，不提醒普通编辑或删除。'),
                        value: _taskReminderEnabled,
                        onChanged: (value) {
                          setState(() => _taskReminderEnabled = value);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '默认提醒时间',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 0, label: Text('准时')),
                                ButtonSegment(value: 5, label: Text('5 分钟')),
                                ButtonSegment(value: 10, label: Text('10 分钟')),
                                ButtonSegment(value: 30, label: Text('30 分钟')),
                              ],
                              selected: {_defaultReminderLeadMinutes},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _defaultReminderLeadMinutes = selection.first;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.wb_sunny_outlined),
                        title: const Text('每日计划提醒'),
                        subtitle: const Text('未来可每天提醒你看一眼今日行动。'),
                        value: _dailyPlanReminderEnabled,
                        onChanged: (value) {
                          setState(() => _dailyPlanReminderEnabled = value);
                        },
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.edit_note_rounded),
                        title: const Text('每日复盘提醒'),
                        subtitle: const Text('未来可在晚上提醒你生成今日复盘。'),
                        value: _dailyReviewReminderEnabled,
                        onChanged: (value) {
                          setState(() => _dailyReviewReminderEnabled = value);
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.task_alt_rounded,
                        title: '已完成任务显示方式',
                        subtitle: '当前保留可见，并用状态标签区分。',
                        trailingText: '保留',
                        onTap: () => _showComingSoon('已完成任务显示方式'),
                      ),
                      _SettingsTile(
                        icon: Icons.cancel_outlined,
                        title: '已取消任务显示方式',
                        subtitle: '当前保留可见，但不参与首页建议。',
                        trailingText: '保留',
                        onTap: () => _showComingSoon('已取消任务显示方式'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: '复盘设置',
                    children: [
                      _SettingsTile(
                        icon: Icons.today_rounded,
                        title: '每日复盘入口',
                        subtitle: '整理当天任务、状态和生活事件。',
                        onTap: () => _showComingSoon('每日复盘'),
                      ),
                      _SettingsTile(
                        icon: Icons.history_rounded,
                        title: '历史复盘',
                        subtitle: '后续可按日期查看每日复盘。',
                        trailingText: '待接入',
                        onTap: () => _showComingSoon('历史复盘'),
                      ),
                      _SettingsTile(
                        icon: Icons.schedule_rounded,
                        title: '复盘提醒时间',
                        subtitle: '默认适合放在晚上，后续可自定义。',
                        trailingText: '待设置',
                        onTap: () => _showComingSoon('复盘提醒时间'),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.lightbulb_outline_rounded),
                        title: const Text('复盘结果参与首页建议'),
                        subtitle: const Text('只作为轻上下文，不自动改任务或画像。'),
                        value: _reviewAffectsHome,
                        onChanged: (value) {
                          setState(() => _reviewAffectsHome = value);
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.refresh_rounded,
                        title: '重新生成今日复盘',
                        subtitle: '未来会基于同一天的可见来源重新生成。',
                        trailingText: '待接入',
                        onTap: () => _showComingSoon('重新生成今日复盘'),
                      ),
                      _SettingsTile(
                        icon: Icons.delete_outline_rounded,
                        title: '删除今日复盘',
                        subtitle: '删除后不再参与首页建议。',
                        trailingText: '需确认',
                        onTap: () => _confirmSensitiveAction(
                          title: '删除今日复盘？',
                          content: '当前版本还没有正式复盘数据。接入后，这个操作会只删除今日复盘，不删除原始任务和事件。',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'AI 与记忆',
                    children: [
                      _SettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'AI 解析设置',
                        subtitle: '负责把自然语言整理成任务、状态、事件和画像候选。',
                        trailingText: '结构化',
                        onTap: () => _showComingSoon('AI 解析设置'),
                      ),
                      _SettingsTile(
                        icon: Icons.auto_awesome_rounded,
                        title: '复盘模型设置',
                        subtitle: '计划使用 DeepSeek v4-pro，语气更适合总结和建议。',
                        trailingText: 'v4-pro',
                        onTap: () => _showComingSoon('复盘模型设置'),
                      ),
                      _SettingsTile(
                        icon: Icons.schema_rounded,
                        title: '解析模型设置',
                        subtitle: '继续保持低温度和 JSON 校验，保证入库稳定。',
                        trailingText: '0.35',
                        onTap: () => _showComingSoon('解析模型设置'),
                      ),
                      _SettingsTile(
                        icon: Icons.thermostat_rounded,
                        title: 'AI 温度说明与当前值',
                        subtitle: '解析偏稳定，复盘可以更自然，但仍要有来源依据。',
                        onTap: () => _openDetail(
                          title: 'AI 温度说明与当前值',
                          description:
                              '温度可以理解为 AI 回答的发散程度。结构化解析要稳定，所以温度低；复盘更像总结和表达，可以适当高一些。',
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
                        icon: Icons.person_search_rounded,
                        title: '长期画像管理',
                        subtitle: '只有你确认过的长期画像才会影响建议。',
                        trailingText: '${data?.profileCount ?? '-'} 条',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ProfileItemsScreen(
                              database: widget.database,
                              nowProvider: widget.nowProvider,
                            ),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.pending_actions_rounded,
                        title: '待确认内容',
                        subtitle: 'AI 猜出来但还没确认的内容会在这里汇总。',
                        trailingText: '${data?.pendingCount ?? '-'} 条',
                        onTap: () => _showComingSoon('待确认内容汇总'),
                      ),
                      _SettingsTile(
                        icon: Icons.visibility_outlined,
                        title: '查看 AI 使用了哪些记忆',
                        subtitle: '后续每条建议都应该能解释自己的来源。',
                        trailingText: '待接入',
                        onTap: () => _showComingSoon('建议来源说明'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                        icon: Icons.file_download_outlined,
                        title: '导出数据',
                        subtitle: '未来可导出任务、事件、复盘和画像。',
                        trailingText: '待接入',
                        onTap: () => _showComingSoon('导出数据'),
                      ),
                      _SettingsTile(
                        icon: Icons.cleaning_services_outlined,
                        title: '删除本地缓存',
                        subtitle: '不会删除云端账号数据，接入云端后可重新同步。',
                        trailingText: '需确认',
                        onTap: () => _confirmSensitiveAction(
                          title: '删除本地缓存？',
                          content: '这个操作后续会清理当前设备缓存。正式实现前不会真的删除任何数据。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.delete_forever_outlined,
                        title: '删除云端账号数据',
                        subtitle: '高风险操作，正式接入后必须二次确认。',
                        trailingText: '危险',
                        onTap: () => _confirmSensitiveAction(
                          title: '删除云端账号数据？',
                          content: '这会影响账号下的任务、记忆和复盘数据。当前版本只是占位确认，不会执行删除。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.cloud_upload_outlined,
                        title: 'API 上传说明',
                        subtitle: '说明哪些内容会被发给 DeepSeek 解析或复盘。',
                        onTap: () => _openDetail(
                          title: 'API 上传说明',
                          description:
                              '解析时只上传当前输入和必要上下文。未来复盘会上传当天可见记录和你的补充文字，不上传被删除或未确认的长期画像。',
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
                  const SizedBox(height: 16),
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
                              '这个 App 帮你把自然语言整理成任务、状态、生活事件和可确认的长期画像，再逐步加入复盘和更稳定的建议。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.new_releases_outlined,
                        title: '当前版本',
                        subtitle: _appVersion,
                        trailingText: kDebugMode ? 'Debug' : 'Release',
                        onTap: () => _showComingSoon('版本详情'),
                      ),
                      _SettingsTile(
                        icon: Icons.api_rounded,
                        title: 'API 连接状态',
                        subtitle: widget.parserBaseUri.toString(),
                        trailingText: '解析代理',
                        onTap: () => _openDetail(
                          title: 'API 连接状态',
                          description:
                              '当前解析接口地址：${widget.parserBaseUri}。后续云端部署后，这里会显示线上 API 是否可用。',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: '通知权限状态',
                        subtitle: '已接入系统通知，权限由 Android / iOS 系统管理。',
                        trailingText: '系统',
                        onTap: () => _showComingSoon('通知权限状态'),
                      ),
                      _SettingsTile(
                        icon: Icons.build_circle_outlined,
                        title: '构建环境',
                        subtitle: kDebugMode ? 'Debug 调试包' : 'Release 正式包',
                        onTap: () => _showComingSoon('构建环境'),
                      ),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: '使用帮助',
                        subtitle: '后续补充真实使用指引。',
                        trailingText: '待接入',
                        onTap: () => _showComingSoon('使用帮助'),
                      ),
                      _SettingsTile(
                        icon: Icons.feedback_outlined,
                        title: '反馈问题',
                        subtitle: '记录试用中遇到的识别、提醒和复盘问题。',
                        trailingText: '待接入',
                        onTap: () => _showComingSoon('反馈问题'),
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
      return '账号已连接，但 profile 写入失败：$_cloudProfileSyncError';
    }
    return '账号已连接，已写入云端 profile。业务数据同步将分阶段接入。';
  }

  void _syncCloudProfileIfNeeded(CloudAuthState authState) {
    final userId = authState.userId;
    if (!authState.isConfigured || !authState.isSignedIn || userId == null) {
      _lastSyncedCloudProfileUserId = null;
      return;
    }

    if (_lastSyncedCloudProfileUserId == userId) {
      return;
    }

    _lastSyncedCloudProfileUserId = userId;
    Future<void>(() async {
      try {
        await widget.cloudAuthService.ensureCloudProfile();
        if (!mounted || _cloudProfileSyncError == null) return;
        setState(() => _cloudProfileSyncError = null);
      } catch (error) {
        if (!mounted) return;
        setState(() => _cloudProfileSyncError = error.toString());
      }
    });
  }

  Future<void> _syncCloudProfileNow(CloudAuthState authState) async {
    if (!authState.isConfigured) {
      _openDetail(title: '数据与同步', description: '当前构建没有配置 Supabase，暂时只能使用本地数据。');
      return;
    }

    if (!authState.isSignedIn) {
      _openDetail(
        title: '数据与同步',
        description: '请先登录账号。登录后可以先写入云端 profile，用来验证账号、RLS 和 Supabase 表权限。',
      );
      return;
    }

    try {
      await widget.cloudAuthService.ensureCloudProfile();
      final result = await widget.cloudSyncService.syncFromLocal(
        widget.database,
      );
      _lastSyncedCloudProfileUserId = authState.userId;
      if (!mounted) return;
      setState(() => _cloudProfileSyncError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('云端同步完成，共 ${result.totalCount} 条本地记录。')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _cloudProfileSyncError = error.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('云端写入失败：$error')));
    }
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

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const PrivacyScreen()),
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

  Future<void> _confirmSensitiveAction({
    required String title,
    required String content,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    _showComingSoon(title.replaceAll('？', ''));
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$featureName 会在后续接入。')));
  }
}

class _ProfileOverviewData {
  const _ProfileOverviewData({
    required this.taskCount,
    required this.activeStateCount,
    required this.lifeEventCount,
    required this.profileCount,
    required this.pendingCount,
  });

  final int taskCount;
  final int activeStateCount;
  final int lifeEventCount;
  final int profileCount;
  final int pendingCount;
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.authState,
    required this.onLogin,
    required this.onSignOut,
  });

  final CloudAuthState authState;
  final VoidCallback onLogin;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final subtitle = !authState.isConfigured
        ? '配置 Supabase 后可使用云端账号'
        : authState.isSignedIn
        ? '云端账号已连接'
        : '登录后可使用云端数据和多设备访问';
    final icon = authState.isSignedIn
        ? Icons.verified_user_rounded
        : Icons.person_rounded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0EC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD5DFD8)),
                  ),
                  child: Icon(icon, color: const Color(0xFF53736A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.displayName,
                        style: const TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF746E66),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: Text(authState.isSignedIn ? '切换账号' : '邮箱登录'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(onPressed: onSignOut, child: const Text('退出')),
              ],
            ),
          ],
        ),
      ),
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
              '今日数据概览',
              style: TextStyle(
                color: Color(0xFF1D1D1F),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OverviewPill(label: '任务', value: data?.taskCount),
                _OverviewPill(label: '状态', value: data?.activeStateCount),
                _OverviewPill(label: '事件', value: data?.lifeEventCount),
                _OverviewPill(label: '画像', value: data?.profileCount),
                _OverviewPill(label: '待确认', value: data?.pendingCount),
                const _OverviewPill(label: '今日复盘', textValue: '未生成'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({required this.label, this.value, this.textValue});

  final String label;
  final int? value;
  final String? textValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAE0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${textValue ?? value ?? '-'}',
        style: const TextStyle(
          color: Color(0xFF3A3835),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onNotifications,
    required this.onSync,
    required this.onPrivacy,
    required this.onAi,
  });

  final VoidCallback onNotifications;
  final VoidCallback onSync;
  final VoidCallback onPrivacy;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _QuickActionButton(
          icon: Icons.notifications_active_rounded,
          label: '通知设置',
          onTap: onNotifications,
        ),
        _QuickActionButton(
          icon: Icons.cloud_sync_rounded,
          label: '数据与同步',
          onTap: onSync,
        ),
        _QuickActionButton(
          icon: Icons.privacy_tip_outlined,
          label: '隐私与记忆',
          onTap: onPrivacy,
        ),
        _QuickActionButton(
          icon: Icons.auto_awesome_rounded,
          label: 'AI 设置',
          onTap: onAi,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF746E66),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
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
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF53736A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: const TextStyle(
                color: Color(0xFF8A8278),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8278)),
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
