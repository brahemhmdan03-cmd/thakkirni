import 'package:flutter/material.dart';

import '../core/store.dart';
import '../services/notifications.dart';
import '../services/voice.dart';
import 'theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final store = AppStore.instance;
    store.settings.speechLanguage = Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
    await Voice.instance.initSpeech();
    await Notifications.instance.requestPermissions();
    store.settings.onboarded = true;
    await store.saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Brand.night1, Brand.night2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: Brand.gradient,
                    boxShadow: [BoxShadow(color: Brand.teal.withValues(alpha: 0.5), blurRadius: 50)],
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 36),
                Text(
                  s.onboardTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text(
                  s.onboardBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 28),
                for (final (icon, text) in [
                  (Icons.mic_rounded, s.ar ? '«بكرة الساعة 8 الصبح اشتري خبز»' : '"Buy bread tomorrow at 8 am"'),
                  (
                    Icons.lightbulb_rounded,
                    s.ar ? '«عندي فكرة: محل قهوة متنقل»' : '"I have an idea: a mobile coffee cart"',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(icon, color: Brand.teal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  s.onboardPermissions,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _start,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Brand.night1,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    child: Text(s.start),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
