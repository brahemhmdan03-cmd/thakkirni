import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/models.dart';
import 'core/parser.dart';
import 'core/store.dart';
import 'services/launch.dart';
import 'services/notifications.dart';
import 'ui/home.dart';
import 'ui/onboarding.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LaunchBridge.init();
  await AppStore.instance.load();
  await Notifications.instance.init();
  if (kIsWeb) await _seedPreview();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ThakkirniApp());
}

/// The browser preview starts with a few sample reminders so there is something to see.
Future<void> _seedPreview() async {
  final store = AppStore.instance;
  if (store.all.isNotEmpty) return;
  store.settings.listenOnOpen = false;
  final now = DateTime.now();
  DateTime at(int dayOffset, int h, [int m = 0]) => DateTime(now.year, now.month, now.day + dayOffset, h, m);
  final samples = [
    ParsedItem(title: 'اشتري خبز', kind: ItemKind.task, due: now.add(const Duration(minutes: 45))),
    ParsedItem(title: 'اروح اجيب الاولاد من المدرسة', kind: ItemKind.task, due: at(0, 16).isAfter(now) ? at(0, 16) : at(1, 16)),
    ParsedItem(title: 'موعد عند الدكتور', kind: ItemKind.task, due: at(1, 17)),
    ParsedItem(title: 'اتصل بأحمد', kind: ItemKind.task, due: at(1, 8, 30)),
    ParsedItem(title: 'تجديد الهوية', kind: ItemKind.task, due: at(4, 10)),
    ParsedItem(title: 'تطبيق للوصفات بيقترح أكلة من الموجود بالبراد', kind: ItemKind.idea),
    ParsedItem(title: 'محل قهوة متنقل جنب الجامعة', kind: ItemKind.idea),
    ParsedItem(title: 'قناة يوتيوب عن قصص المزارع', kind: ItemKind.idea),
  ];
  for (final p in samples) {
    await store.addParsed(p);
  }
}

class ThakkirniApp extends StatelessWidget {
  const ThakkirniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final lang = store.settings.appLanguage;
        return MaterialApp(
          title: 'ذكرني',
          debugShowCheckedModeBanner: false,
          theme: Brand.theme(Brightness.light),
          darkTheme: Brand.theme(Brightness.dark),
          locale: lang == AppLanguage.system ? null : Locale(lang.name),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: kIsWeb ? (context, child) => _PhoneFrame(child: child!) : null,
          home: store.settings.onboarded ? const HomeScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}

/// On a wide browser window, show the app inside a phone-sized frame.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) return child;
    final h = (size.height - 48).clamp(560.0, 880.0);
    return ColoredBox(
      color: const Color(0xFF0E0B22),
      child: Center(
        child: Container(
          width: h * 0.46,
          height: h,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(48),
            boxShadow: const [BoxShadow(color: Color(0x665B4CF5), blurRadius: 60)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(h * 0.46 - 20, h - 20),
                padding: const EdgeInsets.only(top: 24, bottom: 12),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
