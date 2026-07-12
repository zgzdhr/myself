part of 'home_screen.dart';

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppAssistantAvatar(),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Myself',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '你的记忆与行动助手',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _DebugDateSwitcher(),
          ],
        ),
        SizedBox(height: 19),
        _HomeGreeting(),
      ],
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
        Row(
          children: [
            Text(
              '早上好',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 7),
            const Text('✨', style: TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          '记录 · 整理 · 行动 · 成长',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
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

    return PopupMenuButton<String>(
      tooltip: '测试日期',
      onSelected: (value) {
        if (value == 'previous') {
          ref.read(debugNowOverrideProvider.notifier).setPreviousDay(local);
        } else if (value == 'next') {
          ref.read(debugNowOverrideProvider.notifier).setNextDay(local);
        } else {
          ref.read(debugNowOverrideProvider.notifier).clear();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(enabled: false, child: Text('测试日期 · $label')),
        const PopupMenuItem(value: 'previous', child: Text('前一天')),
        const PopupMenuItem(value: 'next', child: Text('后一天')),
        const PopupMenuItem(value: 'real', child: Text('真实日期')),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x142F7DF6),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.adjust_rounded, size: 22),
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
    required this.taskReminderScheduler,
    required this.onRecordsChanged,
  });

  final List<HomeSuggestion> suggestions;
  final HomeSuggestionContext contextData;
  final AppDatabase database;
  final DateTime Function() nowProvider;
  final TaskReminderScheduler taskReminderScheduler;
  final VoidCallback onRecordsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SedentarySessionPanel(
          database: database,
          nowProvider: nowProvider,
          taskReminderScheduler: taskReminderScheduler,
          onRecordsChanged: onRecordsChanged,
        ),
        const SizedBox(height: 14),
        _HomeListSection(
          title: '今日行动',
          emptyText: '暂无今日任务',
          items: [for (final task in contextData.todayTasks) task.displayText],
        ),
        const SizedBox(height: 14),
        _HomeSuggestionPanel(
          suggestions: suggestions,
          contextData: contextData,
        ),
        const SizedBox(height: 14),
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

class _SedentarySessionPanel extends StatefulWidget {
  const _SedentarySessionPanel({
    required this.database,
    required this.nowProvider,
    required this.taskReminderScheduler,
    required this.onRecordsChanged,
  });

  final AppDatabase database;
  final DateTime Function() nowProvider;
  final TaskReminderScheduler taskReminderScheduler;
  final VoidCallback onRecordsChanged;

  @override
  State<_SedentarySessionPanel> createState() => _SedentarySessionPanelState();
}

class _SedentarySessionPanelState extends State<_SedentarySessionPanel> {
  late Future<SedentarySession?> _activeFuture;

  @override
  void initState() {
    super.initState();
    _activeFuture = widget.database.getActiveSedentarySession();
  }

  @override
  void didUpdateWidget(covariant _SedentarySessionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.database != widget.database) {
      _activeFuture = widget.database.getActiveSedentarySession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SedentarySession?>(
      future: _activeFuture,
      builder: (context, snapshot) {
        final session = snapshot.data;
        final isActive = session != null;
        return _SurfacePanel(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFFF4DB)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFE6C56E)
                        : const Color(0xFFD8E7FF),
                  ),
                ),
                child: Icon(
                  isActive
                      ? Icons.timer_outlined
                      : Icons.self_improvement_rounded,
                  color: isActive ? const Color(0xFF9B6A00) : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? '久坐中' : '开始久坐',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? '将在 ${_timeLabel(session.reminderAt)} 提醒你站起来活动'
                          : '手动开始，默认 60 分钟后提醒活动',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: isActive ? () => _end(session) : _start,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(isActive ? '结束' : '开始计时'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _start() async {
    final now = widget.nowProvider();
    final session = await widget.database.startSedentarySession(startedAt: now);
    await SedentaryReminderCoordinator(
      scheduler: widget.taskReminderScheduler,
    ).schedule(sessionId: session.id, reminderAt: session.reminderAt, now: now);
    _refresh();
    widget.onRecordsChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已开始久坐，约 1 小时后提醒活动。')));
  }

  Future<void> _end(SedentarySession session) async {
    final now = widget.nowProvider();
    await widget.database.endSedentarySession(id: session.id, endedAt: now);
    await SedentaryReminderCoordinator(
      scheduler: widget.taskReminderScheduler,
    ).cancel(session.id);
    _refresh();
    widget.onRecordsChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已结束久坐提醒。')));
  }

  void _refresh() {
    setState(() {
      _activeFuture = widget.database.getActiveSedentarySession();
    });
  }

  String _timeLabel(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

class _HomeSuggestionPanel extends StatelessWidget {
  const _HomeSuggestionPanel({
    required this.suggestions,
    required this.contextData,
  });

  final List<HomeSuggestion> suggestions;
  final HomeSuggestionContext contextData;

  @override
  Widget build(BuildContext context) {
    final primarySuggestion = suggestions.first;

    return _SurfacePanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: const Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: AppColors.primary,
            ),
            title: const Text(
              'AI 建议',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                primarySuggestion.text,
                style: const TextStyle(
                  color: Color(0xFF1D1D1F),
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            children: [
              if (suggestions.length > 1) ...[
                const SizedBox(height: 4),
                for (final suggestion in suggestions.skip(1))
                  _SuggestionTextRow(text: suggestion.text),
                const SizedBox(height: 8),
              ],
              _EvidenceGroup(
                title: '任务依据',
                emptyText: '暂无可用于建议的任务',
                items: [
                  for (final task in contextData.tasks.take(3))
                    task.displayText,
                ],
              ),
              const SizedBox(height: 12),
              _EvidenceGroup(
                title: '当前状态',
                emptyText: '暂无未过期状态',
                items: [
                  for (final state in contextData.shortTermStates.take(3))
                    state.content,
                ],
              ),
              const SizedBox(height: 12),
              _EvidenceGroup(
                title: '长期偏好',
                emptyText: '暂无已确认长期画像',
                items: [
                  for (final profile in contextData.profileItems.take(2))
                    profile.content,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTextRow extends StatelessWidget {
  const _SuggestionTextRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.arrow_right_rounded,
              size: 18,
              color: Color(0xFF53736A),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF3A3835),
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceGroup extends StatelessWidget {
  const _EvidenceGroup({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9E1D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1D1D1F),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
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
            for (final item in items)
              _CompactBullet(text: item, color: const Color(0xFF53736A)),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const Spacer(),
            const Text(
              '全部任务 ›',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _SurfacePanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    emptyText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < items.take(4).length; index++)
                      _HomeTaskRow(
                        text: items[index],
                        showDivider: index < items.take(4).length - 1,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HomeTaskRow extends StatelessWidget {
  const _HomeTaskRow({required this.text, required this.showDivider});

  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB4C0D2)),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFFA8B3C4),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _CompactBullet extends StatelessWidget {
  const _CompactBullet({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 5, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142F7DF6),
            offset: Offset(0, 10),
            blurRadius: 22,
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
