import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/store.dart';
import '../core/strings.dart';
import '../features/conversation.dart';
import 'theme.dart';

class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> with SingleTickerProviderStateMixin {
  late final Conversation convo = Conversation(lang: AppStore.instance.settings.speechLanguage);
  late final _wave = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    convo.addListener(_autoScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => convo.start());
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    convo.removeListener(_autoScroll);
    convo.dispose();
    _wave.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _setLang(String lang) async {
    if (lang == convo.lang) return;
    final store = AppStore.instance;
    store.settings.speechLanguage = lang;
    store.saveSettings();
    await convo.switchLanguage(lang);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: convo,
      builder: (context, _) {
        final s = S.of(convo.lang);
        final textDir = convo.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Brand.night1.withValues(alpha: 0.97), Brand.night2.withValues(alpha: 0.97)],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          _LangToggle(lang: convo.lang, onChanged: _setLang),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Orb(animation: _wave, level: convo.level, state: convo.state),
                    const SizedBox(height: 14),
                    Text(switch (convo.state) {
                      ConversationState.listening => s.listening,
                      ConversationState.speaking => s.speaking,
                      ConversationState.thinking => s.thinking,
                      ConversationState.denied => '',
                      ConversationState.idle => s.tapMic,
                    }, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Directionality(
                        textDirection: textDir,
                        child: ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                          children: [
                            for (final b in convo.bubbles) _BubbleView(bubble: b),
                            if (convo.partial.isNotEmpty)
                              _BubbleView(bubble: Bubble(Speaker.user, convo.partial), live: true),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18, top: 4),
                      child: _ActionButton(convo: convo),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.lang, required this.onChanged});
  final String lang;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String code, String label) {
      final on = lang == code;
      return GestureDetector(
        onTap: () => onChanged(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(color: on ? Brand.night1 : Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisSize: MainAxisSize.min, children: [chip('ar', 'عربي'), chip('en', 'EN')]),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.animation, required this.level, required this.state});
  final Animation<double> animation;
  final double level;
  final ConversationState state;

  @override
  Widget build(BuildContext context) {
    // Sound level arrives in dB, roughly -2..10 on Android and -50..0 on iOS.
    final norm = level > 0 ? (level / 10).clamp(0.0, 1.0) : ((level + 50) / 50).clamp(0.0, 1.0) * 0.6;
    final active = state == ConversationState.listening;
    final speaking = state == ConversationState.speaking;
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value * 2 * pi;
          final breathe = speaking ? 0.06 * sin(t * 3) : 0.03 * sin(t);
          final boost = active ? norm * 0.25 : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.scale(
                  scale: 1 + breathe + boost + i * 0.12 + 0.04 * sin(t + i),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (i.isEven ? Brand.teal : Brand.violet).withValues(alpha: 0.16 - i * 0.04),
                    ),
                  ),
                ),
              AnimatedScale(
                scale: 1 + boost * 0.6,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      transform: GradientRotation(t),
                      colors: const [Brand.violet, Brand.teal, Color(0xFF8C7BFF), Brand.violet],
                    ),
                    boxShadow: [BoxShadow(color: Brand.teal.withValues(alpha: 0.5), blurRadius: 40 + 30 * boost)],
                  ),
                  child: Icon(speaking ? Icons.graphic_eq_rounded : Icons.mic_rounded, color: Colors.white, size: 48),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BubbleView extends StatelessWidget {
  const _BubbleView({required this.bubble, this.live = false});
  final Bubble bubble;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final mine = bubble.speaker == Speaker.user;
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: mine ? null : Brand.gradient,
          color: mine ? Colors.white.withValues(alpha: live ? 0.08 : 0.14) : null,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(20),
            topEnd: const Radius.circular(20),
            bottomStart: Radius.circular(mine ? 20 : 6),
            bottomEnd: Radius.circular(mine ? 6 : 20),
          ),
        ),
        child: Text(
          bubble.text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: live ? 0.75 : 1),
            fontSize: 16,
            height: 1.45,
            fontStyle: live ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.convo});
  final Conversation convo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(convo.lang);
    final (IconData icon, String label, VoidCallback? onTap) = switch (convo.state) {
      ConversationState.listening => (Icons.stop_rounded, s.doneTalking, () => convo.stopListeningNow()),
      ConversationState.speaking => (Icons.skip_next_rounded, '', () => convo.skipSpeaking()),
      ConversationState.thinking => (Icons.hourglass_top_rounded, '', null),
      ConversationState.idle ||
      ConversationState.denied => (Icons.mic_rounded, s.tapToTalk, () => convo.start(greet: convo.bubbles.isEmpty)),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: Brand.night1, size: 30),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ],
    );
  }
}
