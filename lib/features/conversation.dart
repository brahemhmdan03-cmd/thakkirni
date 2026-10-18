import 'package:flutter/foundation.dart';

import '../core/parser.dart';
import '../core/store.dart';
import '../core/strings.dart';
import '../services/voice.dart';

enum Speaker { app, user }

class Bubble {
  Bubble(this.speaker, this.text);
  final Speaker speaker;
  final String text;
}

enum ConversationState { idle, speaking, listening, thinking, denied }

/// The spoken back-and-forth: "شو بدك أذكرك؟" → user → confirmation → "بدك شي كمان؟".
class Conversation extends ChangeNotifier {
  Conversation({required this.lang});

  /// 'ar' or 'en'.
  String lang;

  final bubbles = <Bubble>[];
  ConversationState state = ConversationState.idle;
  String partial = '';
  double level = 0;
  int savedCount = 0;

  bool _running = false;
  bool _disposed = false;
  int _session = 0;

  final _voice = Voice.instance;
  final _store = AppStore.instance;

  S get s => S.of(lang);

  void _set(ConversationState st) {
    state = st;
    if (!_disposed) notifyListeners();
  }

  void _say(String text) {
    bubbles.add(Bubble(Speaker.app, text));
    if (!_disposed) notifyListeners();
  }

  Future<void> _speak(String text, int session) async {
    if (session != _session) return;
    _say(text);
    _set(ConversationState.speaking);
    await _voice.speak(text, lang);
  }

  Future<String> _hear(int session) async {
    if (session != _session) return '';
    partial = '';
    _set(ConversationState.listening);
    final locale = _voice.localeFor(lang, preferredArabic: _store.settings.arabicLocaleId);
    final words = await _voice.listen(
      localeId: locale,
      onPartial: (w) {
        partial = w;
        if (!_disposed) notifyListeners();
      },
      onLevel: (l) {
        level = l;
        if (!_disposed) notifyListeners();
      },
    );
    level = 0;
    partial = '';
    if (session != _session) return '';
    if (words.isNotEmpty) bubbles.add(Bubble(Speaker.user, words));
    _set(ConversationState.thinking);
    return words;
  }

  /// Runs the whole conversation. Safe to call again after it ends.
  Future<void> start({bool greet = true}) async {
    if (_running) return;
    _running = true;
    final session = ++_session;
    try {
      if (!await _voice.initSpeech()) {
        _say(s.micDenied);
        _set(ConversationState.denied);
        return;
      }
      if (greet) await _speak(s.greeting, session);

      var misses = 0;
      for (var turn = 0; turn < 8 && session == _session; turn++) {
        final heard = await _hear(session);
        if (session != _session) return;
        if (heard.isEmpty) {
          if (++misses >= 2 || turn > 0) break;
          await _speak(s.didntHear, session);
          continue;
        }
        if (ReminderParser.isNegative(heard)) {
          await _speak(s.bye, session);
          break;
        }
        await handleText(heard, session: session);
        if (session != _session) return;
        await _speak(s.anythingElse, session);
      }
    } finally {
      if (session == _session) {
        _running = false;
        _set(ConversationState.idle);
      }
    }
  }

  /// Parses, asks for a missing time, saves and confirms.
  Future<void> handleText(String text, {required int session}) async {
    final now = DateTime.now();
    final items = ReminderParser.parse(text, now: now);
    if (items.isEmpty) {
      await _speak(s.didntHear, session);
      return;
    }

    for (final item in items) {
      if (!item.needsTime) continue;
      await _speak(s.askTime(item.title), session);
      final answer = await _hear(session);
      if (session != _session) return;
      if (answer.isEmpty || ReminderParser.isNoTime(answer)) continue;
      final t = ReminderParser.parseOne(answer, now: DateTime.now());
      if (t.due != null) {
        item
          ..due = t.due
          ..hasTime = true;
      }
    }

    for (final item in items) {
      await _store.addParsed(item);
    }
    savedCount += items.length;

    if (items.length == 1) {
      await _speak(s.confirmation(items.first, now), session);
    } else {
      final lines = [s.savedMany(items.length)];
      for (final i in items) {
        lines.add(i.due == null ? '• ${i.title}' : '• ${i.title}${s.ar ? '، ' : ', '}${s.when(i.due!, now)}');
      }
      await _speak(lines.join('\n'), session);
    }
  }

  /// Switch language and start listening again.
  Future<void> switchLanguage(String newLang) async {
    await stop();
    lang = newLang;
    notifyListeners();
    await start();
  }

  /// The person tapped "done talking".
  Future<void> stopListeningNow() => _voice.stopListening();

  Future<void> skipSpeaking() => _voice.stopSpeaking();

  Future<void> stop() async {
    _session++;
    _running = false;
    await _voice.cancelListening();
    await _voice.stopSpeaking();
    _set(ConversationState.idle);
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _voice.cancelListening();
    _voice.stopSpeaking();
    super.dispose();
  }
}
