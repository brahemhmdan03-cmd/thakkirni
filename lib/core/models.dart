import 'parser.dart';

class Reminder {
  Reminder({
    required this.id,
    required this.text,
    required this.kind,
    required this.createdAt,
    required this.notificationId,
    this.due,
    this.done = false,
    this.timesSurfaced = 0,
  });

  final String id;
  String text;
  ItemKind kind;
  DateTime? due;
  final DateTime createdAt;
  bool done;

  /// Base id for local notifications (the pre-alert uses id + 1).
  final int notificationId;

  /// How many times an idea was brought back; the least surfaced go first.
  int timesSurfaced;

  bool get isIdea => kind == ItemKind.idea;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'kind': kind.name,
    'due': due?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'done': done,
    'notificationId': notificationId,
    'timesSurfaced': timesSurfaced,
  };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
    id: j['id'] as String,
    text: j['text'] as String,
    kind: ItemKind.values.byName(j['kind'] as String? ?? 'task'),
    due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
    done: j['done'] as bool? ?? false,
    notificationId: j['notificationId'] as int,
    timesSurfaced: j['timesSurfaced'] as int? ?? 0,
  );
}

enum AppLanguage { system, ar, en }

class Settings {
  Settings({
    this.appLanguage = AppLanguage.system,
    this.speechLanguage = 'ar',
    this.arabicLocaleId,
    this.listenOnOpen = true,
    this.preAlertMinutes = 10,
    this.ideasEnabled = true,
    this.freeStartMinutes = 20 * 60,
    this.freeEndMinutes = 22 * 60,
    this.ideasPerDay = 1,
    this.onboarded = false,
  });

  AppLanguage appLanguage;

  /// 'ar' or 'en': which language the microphone listens in.
  String speechLanguage;

  /// Dialect picked from the device's recognizer list, e.g. ar_JO, ar_SA.
  String? arabicLocaleId;

  /// Open straight into listening when the app is opened.
  bool listenOnOpen;

  /// Extra alert before a task; 0 turns it off.
  int preAlertMinutes;

  bool ideasEnabled;

  /// Free-time window, in minutes after midnight.
  int freeStartMinutes;
  int freeEndMinutes;
  int ideasPerDay;
  bool onboarded;

  Map<String, dynamic> toJson() => {
    'appLanguage': appLanguage.name,
    'speechLanguage': speechLanguage,
    'arabicLocaleId': arabicLocaleId,
    'listenOnOpen': listenOnOpen,
    'preAlertMinutes': preAlertMinutes,
    'ideasEnabled': ideasEnabled,
    'freeStartMinutes': freeStartMinutes,
    'freeEndMinutes': freeEndMinutes,
    'ideasPerDay': ideasPerDay,
    'onboarded': onboarded,
  };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
    appLanguage: AppLanguage.values.byName(j['appLanguage'] as String? ?? 'system'),
    speechLanguage: j['speechLanguage'] as String? ?? 'ar',
    arabicLocaleId: j['arabicLocaleId'] as String?,
    listenOnOpen: j['listenOnOpen'] as bool? ?? true,
    preAlertMinutes: j['preAlertMinutes'] as int? ?? 10,
    ideasEnabled: j['ideasEnabled'] as bool? ?? true,
    freeStartMinutes: j['freeStartMinutes'] as int? ?? 20 * 60,
    freeEndMinutes: j['freeEndMinutes'] as int? ?? 22 * 60,
    ideasPerDay: j['ideasPerDay'] as int? ?? 1,
    onboarded: j['onboarded'] as bool? ?? false,
  );
}
