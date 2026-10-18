import 'dart:async';

import 'package:flutter/services.dart';

/// Bridge to the native side: Siri ("ذكرني"), Android shortcuts and deep links
/// ask the app to open straight into listening.
class LaunchBridge {
  LaunchBridge._();

  static const _channel = MethodChannel('thakkirni/launch');
  static final _requests = StreamController<void>.broadcast();

  /// Fires when the native side asks to listen while the app is running.
  static Stream<void> get listenRequests => _requests.stream;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'listen') _requests.add(null);
      return null;
    });
  }

  /// True once if the app was opened by Siri, a shortcut or a link to listen.
  static Future<bool> consumeListenRequest() async {
    try {
      return await _channel.invokeMethod<bool>('consumeListenRequest') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
