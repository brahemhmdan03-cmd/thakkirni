import 'package:flutter/foundation.dart';

// dart:io's Platform throws on the web preview, so platform checks go through here.
bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
