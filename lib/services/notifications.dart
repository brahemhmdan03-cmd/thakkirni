import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/models.dart';
import '../core/parser.dart';
import '../core/platform.dart';
import '../core/strings.dart';

/// A tap on a notification or one of its buttons.
class NotificationTap {
  NotificationTap(this.reminderId, this.action);
  final String reminderId;

  /// 'done', 'snooze' or null for a plain tap.
  final String? action;
}

class Notifications {
  Notifications._();
  static final Notifications instance = Notifications._();

  static const _ideaBaseId = 1000000;
  static const _maxIdeaSlots = 14;
  static const _ideaSlotsKey = 'idea_slots_v1';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<NotificationTap>.broadcast();
  Stream<NotificationTap> get taps => _taps.stream;

  /// A tap that launched the app from a closed state.
  NotificationTap? launchTap;

  S get _s => S.of(PlatformDispatcher.instance.locale.languageCode == 'ar' ? 'ar' : 'en');

  Future<void> init() async {
    if (kIsWeb) return; // browser preview: no scheduled notifications
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Unknown zone name: fall back to a fixed offset zone so times still match the phone.
      tz.setLocalLocation(tz.UTC);
    }

    final s = _s;
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'task',
          actions: [
            DarwinNotificationAction.plain('done', s.actionDone, options: {DarwinNotificationActionOption.foreground}),
            DarwinNotificationAction.plain(
              'snooze',
              s.actionSnooze,
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
        DarwinNotificationCategory(
          'idea',
          actions: [
            DarwinNotificationAction.plain('done', s.actionDone, options: {DarwinNotificationActionOption.foreground}),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: (r) {
        final tap = _decode(r.payload, r.actionId);
        if (tap != null) _taps.add(tap);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final r = launch!.notificationResponse;
      launchTap = _decode(r?.payload, r?.actionId);
    }
  }

  NotificationTap? _decode(String? payload, String? action) {
    if (payload == null || payload.isEmpty) return null;
    return NotificationTap(payload, (action == null || action.isEmpty) ? null : action);
  }

  /// Asks for notification (and on Android exact-alarm) permission.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true, badge: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ok = await android?.requestNotificationsPermission() ?? false;
    if (!(await android?.canScheduleExactNotifications() ?? true)) {
      await android?.requestExactAlarmsPermission();
    }
    return ok;
  }

  Future<bool> canScheduleExact() async {
    if (!isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  Future<void> requestExactAlarms() async {
    if (kIsWeb) return;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  NotificationDetails _details({required bool idea, required S s}) => NotificationDetails(
    android: AndroidNotificationDetails(
      idea ? 'ideas' : 'tasks',
      idea ? s.channelIdeas : s.channelTasks,
      importance: idea ? Importance.defaultImportance : Importance.max,
      priority: idea ? Priority.defaultPriority : Priority.high,
      category: idea ? null : AndroidNotificationCategory.reminder,
      actions: [
        AndroidNotificationAction('done', s.actionDone, showsUserInterface: true),
        if (!idea) AndroidNotificationAction('snooze', s.actionSnooze, showsUserInterface: true),
      ],
    ),
    iOS: DarwinNotificationDetails(
      categoryIdentifier: idea ? 'idea' : 'task',
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    ),
  );

  Future<AndroidScheduleMode> _mode() async =>
      await canScheduleExact() ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> _schedule(
    int id,
    DateTime when,
    String title,
    String body,
    String payload, {
    required bool idea,
    required S s,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details(idea: idea, s: s),
      androidScheduleMode: await _mode(),
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> cancelFor(Reminder r) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: r.notificationId);
    await _plugin.cancel(id: r.notificationId + 1);
  }

  Future<void> scheduleTask(Reminder r, Settings settings) async {
    if (kIsWeb) return;
    await cancelFor(r);
    if (r.done || r.isIdea || r.due == null) return;
    final s = S.of(ReminderParser.isArabic(r.text) ? 'ar' : 'en');
    await _schedule(r.notificationId, r.due!, s.notifTaskTitle, r.text, r.id, idea: false, s: s);
    final pre = settings.preAlertMinutes;
    if (pre > 0) {
      await _schedule(
        r.notificationId + 1,
        r.due!.subtract(Duration(minutes: pre)),
        s.notifPreTitle(pre),
        r.text,
        r.id,
        idea: false,
        s: s,
      );
    }
  }

  /// Spreads open ideas over the free-time window for the coming days.
  /// Ideas shown least often come first, so all of them come back in turn.
  Future<void> rescheduleIdeas(List<Reminder> items, Settings settings) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Count slots that already fired since the last run.
    final previous = prefs.getString(_ideaSlotsKey);
    if (previous != null) {
      try {
        for (final e in (jsonDecode(previous) as List)) {
          final m = Map<String, dynamic>.from(e as Map);
          if (DateTime.parse(m['at'] as String).isBefore(now)) {
            for (final r in items) {
              if (r.id == m['id']) r.timesSurfaced++;
            }
          }
        }
      } catch (_) {}
    }

    for (var i = 0; i < _maxIdeaSlots; i++) {
      await _plugin.cancel(id: _ideaBaseId + i);
    }

    final ideas = items.where((r) => r.isIdea && !r.done).toList()
      ..sort((a, b) {
        final c = a.timesSurfaced.compareTo(b.timesSurfaced);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
    if (!settings.ideasEnabled || ideas.isEmpty) {
      await prefs.remove(_ideaSlotsKey);
      return;
    }

    var start = settings.freeStartMinutes;
    var end = settings.freeEndMinutes;
    if (end <= start) end = start + 60;
    final perDay = settings.ideasPerDay.clamp(1, 3);
    final days = (_maxIdeaSlots / perDay).floor().clamp(1, 7);
    final rnd = Random(now.day + now.month * 31);

    final slots = <Map<String, String>>[];
    var slot = 0;
    var ideaIndex = 0;
    for (var d = 0; d <= days && slot < _maxIdeaSlots; d++) {
      for (var k = 0; k < perDay && slot < _maxIdeaSlots; k++) {
        final span = (end - start) / perDay;
        final minuteOfDay = (start + span * k + rnd.nextDouble() * span * 0.8).round();
        final at = DateTime(now.year, now.month, now.day + d).add(Duration(minutes: minuteOfDay));
        if (!at.isAfter(now)) continue;
        final idea = ideas[ideaIndex % ideas.length];
        ideaIndex++;
        final s = S.of(ReminderParser.isArabic(idea.text) ? 'ar' : 'en');
        await _schedule(_ideaBaseId + slot, at, s.notifIdeaTitle, idea.text, idea.id, idea: true, s: s);
        slots.add({'id': idea.id, 'at': at.toIso8601String()});
        slot++;
      }
    }
    await prefs.setString(_ideaSlotsKey, jsonEncode(slots));
  }

  Future<void> rescheduleAll(List<Reminder> items, Settings settings) async {
    for (final r in items.where((r) => !r.isIdea)) {
      await scheduleTask(r, settings);
    }
    await rescheduleIdeas(items, settings);
  }

  Future<void> showTest() async {
    if (kIsWeb) return;
    final s = _s;
    await _plugin.show(
      id: 999999,
      title: s.notifTaskTitle,
      body: s.greeting,
      notificationDetails: _details(idea: false, s: s),
    );
  }
}
