import 'parser.dart';

/// All user-facing text, Arabic and English.
class S {
  const S(this.ar);
  final bool ar;

  static const arabic = S(true);
  static const english = S(false);
  static S of(String lang) => lang == 'ar' ? arabic : english;

  String _(String a, String e) => ar ? a : e;

  // ------------------------------------------------------------------ app
  String get appName => _('ذكرني', 'Thakkirni');
  String get tasks => _('المهام', 'Tasks');
  String get ideas => _('الأفكار', 'Ideas');
  String get done => _('المنجزة', 'Done');
  String get overdue => _('فاتت', 'Overdue');
  String get today => _('اليوم', 'Today');
  String get tomorrow => _('بكرة', 'Tomorrow');
  String get later => _('لاحقاً', 'Later');
  String get noTime => _('بدون وقت', 'No time');
  String get settings => _('الإعدادات', 'Settings');
  String get tapToTalk => _('اضغط واحكي', 'Tap and talk');
  String get typeInstead => _('اكتب بدل ما تحكي', 'Type instead');
  String get emptyTasks =>
      _('ما في مهام. احكي «ذكرني» وقلّي شو بدك.', 'No tasks yet. Say "Thakkirni" and tell me what you need.');
  String get emptyIdeas => _(
    'ما في أفكار محفوظة. لما تخطر لك فكرة، قلّي «عندي فكرة…».',
    'No ideas saved. When one comes to mind, say "I have an idea…".',
  );
  String get emptyDone => _('لسا ما خلصت شي اليوم 💪', 'Nothing done yet 💪');
  String get goodMorning => _('صباح الخير', 'Good morning');
  String get goodAfternoon => _('نهارك سعيد', 'Good afternoon');
  String get goodEvening => _('مساء الخير', 'Good evening');
  String tasksToday(int n) => ar
      ? (n == 0
            ? 'يومك فاضي'
            : n == 1
            ? 'عندك مهمة وحدة اليوم'
            : n == 2
            ? 'عندك مهمتين اليوم'
            : 'عندك $n مهام اليوم')
      : (n == 0
            ? 'Your day is free'
            : n == 1
            ? '1 task today'
            : '$n tasks today');
  String ideasCount(int n) => ar ? '$n أفكار' : '$n ideas';
  String get delete => _('حذف', 'Delete');
  String get save => _('حفظ', 'Save');
  String get cancel => _('إلغاء', 'Cancel');
  String get edit => _('تعديل', 'Edit');
  String get task => _('مهمة', 'Task');
  String get idea => _('فكرة', 'Idea');
  String get whatToRemind => _('شو بدك أذكرك؟', 'What should I remind you of?');
  String get typeHint => _('مثلاً: بكرة الساعة 8 الصبح اشتري خبز', 'e.g. buy bread tomorrow at 8 am');
  String get setTime => _('حدد الوقت', 'Set time');
  String get removeTime => _('بدون وقت', 'No time');
  String get undo => _('تراجع', 'Undo');
  String get deleted => _('انحذفت', 'Deleted');
  String get preview => _('رح أحفظ:', "I'll save:");
  String get listening => _('عم بسمعك…', 'Listening…');
  String get speaking => _('عم بحكي…', 'Speaking…');
  String get thinking => _('لحظة…', 'One moment…');
  String get doneTalking => _('خلصت', 'Done');
  String get tapMic => _('اضغط على المايك لتحكي', 'Tap the mic to talk');
  String get micDenied => _(
    'ما في إذن للمايك أو التعرف على الصوت. فعّله من إعدادات التلفون.',
    'Microphone or speech recognition is not allowed. Turn it on in phone Settings.',
  );

  // ------------------------------------------------------------- settings
  String get language => _('لغة التطبيق', 'App language');
  String get systemDefault => _('حسب التلفون', 'Phone default');
  String get speechLanguage => _('لغة الحكي', 'Speaking language');
  String get dialect => _('اللهجة', 'Dialect');
  String get listenOnOpen => _('اسمعني أول ما أفتح التطبيق', 'Listen as soon as I open the app');
  String get preAlert => _('نبهني قبل الموعد', 'Alert me before');
  String get atTimeOnly => _('بس على الوقت', 'Only on time');
  String minutes(int n) => ar ? '$n دقيقة' : '$n min';
  String get ideasSection => _('تذكير الأفكار', 'Idea reminders');
  String get ideasEnabled => _('ذكرني بأفكاري بأوقات فراغي', 'Bring my ideas back in my free time');
  String get freeFrom => _('وقت الفراغ من', 'Free time from');
  String get freeTo => _('لحد', 'Until');
  String get perDay => _('كم فكرة باليوم', 'Ideas per day');
  String get voiceSection => _('التشغيل بالصوت', 'Voice start');
  String get siriHelpIos => _(
    'قول «يا سيري، ذكرني» والتطبيق بيفتح وبيسألك شو بدك تذكرك فيه. ممكن كمان تحطه على زر الأكشن أو شاشة القفل من تطبيق الاختصارات.',
    'Say "Hey Siri, Thakkirni" and the app opens and asks what to remind you of. You can also put it on the Action Button or Lock Screen from the Shortcuts app.',
  );
  String get assistantHelpAndroid => _(
    'قول «Hey Google، افتح ذكرني» أو اضغط مطولاً على أيقونة التطبيق واختار «احكي». ممكن تحط الاختصار على الشاشة الرئيسية.',
    'Say "Hey Google, open Thakkirni" or long-press the app icon and pick "Talk". You can pin that shortcut to your home screen.',
  );
  String get wakeWordNote => _(
    'آبل وجوجل ما بيسمحوا لأي تطبيق يضل يسمع بالخلفية لكلمة خاصة، لهيك بنستخدم سيري ومساعد جوجل للتشغيل بالصوت.',
    'Apple and Google do not let apps listen in the background for a custom word, so voice start goes through Siri and Google Assistant.',
  );
  String get exactAlarms => _('اسمح بالتنبيهات بالدقيقة', 'Allow exact alarms');
  String get testNotification => _('جرّب تنبيه', 'Test notification');
  String get about => _('عن التطبيق', 'About');
  String get privacyNote => _('كل تذكيراتك محفوظة على تلفونك بس.', 'All your reminders stay on your phone.');

  // ------------------------------------------------------------ onboarding
  String get onboardTitle => _('أهلاً في ذكرني', 'Welcome to Thakkirni');
  String get onboardBody => _(
    'احكيلي مهامك ومواعيدك وأفكارك بصوتك، بالعربي أو بالإنجليزي، وأنا بذكرك فيها على وقتها، وبرجعلك أفكارك بأوقات فراغك.',
    'Tell me your tasks, appointments and ideas out loud, in Arabic or English. I remind you on time and bring your ideas back when you are free.',
  );
  String get onboardPermissions => _(
    'بحتاج إذن المايك والتعرف على الصوت والتنبيهات.',
    'I need the microphone, speech recognition and notifications.',
  );
  String get start => _('يلا نبلش', "Let's start");

  // ----------------------------------------------------------------- voice
  String get greeting => _('تفضّل، شو بدك أذكرك؟', 'Go ahead, what should I remind you of?');
  String get didntHear => _('ما سمعتك منيح، احكي كمان مرة.', "I didn't catch that, say it again.");
  String get anythingElse => _('بدك شي كمان؟', 'Anything else?');
  String get bye => _('تمام، بالتوفيق!', 'Alright, good luck!');
  String askTime(String title) =>
      ar ? 'إمتى بدك أذكرك بـ «$title»؟ أو قول «بدون وقت».' : 'When should I remind you to "$title"? Or say "no time".';
  String savedAsIdea(String title) => ar
      ? 'تمام، حفظت «$title» بدون وقت، ورح ضل أذكرك فيها بأوقات فراغك.'
      : 'Okay, I saved "$title" without a time and will bring it up in your free time.';
  String savedIdea(String title) => ar
      ? 'تمام، رح أحفظلك الفكرة، وضل أذكرك فيها بأوقات فراغك.'
      : "Great idea! I saved it and I'll bring it back in your free time.";
  String savedTask(String title, String when) =>
      ar ? 'تمام، رح أذكرك: $title، $when.' : "Done. I'll remind you: $title, $when.";
  String savedMany(int n) =>
      ar ? (n == 2 ? 'تمام، حفظتلك تذكيرين.' : 'تمام، حفظتلك $n تذكيرات.') : 'Done, I saved $n reminders.';

  // ---------------------------------------------------------- notifications
  String get notifTaskTitle => _('ذكرني ⏰', 'Thakkirni ⏰');
  String notifPreTitle(int min) => ar ? 'بعد $min دقيقة ⏳' : 'In $min minutes ⏳';
  String get notifIdeaTitle => _('💡 فكرة من أفكارك', '💡 One of your ideas');
  String get actionDone => _('تم ✓', 'Done ✓');
  String get actionSnooze => _('أجّل 10 دقائق', 'Snooze 10 min');
  String get channelTasks => _('المهام والمواعيد', 'Tasks & appointments');
  String get channelIdeas => _('الأفكار', 'Ideas');

  // ----------------------------------------------------------------- dates
  static const _arDays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const _enDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _arMonths = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];
  static const _enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String weekday(DateTime d) => (ar ? _arDays : _enDays)[d.weekday - 1];
  String dateLong(DateTime d) =>
      ar ? '${weekday(d)} ${d.day} ${_arMonths[d.month - 1]}' : '${weekday(d)}, ${_enMonths[d.month - 1]} ${d.day}';

  String dayLabel(DateTime d, DateTime now) {
    final days = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return today;
    if (days == 1) return tomorrow;
    if (days == -1) return _('مبارح', 'Yesterday');
    if (days > 1 && days < 7) return weekday(d);
    return ar ? '${d.day}/${d.month}' : '${_enMonths[d.month - 1]} ${d.day}';
  }

  String clock(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    if (ar) {
      final p = d.hour < 5
          ? 'بالليل'
          : d.hour < 12
          ? 'الصبح'
          : d.hour < 15
          ? 'الظهر'
          : d.hour < 18
          ? 'العصر'
          : d.hour < 21
          ? 'المسا'
          : 'بالليل';
      return '$h12:$mm $p';
    }
    return '$h12:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "بكرة الساعة 8:00 الصبح" / "tomorrow at 8:00 AM".
  String when(DateTime d, DateTime now) {
    final day = dayLabel(d, now);
    return ar
        ? '$day الساعة ${clock(d)}'
        : '${day == today || day == tomorrow ? day.toLowerCase() : day} at ${clock(d)}';
  }

  /// Short spoken summary for one saved item.
  String confirmation(ParsedItem item, DateTime now) => item.kind == ItemKind.idea
      ? savedIdea(item.title)
      : item.due == null
      ? savedAsIdea(item.title)
      : savedTask(item.title, when(item.due!, now));
}
