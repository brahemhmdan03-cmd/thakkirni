import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notifications.dart';
import 'models.dart';
import 'parser.dart';
import 'strings.dart';

/// Holds reminders and settings, persists them, and keeps notifications in sync.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const _remindersKey = 'reminders_v1';
  static const _settingsKey = 'settings_v1';
  static const _nextIdKey = 'next_notification_id';

  late SharedPreferences _prefs;
  final List<Reminder> _items = [];
  Settings settings = Settings();

  List<Reminder> get all => List.unmodifiable(_items);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_remindersKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _items
          ..clear()
          ..addAll(list.map((e) => Reminder.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {
        // Corrupt data should never block the app from opening.
      }
    }
    final s = _prefs.getString(_settingsKey);
    if (s != null) {
      try {
        settings = Settings.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
      } catch (_) {}
    }
  }

  /// UI language actually in use.
  bool isArabicUi(Locale deviceLocale) => switch (settings.appLanguage) {
    AppLanguage.ar => true,
    AppLanguage.en => false,
    AppLanguage.system => deviceLocale.languageCode == 'ar',
  };

  S strings(Locale deviceLocale) => isArabicUi(deviceLocale) ? S.arabic : S.english;

  Future<void> _persist() async {
    await _prefs.setString(_remindersKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
    await Notifications.instance.rescheduleAll(_items, settings);
  }

  int _nextNotificationId() {
    // Even numbers; +1 is the pre-alert. Idea slots live above 1,000,000.
    final id = _prefs.getInt(_nextIdKey) ?? 2;
    _prefs.setInt(_nextIdKey, id >= 999998 ? 2 : id + 2);
    return id;
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}';

  // -------------------------------------------------------------- queries

  List<Reminder> get openTasks => _items.where((r) => !r.isIdea && !r.done).toList()
    ..sort((a, b) {
      if (a.due == null && b.due == null) return b.createdAt.compareTo(a.createdAt);
      if (a.due == null) return 1;
      if (b.due == null) return -1;
      return a.due!.compareTo(b.due!);
    });

  List<Reminder> get ideas =>
      _items.where((r) => r.isIdea && !r.done).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Reminder> get finished =>
      _items.where((r) => r.done).toList()..sort((a, b) => (b.due ?? b.createdAt).compareTo(a.due ?? a.createdAt));

  int tasksOn(DateTime day) => openTasks
      .where((r) => r.due != null && r.due!.year == day.year && r.due!.month == day.month && r.due!.day == day.day)
      .length;

  Reminder? byId(String id) {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ------------------------------------------------------------ mutations

  Future<Reminder> addParsed(ParsedItem p) async {
    final r = Reminder(
      id: _newId(),
      text: p.title,
      kind: p.due == null ? ItemKind.idea : p.kind,
      due: p.due,
      createdAt: DateTime.now(),
      notificationId: _nextNotificationId(),
    );
    _items.add(r);
    await _persist();
    await _sync(r);
    return r;
  }

  Future<void> update(Reminder r) async {
    if (!_items.contains(r)) _items.add(r);
    await _persist();
    await _sync(r);
  }

  Future<void> toggleDone(Reminder r) async {
    r.done = !r.done;
    await update(r);
  }

  Future<void> snooze(Reminder r, Duration by) async {
    r
      ..due = DateTime.now().add(by)
      ..done = false;
    await update(r);
  }

  Future<void> delete(Reminder r) async {
    _items.remove(r);
    await _persist();
    await Notifications.instance.cancelFor(r);
    if (r.isIdea) await Notifications.instance.rescheduleIdeas(_items, settings);
  }

  /// Puts a deleted reminder back (undo).
  Future<void> restore(Reminder r) => update(r);

  Future<void> _sync(Reminder r) async {
    final n = Notifications.instance;
    if (r.isIdea) {
      await n.cancelFor(r);
      await n.rescheduleIdeas(_items, settings);
    } else {
      await n.scheduleTask(r, settings);
    }
  }

  /// Called when the app comes to the front: refresh idea slots.
  Future<void> refreshSchedules() async {
    await Notifications.instance.rescheduleAll(_items, settings);
    await _persist(); // keeps the updated idea rotation counts
  }
}
