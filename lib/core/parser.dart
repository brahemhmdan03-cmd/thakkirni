// Understands spoken reminders in Arabic (Levantine/Gulf/MSA) and English.
//
// Example inputs:
//   "لازم اشتري علي الساعه 8 الصبح خبز"
//   "بكرة الساعة 4 اروح اجيب الاولاد وكمان الساعة 5 عندي موعد"
//   "عندي فكرة: تطبيق للوصفات"
//   "remind me to call mom tomorrow at 6:30 pm"
//
// Matching runs on a normalized copy of the text that has exactly the same
// length as the original, so every match range can be cut out of the original
// text to leave a clean title.

enum ItemKind { task, idea }

class ParsedItem {
  ParsedItem({required this.title, required this.kind, this.due, this.dayOffset, this.hasTime = false});

  String title;
  ItemKind kind;
  DateTime? due;

  /// Days from today when the user named a day ("بكرة", "monday").
  int? dayOffset;

  /// True when an hour, period or relative time was found.
  bool hasTime;

  bool get needsTime => kind == ItemKind.task && due == null;

  @override
  String toString() => 'ParsedItem($kind, "$title", $due)';
}

enum _Period { dawn, morning, noon, afternoon, evening, night }

class ReminderParser {
  ReminderParser._();

  // Letter boundaries that also work for Arabic (Dart's \b is ASCII only).
  static const _b = r'(?<![\p{L}\p{N}])';
  static const _e = r'(?![\p{L}\p{N}])';

  static RegExp _re(String p) => RegExp(p, unicode: true, caseSensitive: false);

  // ---------------------------------------------------------------- numbers

  static const Map<String, int> _arNumberWords = {
    'الحاديه عشر': 11,
    'الحادي عشر': 11,
    'احدي عشر': 11,
    'احد عشر': 11,
    'احدعش': 11,
    'حداعش': 11,
    'حدعش': 11,
    'احداعش': 11,
    'الثانيه عشر': 12,
    'اثنا عشر': 12,
    'اثني عشر': 12,
    'اثنعش': 12,
    'اتنعش': 12,
    'اتناعش': 12,
    'ثنعش': 12,
    'طنعش': 12,
    'اطنعش': 12,
    'واحده': 1,
    'وحده': 1,
    'الواحده': 1,
    'واحد': 1,
    'اثنين': 2,
    'اتنين': 2,
    'ثنتين': 2,
    'الثانيه': 2,
    'تنتين': 2,
    'ثلاثه': 3,
    'تلاته': 3,
    'ثلاث': 3,
    'تلات': 3,
    'الثالثه': 3,
    'اربعه': 4,
    'اربع': 4,
    'الرابعه': 4,
    'خمسه': 5,
    'خمس': 5,
    'الخامسه': 5,
    'سته': 6,
    'ست': 6,
    'السادسه': 6,
    'سبعه': 7,
    'سبع': 7,
    'السابعه': 7,
    'ثمانيه': 8,
    'تمانيه': 8,
    'ثمان': 8,
    'تمان': 8,
    'تمنه': 8,
    'ثمنه': 8,
    'الثامنه': 8,
    'تسعه': 9,
    'تسع': 9,
    'التاسعه': 9,
    'عشره': 10,
    'عشر': 10,
    'العاشره': 10,
    'عشرين': 20,
    'ثلاثين': 30,
    'تلاتين': 30,
    'اربعين': 40,
    'خمسين': 50,
  };

  static const Map<String, int> _enNumberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'fifteen': 15,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'forty five': 45,
    'fifty': 50,
    'a': 1,
    'an': 1,
  };

  static String _alt(Iterable<String> words) {
    final list = words.toList()..sort((a, b) => b.length.compareTo(a.length));
    return list.map(RegExp.escape).join('|');
  }

  static final String _arNum = _alt(_arNumberWords.keys);
  static final String _enNum = _alt(_enNumberWords.keys.where((w) => w != 'a' && w != 'an'));

  static int? _number(String? s) {
    if (s == null) return null;
    final t = s.trim().toLowerCase();
    return int.tryParse(t) ?? _arNumberWords[t] ?? _enNumberWords[t];
  }

  // ---------------------------------------------------------- normalization

  /// Same-length normalization: Arabic-Indic digits to ASCII, alef/teh
  /// marbuta/alef maqsura variants unified, Latin letters lowercased.
  static String normalize(String s) {
    final out = List<int>.of(s.codeUnits);
    for (var i = 0; i < out.length; i++) {
      final c = out[i];
      if (c >= 0x0660 && c <= 0x0669) {
        out[i] = 0x30 + c - 0x0660;
      } else if (c >= 0x06F0 && c <= 0x06F9) {
        out[i] = 0x30 + c - 0x06F0;
      } else if (c == 0x0623 || c == 0x0625 || c == 0x0622 || c == 0x0671) {
        out[i] = 0x0627; // ا
      } else if (c == 0x0629) {
        out[i] = 0x0647; // ة -> ه
      } else if (c == 0x0649) {
        out[i] = 0x064A; // ى -> ي
      } else if (c == 0x060C || c == 0x061B) {
        out[i] = 0x2C; // ، ؛ -> ,
      } else if (c == 0x066B) {
        out[i] = 0x2E; // ٫ -> .
      } else if (c >= 0x41 && c <= 0x5A) {
        out[i] = c + 32;
      } else if (c == 0x2019) {
        out[i] = 0x27; // ’ -> '
      }
    }
    return String.fromCharCodes(out);
  }

  static bool isArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

  // ----------------------------------------------------------------- tokens

  static const _arPeriodWords =
      r'(?:ب|في\s*)?(?:ال)?(?:صبح|صباح|ظهر|ضهر|عصر|مسا|مساء|ليل|فجر)|صباحا|ظهرا|عصرا|مساءا|ليلا';

  static final _arTime = _re(
    '$_b(?:و\\s*)?(?:(?:علي|ع|عند|في|الي|ل)\\s*)?'
    '(?:ال)?ساعه\\s*(?<h>\\d{1,2}|$_arNum)'
    '(?:\\s*[:.]\\s*(?<m>\\d{2})'
    '|\\s*و\\s*(?<frac>النص|نص|الربع|ربع|الثلث|ثلث)'
    '|\\s*و\\s*(?<mm>\\d{1,2})\\s*(?:دقيقه|دقايق|دقائق)?'
    '|\\s*الا\\s*(?<minus>الربع|ربع|الثلث|ثلث|\\d{1,2})(?:\\s*(?:دقيقه|دقايق|دقائق))?)?'
    '$_e',
  );

  static final _arBare = _re(
    '$_b(?:(?:علي|ع)\\s*)?(?<h>\\d{1,2})'
    '(?:\\s*[:.]\\s*(?<m>\\d{2})|\\s*و\\s*(?<frac>نص|ربع|ثلث))?'
    '(?=\\s*(?:$_arPeriodWords)$_e)',
  );

  static final _clock = _re(
    '$_b(?:(?:at|@|علي|ع)\\s*)?(?<h>\\d{1,2}):(?<m>\\d{2})'
    '(?:\\s*(?<ap>a\\.?m\\.?|p\\.?m\\.?)(?![a-z]))?$_e',
  );

  static final _enAt = _re(
    '$_b(?:at|by|@|around)\\s+(?<h>\\d{1,2}|$_enNum)'
    '(?::(?<m>\\d{2}))?(?:\\s*(?<ap>a\\.?m\\.?|p\\.?m\\.?)(?![a-z]))?'
    "(?:\\s*o'?clock)?$_e",
  );

  static final _enAmPm = _re(
    '$_b(?<h>\\d{1,2}|$_enNum)(?::(?<m>\\d{2}))?'
    '\\s*(?<ap>a\\.?m\\.?|p\\.?m\\.?)(?![a-z])',
  );

  static final _enPast = _re(
    '$_b(?:at\\s+)?(?<frac>half|quarter|\\d{1,2})\\s+'
    '(?<rel>past|to)\\s+(?<h>\\d{1,2}|$_enNum)$_e',
  );

  static final _arRelative = _re(
    '$_b(?:و\\s*)?بعد\\s+(?:(?<n>\\d{1,3}|$_arNum)\\s*)?'
    '(?<frac>نص|ربع)?\\s*(?<u>دقيقتين|دقيقه|دقايق|دقائق|دقيقة|ساعتين|ساعه|ساعات|يومين|يوم|ايام|اسبوعين|اسبوع)'
    '(?<half>\\s*و\\s*نص)?$_e',
  );

  static final _enRelative = _re(
    '$_b(?:in|after)\\s+(?:(?<n>\\d{1,3}|$_enNum|an|a)\\s+)?'
    '(?<frac>half\\s+an?|half|a\\s+quarter\\s+of\\s+an|quarter\\s+of\\s+an)?\\s*'
    '(?<u>minutes?|mins?|hours?|hrs?|days?|weeks?)(?<half>\\s+and\\s+a\\s+half)?$_e',
  );

  static final _arDays = <RegExp, int>{
    _re('$_b(?:و\\s*)?بعد\\s*(?:بكره|بكرا|بكري|غد|الغد|بكر)$_e'): 2,
    _re('$_b(?:و\\s*)?(?:ب)?(?:بكره|بكرا|بكري|غدا|الغد|غدوه)$_e'): 1,
    _re('$_b(?:و\\s*)?(?:ال)?يوم$_e(?!\\s*(?:ال)?(?:احد|اثنين|اتنين|ثلاثاء|تلات|اربعاء|اربعا|خميس|جمعه|سبت))'): 0,
    _re('$_b(?:و\\s*)?(?:day after tomorrow)$_e'): 2,
    _re('$_b(?:و\\s*)?(?:tomorrow|tmrw|tmr)$_e'): 1,
    _re('$_b(?:today)$_e'): 0,
  };

  static final _tonight = _re('$_b(?:و\\s*)?(?:الليله|tonight)$_e');

  static final _weekdays = <RegExp, int>{
    _re('$_b(?:(?:يوم|نهار)\\s*)?(?:ال)?(?:اثنين|اتنين|تنين|ثنين)$_e'): DateTime.monday,
    _re('$_b(?:(?:يوم|نهار)\\s*)?(?:ال)?(?:ثلاثاء|ثلاثا|تلاتا|تلات|ثلوث)$_e'): DateTime.tuesday,
    _re('$_b(?:(?:يوم|نهار)\\s*)?(?:ال)?(?:اربعاء|اربعا|ربوع)$_e'): DateTime.wednesday,
    _re('$_b(?:(?:يوم|نهار)\\s*)?ال?خميس$_e'): DateTime.thursday,
    _re('$_b(?:(?:يوم|نهار)\\s*)?ال?جمعه$_e'): DateTime.friday,
    _re('$_b(?:(?:يوم|نهار)\\s*)?ال?سبت$_e'): DateTime.saturday,
    _re('$_b(?:(?:يوم|نهار)\\s*)?(?:ال)?احد$_e'): DateTime.sunday,
    _re('$_b(?:on\\s+|next\\s+|this\\s+)?monday$_e'): DateTime.monday,
    _re('$_b(?:on\\s+|next\\s+|this\\s+)?tuesday$_e'): DateTime.tuesday,
    _re('$_b(?:on\\s+|next\\s+|this\\s+)?wednesday$_e'): DateTime.wednesday,
    _re('$_b(?:on\\s+|next\\s+|this\\s+)?thursday$_e'): DateTime.thursday,
    _re('$_b(?:on\\s+|next\\s+|this\\s+)?friday$_e'): DateTime.friday,
    _re('$_b(?:on\\s+|next\\s+|this\\s+)?saturday$_e'): DateTime.saturday,
    _re('$_b(?:on\\s+|next\\s+|this\\s+)?sunday$_e'): DateTime.sunday,
  };

  // Order matters: "بعد الظهر" must win over "الظهر".
  static final _periods = <RegExp, _Period>{
    _re('$_b(?:و\\s*)?(?:بعد\\s*(?:ال)?(?:ظهر|ضهر)|in the afternoon|this afternoon|afternoon)$_e'): _Period.afternoon,
    _re('$_b(?:و\\s*)?(?:(?:ب|في\\s*)?(?:ال)?(?:صبح|صباح|صبحيه)|صباحا|بدري|in the morning|this morning|morning)$_e'):
        _Period.morning,
    _re('$_b(?:و\\s*)?(?:(?:ب|في\\s*)?(?:ال)?(?:ظهر|ضهر|ظهريه)|ظهرا|noon|midday)$_e'): _Period.noon,
    _re('$_b(?:و\\s*)?(?:(?:ب|في\\s*)?(?:ال)?(?:عصر|عصريه)|عصرا)$_e'): _Period.afternoon,
    _re('$_b(?:و\\s*)?(?:(?:ب|في\\s*)?(?:ال)?(?:مسا|مساء|مغرب)|مساءا|in the evening|this evening|evening)$_e'):
        _Period.evening,
    _re('$_b(?:و\\s*)?(?:(?:ب|في\\s*)?(?:ال)?ليل|ليلا|at night)$_e'): _Period.night,
    _re('$_b(?:و\\s*)?(?:(?:ب|في\\s*)?(?:ال)?فجر|at dawn)$_e'): _Period.dawn,
  };

  static final _midnight = _re('$_b(?:at\\s+)?midnight$_e');

  static final _ideaWords = _re(
    '$_b(?:فكره|افكار|فكرتي|خطرت|خطرلي|خطر|ببالي|ملاحظه|'
    'idea|ideas|thought|note)$_e',
  );

  // ----------------------------------------------------------- the masking

  static void _mask(List<int> work, int start, int end, List<List<int>> cuts) {
    for (var i = start; i < end; i++) {
      work[i] = 0x20;
    }
    cuts.add([start, end]);
  }

  static RegExpMatch? _first(RegExp re, List<int> work) => re.firstMatch(String.fromCharCodes(work));

  static String? _g(RegExpMatch m, String name) {
    try {
      return m.namedGroup(name);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------ split

  static final _splitter = _re(
    r'\s*,\s*|(?<!\d)\.(?!\d)\s*|\s*[!?؟]\s*|\n+'
    r'|\s+(?:و\s*)?(?:كمان|بعدين|بعدها|ثم|وبعدين|وكمان)\s+'
    r'|\s+(?:and then|and also|then|also|plus)\s+'
    r'|\s+and\s+(?=(?:at|i|tomorrow|today|tonight|on|remind|in)\s)'
    r'|\s+و(?=(?:لازم|عندي|بدي|كمان|بكره|بكرا|علي الساعه|الساعه|عالساعه|ع الساعه)(?![\p{L}]))',
  );

  /// Splits one utterance into several reminders and parses each.
  static List<ParsedItem> parse(String input, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final norm = normalize(input);

    // Segment boundaries from connectors.
    final segments = <String>[];
    var last = 0;
    for (final m in _splitter.allMatches(norm)) {
      segments.add(input.substring(last, m.start));
      last = m.end;
    }
    segments.add(input.substring(last));

    // A segment with two clock times is two reminders.
    final finalSegments = <String>[];
    for (final seg in segments) {
      final n = normalize(seg);
      final starts = <int>[..._arTime.allMatches(n).map((m) => m.start), ..._enAt.allMatches(n).map((m) => m.start)]
        ..sort();
      if (starts.length < 2) {
        finalSegments.add(seg);
        continue;
      }
      var from = 0;
      for (final s in starts.skip(1)) {
        finalSegments.add(seg.substring(from, s));
        from = s;
      }
      finalSegments.add(seg.substring(from));
    }

    final items = <ParsedItem>[];
    int? inheritedDay;
    for (final seg in finalSegments) {
      if (seg.trim().isEmpty) continue;
      final item = parseOne(seg, now: clock, inheritedDayOffset: inheritedDay);
      if (item.dayOffset != null) inheritedDay = item.dayOffset;
      if (item.title.isEmpty) {
        // Only a time, e.g. "..., الساعة 8 الصبح": attach to the previous item.
        if (items.isNotEmpty && items.last.due == null && item.due != null) {
          items.last
            ..due = item.due
            ..hasTime = true
            ..kind = ItemKind.task;
        }
        continue;
      }
      items.add(item);
    }
    return items;
  }

  /// Parses a single reminder (no splitting).
  static ParsedItem parseOne(String input, {DateTime? now, int? inheritedDayOffset}) {
    final clock = now ?? DateTime.now();
    final work = List<int>.of(normalize(input).codeUnits);
    final cuts = <List<int>>[];

    // Relative ("بعد ساعة", "in 10 minutes").
    Duration? relative;
    for (final re in [_arRelative, _enRelative]) {
      final m = _first(re, work);
      if (m == null) continue;
      relative = _relativeDuration(m);
      if (relative != null) {
        _mask(work, m.start, m.end, cuts);
        break;
      }
    }

    // Day.
    int? dayOffset;
    var tonight = false;
    for (final entry in _arDays.entries) {
      final m = _first(entry.key, work);
      if (m != null) {
        dayOffset = entry.value;
        _mask(work, m.start, m.end, cuts);
        break;
      }
    }
    final tn = _first(_tonight, work);
    if (tn != null) {
      tonight = true;
      dayOffset ??= 0;
      _mask(work, tn.start, tn.end, cuts);
    }
    if (dayOffset == null) {
      for (final entry in _weekdays.entries) {
        final m = _first(entry.key, work);
        if (m != null) {
          var diff = (entry.value - clock.weekday + 7) % 7;
          if (diff == 0) diff = 7;
          dayOffset = diff;
          _mask(work, m.start, m.end, cuts);
          break;
        }
      }
    }

    // Clock time.
    int? hour;
    var minute = 0;
    String? ampm;
    final timeMatchers = [_arTime, _enPast, _clock, _enAt, _enAmPm, _arBare];
    for (final re in timeMatchers) {
      final m = _first(re, work);
      if (m == null) continue;
      final h = _number(_g(m, 'h'));
      if (h == null || h > 23) continue;
      hour = h;
      minute = int.tryParse(_g(m, 'm') ?? '') ?? 0;
      final frac = _g(m, 'frac');
      final mm = _g(m, 'mm');
      final minus = _g(m, 'minus');
      final rel = _g(m, 'rel');
      ampm = _g(m, 'ap');
      if (rel != null) {
        final f = frac == 'half'
            ? 30
            : frac == 'quarter'
            ? 15
            : int.parse(frac!);
        if (rel == 'past') {
          minute = f;
        } else {
          hour = (h + 23) % 24;
          minute = 60 - f;
        }
      } else if (frac != null) {
        minute = frac.contains('نص')
            ? 30
            : frac.contains('ربع')
            ? 15
            : 20;
      } else if (mm != null) {
        minute = int.parse(mm);
      } else if (minus != null) {
        final f = minus.contains('ربع')
            ? 15
            : minus.contains('ثلث')
            ? 20
            : int.parse(minus);
        hour = (h + 23) % 24;
        if (hour == 0 && h != 0) hour = 12; // "الساعة 1 الا ربع" -> 12:45
        minute = 60 - f;
      }
      if (minute > 59) minute = 0;
      _mask(work, m.start, m.end, cuts);
      break;
    }
    final mid = _first(_midnight, work);
    if (hour == null && mid != null) {
      hour = 0;
      dayOffset ??= 1;
      _mask(work, mid.start, mid.end, cuts);
    }

    // Period of day.
    _Period? period;
    for (final entry in _periods.entries) {
      final m = _first(entry.key, work);
      if (m != null) {
        period = entry.value;
        _mask(work, m.start, m.end, cuts);
        break;
      }
    }
    if (tonight) period ??= _Period.evening;

    // Kind.
    final isIdea = _ideaWords.hasMatch(String.fromCharCodes(work));

    // Compose the date.
    DateTime? due;
    final hasTime = relative != null || hour != null || period != null;
    final explicitDay = dayOffset != null;
    dayOffset ??= inheritedDayOffset;

    if (relative != null) {
      due = clock.add(relative);
    } else if (hour != null || period != null || dayOffset != null) {
      var h = hour;
      var addDay = 0;
      if (h == null) {
        h = switch (period) {
          _Period.dawn => 5,
          _Period.morning => 9,
          _Period.noon => 12,
          _Period.afternoon => 16,
          _Period.evening => 19,
          _Period.night => 21,
          null => 9,
        };
      } else if (ampm != null) {
        final pm = ampm.startsWith('p');
        if (pm && h < 12) h += 12;
        if (!pm && h == 12) h = 0;
      } else if (period != null) {
        switch (period) {
          case _Period.dawn:
          case _Period.morning:
            if (h == 12) h = 0;
          case _Period.noon:
            if (h <= 4) h += 12;
          case _Period.afternoon:
          case _Period.evening:
            if (h < 12) h += 12;
          case _Period.night:
            if (h >= 6 && h < 12) {
              h += 12;
            } else if (h == 12) {
              h = 0;
              addDay = 1;
            }
        }
      } else if (h >= 1 && h <= 6) {
        // "الساعة 4 اروح اجيب الاولاد" almost always means the afternoon.
        h += 12;
      }

      final base = DateTime(clock.year, clock.month, clock.day);
      var date = DateTime(base.year, base.month, base.day + (dayOffset ?? 0) + addDay, h, minute);

      if (dayOffset == null) {
        // Ambiguous 7–12 o'clock without am/pm: pick the next one coming.
        if (date.isBefore(clock) && hour != null && ampm == null && period == null && h < 12) {
          final later = date.add(const Duration(hours: 12));
          if (later.isAfter(clock)) date = later;
        }
        if (date.isBefore(clock)) {
          date = DateTime(date.year, date.month, date.day + 1, date.hour, date.minute);
        }
      }
      due = date;
    }

    var title = _cleanTitle(input, cuts);
    final kind = (isIdea && !hasTime) ? ItemKind.idea : ItemKind.task;
    if (kind == ItemKind.idea) title = _stripIdeaWords(title);

    return ParsedItem(title: title, kind: kind, due: due, dayOffset: explicitDay ? dayOffset : null, hasTime: hasTime);
  }

  static Duration? _relativeDuration(RegExpMatch m) {
    final u = (_g(m, 'u') ?? '').toLowerCase();
    final nText = _g(m, 'n');
    final frac = _g(m, 'frac');
    var n = _number(nText)?.toDouble() ?? 1;
    if (u == 'دقيقتين' || u == 'ساعتين' || u == 'يومين' || u == 'اسبوعين') n = 2;
    if (frac != null) {
      n = frac.contains('نص') || frac.contains('half') ? 0.5 : 0.25;
    }
    if (_g(m, 'half') != null) n += 0.5;
    int minutes;
    if (u.startsWith('دقي') || u.startsWith('دقا') || u.startsWith('min')) {
      minutes = n.round();
    } else if (u.startsWith('ساع') || u.startsWith('h')) {
      minutes = (n * 60).round();
    } else if (u.startsWith('يوم') || u.startsWith('ايام') || u.startsWith('day')) {
      minutes = (n * 1440).round();
    } else if (u.startsWith('اسبوع') || u.startsWith('week')) {
      minutes = (n * 10080).round();
    } else {
      return null;
    }
    if (minutes <= 0) return null;
    return Duration(minutes: minutes);
  }

  // ----------------------------------------------------------------- titles

  static final _leadingFillers = _re(
    '^(?:'
    r'ذكرني|ذكريني|فكرني|تذكرني|ذكرنا|يا ذكرني|'
    r'في عندي|عندي|فيه عندي|انا عندي|'
    r'بدي|بدك|اريد|ابغي|ابي|ودي|لازم|ضروري|يجب|انا|اني|انه|ان|اذكر|تذكير|خليني|'
    r'و|علي|ع|عند|في|الساعه|'
    r"hey|ok|okay|please|remind me to|remind me that|remind me about|remind me|"
    r"i need to|i have to|i must|i should|i want to|i'd like to|need to|have to|"
    r"don't forget to|dont forget to|i have|i've got|i got|to|that|about|and|at|on"
    ')(?![\\p{L}\\p{N}])\\s*',
  );

  static final _trailingFillers = _re(
    r'\s*(?<![\p{L}\p{N}])(?:'
    r'و|علي|ع|عند|في|الساعه|لازم|at|on|and|to|by|please'
    r')$',
  );

  static String _cleanTitle(String input, List<List<int>> cuts) {
    final units = List<int>.of(input.codeUnits);
    for (final c in cuts) {
      for (var i = c[0]; i < c[1] && i < units.length; i++) {
        units[i] = 0x20;
      }
    }
    var t = String.fromCharCodes(units);
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    t = _trimPunct(t);
    for (var i = 0; i < 6; i++) {
      final before = t;
      final n = normalize(t);
      final m = _leadingFillers.firstMatch(n);
      if (m != null && m.end > 0) t = t.substring(m.end);
      final n2 = normalize(t);
      final m2 = _trailingFillers.firstMatch(n2);
      if (m2 != null) t = t.substring(0, m2.start);
      t = _trimPunct(t);
      if (t == before) break;
    }
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isNotEmpty && !isArabic(t)) {
      t = t[0].toUpperCase() + t.substring(1);
    }
    return t;
  }

  static final _ideaLead = _re(
    '^(?:'
    r'(?:في\s+)?(?:عندي|عندي\s+هيك|خطرت\s+(?:لي|علي)?\s*(?:ببالي|بالي)?|خطرلي|خطر\s+ببالي|طلعت\s+معي)?\s*'
    r'(?:فكره|ملاحظه)(?:\s+(?:ابداعيه|جديده|حلوه|مهمه))?|'
    r'فكرتي|خطرت\s+(?:لي|ببالي)|خطرلي|'
    r'(?:i\s+(?:have|had|got)\s+)?(?:an?\s+)?(?:new\s+|creative\s+|great\s+)?(?:idea|thought|note)'
    r')(?![\p{L}\p{N}])\s*(?:انه|ان|انو|اني|بانه|هي|:|-|that|is|for)?\s*',
  );

  static String _stripIdeaWords(String title) {
    final n = normalize(title);
    final m = _ideaLead.firstMatch(n);
    var t = title;
    if (m != null && m.end < title.length) t = title.substring(m.end);
    t = _trimPunct(t);
    // Fillers like "عندي" may remain in front.
    final m2 = _leadingFillers.firstMatch(normalize(t));
    if (m2 != null && m2.end > 0 && m2.end < t.length) t = t.substring(m2.end);
    t = _trimPunct(t);
    if (t.isNotEmpty && !isArabic(t)) t = t[0].toUpperCase() + t.substring(1);
    return t.isEmpty ? title : t;
  }

  static String _trimPunct(String s) => s.replaceAll(RegExp(r'^[\s,.،؛:;!?؟\-–]+|[\s,.،؛:;!?؟\-–]+$'), '');

  // ---------------------------------------------------------- conversation

  static final _negatives = _re(
    '$_b(?:لا|لأ|لاء|لاا|ما\\s*في|مافي|ولا\\s*شي|لا\\s*شي|خلص|خلاص|بس|هيك|شكرا|'
    'تسلم|يسلمو|يعطيك العافيه|مشكور|كفايه|no|nope|nah|nothing|done|thanks|thank you|'
    "that's it|thats it|that's all|thats all|i'm good|im good|all good|no thanks)$_e",
  );

  /// True for "لا، خلص" / "no thanks, that's it".
  static bool isNegative(String s) {
    final rest = normalize(s).replaceAll(_negatives, ' ').replaceAll(RegExp(r'[\s,.!?؟]+'), '');
    return rest.isEmpty && s.trim().isNotEmpty;
  }

  static final _noTime = _re(
    '$_b(?:بدون(?:\\s*وقت)?|بلا\\s*وقت|مش\\s*مهم|ما\\s*في\\s*وقت|'
    'اي\\s*وقت|فكره|احفظها|خليها|no time|anytime|any time|whenever|just save|save it)$_e',
  );

  /// "بدون وقت" when asked for a time.
  static bool isNoTime(String s) => _noTime.hasMatch(normalize(s)) || isNegative(s);
}
