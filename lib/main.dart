import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/models.dart';
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
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ThakkirniApp());
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
          home: store.settings.onboarded ? const HomeScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}
