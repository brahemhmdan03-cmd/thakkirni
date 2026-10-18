# ذكرني · Thakkirni

تطبيق تذكير بالصوت للآيفون والأندرويد (Flutter، كود واحد للنظامين). بتحكيله مهامك ومواعيدك وأفكارك بالعربي أو بالإنجليزي، وهو بيذكرك فيها على وقتها، وبيرجعلك أفكارك بأوقات فراغك.

## شو بيعمل

| | |
|---|---|
| 🎙️ محادثة صوتية | بيقلك «تفضّل، شو بدك أذكرك؟» وبيسمعك، وبيرد عليك بالصوت، وبيسألك «بدك شي كمان؟» |
| 🧠 فهم الوقت | «الساعة 8 الصبح»، «على الساعة 4» (بيفهمها العصر)، «تمانية ونص»، «تلاتة إلا ربع»، «بكرة»، «يوم الخميس»، «بعد ساعة ونص»، «بعد 10 دقايق»، «الليلة»، و«at 6:30 pm»، «tomorrow»، «in 20 minutes» |
| 📋 كذا مهمة بجملة وحدة | «لازم أشتري خبز الساعة 8 الصبح ولازم الساعة 4 أجيب الأولاد وعندي الساعة 5 موعد» ← 3 تذكيرات |
| ❓ بيسأل عن الوقت | إذا ما حكيت وقت، بيسألك «إمتى بدك أذكرك؟» أو بتقول «بدون وقت» |
| 💡 الأفكار | «عندي فكرة…» بتنحفظ بقسم الأفكار، وبيذكرك فيها بالتناوب بأوقات فراغك (افتراضياً 8–10 المسا، بتتغير من الإعدادات) |
| 🔔 تنبيهات | على الوقت + تنبيه قبل (10 دقائق افتراضياً)، مع زر «تم ✓» و«أجّل 10 دقائق» |
| 🗣️ تشغيل بالصوت | آيفون: «يا سيري، ذكرني». أندرويد: «Hey Google, open ذكرني» أو اختصار «احكي» من الضغط المطوّل على الأيقونة |
| 🌙 | عربي/إنجليزي مع اتجاه يمين لليسار، وضع ليلي، كل البيانات على التلفون |

> **ليش مش «ذكرني» لحالها بدون سيري؟** آبل وجوجل ما بيسمحوا لأي تطبيق يضل يسمع بالخلفية لكلمة تشغيل خاصة فيه (هاد محجوز لسيري ومساعد جوجل). لهيك أقرب طريقة حقيقية: «يا سيري، ذكرني» بتفتح التطبيق وهو بيبلّش يسمعك فوراً. وكمان خيار «اسمعني أول ما أفتح التطبيق» مفعّل افتراضياً، فأول ما تفتحه بيسألك شو بدك.

## هيكل المشروع

```
lib/
  core/parser.dart        فهم الجمل والأوقات بالعربي والإنجليزي
  core/store.dart         حفظ التذكيرات والإعدادات
  core/strings.dart       كل النصوص (عربي/إنجليزي) والرد الصوتي
  features/conversation.dart  المحادثة الصوتية
  services/voice.dart     التعرف على الكلام + النطق
  services/notifications.dart  التنبيهات وجدولة الأفكار
  ui/                     الشاشات
ios/Runner/AppDelegate.swift   أمر سيري «ذكرني» (App Intents)
android/.../MainActivity.kt    اختصار «احكي» وفتح الاستماع
test/parser_test.dart     26 اختبار لفهم الجمل
```

## التشغيل على جهازك

1. نزّل Flutter: https://docs.flutter.dev/get-started/install (على ماك لو بدك آيفون، لأنه بناء الآيفون بيحتاج Xcode).
2. بمجلد المشروع:
   ```bash
   flutter pub get
   flutter test          # يتأكد إنه فهم الجمل شغال
   flutter run           # والتلفون موصول بالكمبيوتر
   ```
3. **أندرويد بس:** `flutter build apk --release` وبيطلع الملف `build/app/outputs/flutter-apk/app-release.apk` بتنزّله على أي تلفون أندرويد.

> ملاحظة: التعرف على الكلام ما بيشتغل على المحاكي منيح، جرّب على تلفون حقيقي.

## النشر على App Store (آيفون)

بتحتاج: جهاز ماك عليه Xcode، وحساب **Apple Developer** (‏99$ بالسنة) من https://developer.apple.com/programs/

1. افتح `ios/Runner.xcworkspace` بـ Xcode.
2. Runner ← Signing & Capabilities: اختار الـ Team تبعك، وغيّر **Bundle Identifier** لشي خاص فيك مثل `com.brahem.thakkirni`.
3. على https://appstoreconnect.apple.com ← My Apps ← «+» ← New App: الاسم «ذكرني»، اللغة الأساسية العربية، ونفس الـ Bundle ID.
4. بالترمينال: `flutter build ipa --release`
5. افتح `build/ios/archive/Runner.xcarchive` بـ Xcode (أو استخدم تطبيق Transporter) واضغط **Distribute App ← App Store Connect**.
6. بـ App Store Connect عبّي: الوصف، الكلمات المفتاحية، صور الشاشة (6.7 إنش و 6.5 إنش)، رابط سياسة الخصوصية (ارفع `PRIVACY.md` على أي صفحة ويب، مثلاً GitHub Pages أو Notion)، وبقسم App Privacy اختار «Data Not Collected».
7. جرّب عن طريق **TestFlight** أول، وبعدين **Submit for Review**. المراجعة عادة يوم أو يومين.

## النشر على Google Play (أندرويد)

بتحتاج حساب **Google Play Console** (‏25$ مرة وحدة) من https://play.google.com/console

1. غيّر `applicationId` و `namespace` بـ `android/app/build.gradle.kts` لاسم خاص فيك (مثل `com.brahem.thakkirni`)، وانقل `MainActivity.kt` لنفس المسار، وعدّل `targetPackage`/`targetClass` بـ `android/app/src/main/res/xml/shortcuts.xml`.
2. اعمل مفتاح توقيع (مرة وحدة، واحفظه منيح):
   ```bash
   keytool -genkey -v -keystore ~/thakkirni-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. اعمل ملف `android/key.properties`:
   ```
   storePassword=كلمة السر
   keyPassword=كلمة السر
   keyAlias=upload
   storeFile=/المسار/الكامل/thakkirni-upload.jks
   ```
4. `flutter build appbundle --release` ← ارفع `build/app/outputs/bundle/release/app-release.aab` على Play Console.
5. عبّي صفحة المتجر، Data safety («لا يتم جمع بيانات»)، ورابط سياسة الخصوصية. التطبيق بيطلب إذن **Exact alarms** لأنه تطبيق تذكير، وبتصرّح عنه بقسم App content.

## البناء التلقائي على GitHub

إذا رفعت المشروع على GitHub، الملف `.github/workflows/build.yml` بيشغّل الاختبارات وبيبني ملف APK للأندرويد تلقائياً (بتلاقيه بـ Actions ← Artifacts)، وبيتأكد إنه نسخة الآيفون بتنبني.
