import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/platform.dart';

/// Microphone in, voice out. One shared instance for the whole app.
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  final _stt = SpeechToText();
  final _tts = FlutterTts();
  bool _sttReady = false;
  bool _ttsReady = false;
  List<LocaleName> _locales = [];

  Completer<String>? _listening;
  String _lastWords = '';
  Timer? _safety;

  /// Arabic dialects the phone can recognize, e.g. ar_JO, ar_SA.
  List<LocaleName> get arabicLocales => _locales.where((l) => l.localeId.toLowerCase().startsWith('ar')).toList();

  /// Starts speech recognition; the first call shows the system permission prompts.
  Future<bool> initSpeech() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize(onStatus: _onStatus, onError: _onError);
      if (_sttReady) _locales = await _stt.locales();
    } catch (_) {
      _sttReady = false;
    }
    return _sttReady;
  }

  Future<void> _initTts() async {
    if (_ttsReady) return;
    await _tts.awaitSpeakCompletion(true);
    if (isIOS) await _tts.setSharedInstance(true);
    _ttsReady = true;
  }

  /// Picks the recognizer locale id for 'ar' or 'en'.
  String localeFor(String lang, {String? preferredArabic}) {
    // Browsers take BCP 47 tags and do not list their languages.
    if (kIsWeb) return lang == 'ar' ? 'ar-SA' : 'en-US';
    String norm(String s) => s.replaceAll('-', '_').toLowerCase();
    final ids = _locales.map((l) => l.localeId).toList();
    String? find(List<String> wanted) {
      for (final w in wanted) {
        for (final id in ids) {
          if (norm(id) == norm(w)) return id;
        }
      }
      return null;
    }

    if (lang == 'ar') {
      return find([?preferredArabic, 'ar_JO', 'ar_SA', 'ar_AE', 'ar_EG']) ??
          ids.firstWhere((id) => norm(id).startsWith('ar'), orElse: () => 'ar_SA');
    }
    return find(['en_US', 'en_GB']) ?? ids.firstWhere((id) => norm(id).startsWith('en'), orElse: () => 'en_US');
  }

  /// Listens until the person stops talking and returns what they said ('' if nothing).
  Future<String> listen({
    required String localeId,
    void Function(String words)? onPartial,
    void Function(double level)? onLevel,
  }) async {
    if (!await initSpeech()) return '';
    await stopSpeaking();
    if (_stt.isListening) await _stt.cancel();

    _lastWords = '';
    final done = Completer<String>();
    _listening = done;
    _safety?.cancel();
    _safety = Timer(const Duration(seconds: 45), () => _finish());

    try {
      await _stt.listen(
        onResult: (r) {
          _lastWords = r.recognizedWords;
          onPartial?.call(_lastWords);
          if (r.finalResult) _finish();
        },
        onSoundLevelChange: onLevel,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      _finish();
    }
    return done.future;
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus) {
      _finish();
    } else if (status == SpeechToText.notListeningStatus) {
      // The final result usually follows right after; give it a moment,
      // but never end a newer listening session.
      final current = _listening;
      Timer(const Duration(milliseconds: 1200), () {
        if (identical(_listening, current)) _finish();
      });
    }
  }

  void _onError(SpeechRecognitionError e) => _finish();

  void _finish() {
    _safety?.cancel();
    final c = _listening;
    if (c != null && !c.isCompleted) {
      _listening = null;
      c.complete(_lastWords.trim());
    }
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
    _finish();
  }

  Future<void> cancelListening() async {
    _lastWords = '';
    if (_stt.isListening) await _stt.cancel();
    _finish();
  }

  /// Speaks and waits until finished.
  Future<void> speak(String text, String lang) async {
    await _initTts();
    if (isIOS) {
      // The recognizer leaves the session in record mode; route speech to the loudspeaker.
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playAndRecord, [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      ], IosTextToSpeechAudioMode.voicePrompt);
    }
    await _tts.setLanguage(lang == 'ar' ? 'ar-SA' : 'en-US');
    await _tts.setSpeechRate(isIOS ? 0.5 : 0.95);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    if (_ttsReady) await _tts.stop();
  }
}
