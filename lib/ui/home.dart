import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../services/launch.dart';
import '../services/notifications.dart';
import 'edit_sheet.dart';
import 'listen_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Tab { tasks, ideas, done }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final store = AppStore.instance;
  _Tab tab = _Tab.tasks;
  bool _listenOpen = false;
  DateTime? _pausedAt;
  late final StreamSubscription _tapSub;
  late final StreamSubscription _listenSub;
  Timer? _minuteTick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tapSub = Notifications.instance.taps.listen(_onNotificationTap);
    _listenSub = LaunchBridge.listenRequests.listen((_) => _openListen());
    _minuteTick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {}); // keeps "overdue" and "today" fresh
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onLaunch());
  }

  Future<void> _onLaunch() async {
    unawaited(store.refreshSchedules());
    final tap = Notifications.instance.launchTap;
    Notifications.instance.launchTap = null;
    if (tap != null) {
      _onNotificationTap(tap);
      if (tap.action != null) return;
    }
    final asked = await LaunchBridge.consumeListenRequest();
    if (asked || store.settings.listenOnOpen) _openListen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      store.refreshSchedules();
      LaunchBridge.consumeListenRequest().then((asked) {
        if (asked || (store.settings.listenOnOpen && away > const Duration(seconds: 30))) {
          _openListen();
        }
      });
    }
  }

  void _onNotificationTap(NotificationTap tap) {
    final r = store.byId(tap.reminderId);
    if (r == null) return;
    switch (tap.action) {
      case 'done':
        if (!r.done) store.toggleDone(r);
      case 'snooze':
        store.snooze(r, const Duration(minutes: 10));
      default:
        setState(() => tab = r.isIdea ? _Tab.ideas : _Tab.tasks);
    }
  }

  Future<void> _openListen() async {
    if (_listenOpen || !mounted) return;
    _listenOpen = true;
    unawaited(LaunchBridge.consumeListenRequest()); // this request is being handled
    Navigator.of(context).popUntil((r) => r.isFirst);
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => const ListenScreen(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(a), child: child),
        ),
      ),
    );
    _listenOpen = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub.cancel();
    _listenSub.cancel();
    _minuteTick?.cancel();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    final s = context.s;
    return h < 12
        ? s.goodMorning
        : h < 18
        ? s.goodAfternoon
        : s.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(s.dateLong(now), style: TextStyle(color: context.colors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: s.settings,
                          icon: const Icon(Icons.tune_rounded),
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _summary(context, now)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: SegmentedButton<_Tab>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: _Tab.tasks,
                          label: Text(s.tasks),
                          icon: const Icon(Icons.checklist_rounded),
                        ),
                        ButtonSegment(
                          value: _Tab.ideas,
                          label: Text(s.ideas),
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                        ),
                        ButtonSegment(value: _Tab.done, label: Text(s.done), icon: const Icon(Icons.done_all_rounded)),
                      ],
                      selected: {tab},
                      onSelectionChanged: (v) => setState(() => tab = v.first),
                    ),
                  ),
                ),
                ..._list(context, now),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: context.isDark ? const Color(0xFF26223F) : Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: IconButton(
                  tooltip: s.typeInstead,
                  padding: const EdgeInsets.all(14),
                  icon: const Icon(Icons.keyboard_alt_outlined),
                  onPressed: () => showEditSheet(context),
                ),
              ),
              const SizedBox(width: 16),
              MicButton(onTap: _openListen, label: s.tapToTalk),
              const SizedBox(width: 68),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(BuildContext context, DateTime now) {
    final s = context.s;
    final today = store.tasksOn(now);
    final next = store.openTasks.where((r) => r.due != null && r.due!.isAfter(now)).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: Brand.violet.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tasksToday(today),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    next == null ? s.whatToRemind : '${next.text} · ${s.when(next.due!, now)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Colors.white),
                  const SizedBox(height: 2),
                  Text(
                    '${store.ideas.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _list(BuildContext context, DateTime now) {
    final s = context.s;
    switch (tab) {
      case _Tab.ideas:
        final ideas = store.ideas;
        if (ideas.isEmpty) return [EmptyState(icon: Icons.lightbulb_outline_rounded, text: s.emptyIdeas)];
        return [_section(null, ideas, now)];
      case _Tab.done:
        final done = store.finished;
        if (done.isEmpty) return [EmptyState(icon: Icons.emoji_events_outlined, text: s.emptyDone)];
        return [_section(null, done, now)];
      case _Tab.tasks:
        final tasks = store.openTasks;
        if (tasks.isEmpty) return [EmptyState(icon: Icons.mic_none_rounded, text: s.emptyTasks)];
        final today = DateTime(now.year, now.month, now.day);
        final groups = <String, List<Reminder>>{};
        for (final r in tasks) {
          final String key;
          if (r.due == null) {
            key = s.noTime;
          } else if (r.due!.isBefore(now)) {
            key = s.overdue;
          } else {
            final d = DateTime(r.due!.year, r.due!.month, r.due!.day).difference(today).inDays;
            key = d == 0
                ? s.today
                : d == 1
                ? s.tomorrow
                : s.later;
          }
          groups.putIfAbsent(key, () => []).add(r);
        }
        final order = [s.overdue, s.today, s.tomorrow, s.later, s.noTime];
        return [
          for (final k in order)
            if (groups[k] != null) _section(k, groups[k]!, now),
        ];
    }
  }

  Widget _section(String? title, List<Reminder> items, DateTime now) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.list(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 14, bottom: 8, start: 4),
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant),
              ),
            )
          else
            const SizedBox(height: 8),
          for (final r in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReminderTile(reminder: r, now: now),
            ),
        ],
      ),
    );
  }
}
