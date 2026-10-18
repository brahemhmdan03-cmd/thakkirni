import 'package:flutter_test/flutter_test.dart';
import 'package:thakkirni/core/parser.dart';

void main() {
  // Sunday 18 Oct 2026, 07:00.
  final now = DateTime(2026, 10, 18, 7, 0);

  ParsedItem one(String s, {DateTime? at}) {
    final items = ReminderParser.parse(s, now: at ?? now);
    expect(items, hasLength(1), reason: 'for "$s" got $items');
    return items.single;
  }

  group('Arabic', () {
    test('morning bread', () {
      final i = one('لازم اشتري على الساعه 8 الصبح خبز');
      expect(i.title, 'اشتري خبز');
      expect(i.kind, ItemKind.task);
      expect(i.due, DateTime(2026, 10, 18, 8, 0));
    });

    test('4 o\'clock means afternoon', () {
      final i = one('لازم على الساعه 4 اروح اجيب الاولاد');
      expect(i.title, 'اروح اجيب الاولاد');
      expect(i.due, DateTime(2026, 10, 18, 16, 0));
    });

    test('appointment at 5', () {
      final i = one('عندي على الساعة ٥ موعد عند الدكتور');
      expect(i.title, 'موعد عند الدكتور');
      expect(i.due, DateTime(2026, 10, 18, 17, 0));
    });

    test('hour words, half, tomorrow', () {
      final i = one('بكرة الساعة تمانية ونص الصبح اتصل بأحمد');
      expect(i.title, 'اتصل بأحمد');
      expect(i.due, DateTime(2026, 10, 19, 8, 30));
    });

    test('quarter to', () {
      final i = one('الساعة ثلاثة الا ربع اجتماع');
      expect(i.due, DateTime(2026, 10, 18, 14, 45));
      expect(i.title, 'اجتماع');
    });

    test('evening', () {
      final i = one('الساعه 9 بالليل اطفي الغاز');
      expect(i.due, DateTime(2026, 10, 18, 21, 0));
      expect(i.title, 'اطفي الغاز');
    });

    test('after the noon', () {
      final i = one('بعد الظهر الساعة 3 روح عالبنك');
      expect(i.due, DateTime(2026, 10, 18, 15, 0));
      expect(i.title, 'روح عالبنك');
    });

    test('relative minutes', () {
      final i = one('ذكرني بعد 10 دقايق اطلع الكيكة من الفرن');
      expect(i.due, DateTime(2026, 10, 18, 7, 10));
      expect(i.title, 'اطلع الكيكة من الفرن');
    });

    test('relative hour and half', () {
      final i = one('بعد ساعة ونص اشرب الدوا');
      expect(i.due, DateTime(2026, 10, 18, 8, 30));
      expect(i.title, 'اشرب الدوا');
    });

    test('weekday', () {
      final i = one('يوم الخميس الساعة 10 الصبح تجديد الهوية');
      expect(i.due!.weekday, DateTime.thursday);
      expect(i.due, DateTime(2026, 10, 22, 10, 0));
      expect(i.title, 'تجديد الهوية');
    });

    test('a time that already passed today moves on', () {
      final i = one('الساعة 8 الصبح رياضة', at: DateTime(2026, 10, 18, 9, 0));
      expect(i.due, DateTime(2026, 10, 19, 8, 0));
    });

    test('ambiguous 8 later today becomes evening', () {
      final i = one('الساعة 8 اتصل بأمي', at: DateTime(2026, 10, 18, 12, 0));
      expect(i.due, DateTime(2026, 10, 18, 20, 0));
    });

    test('idea', () {
      final i = one('في عندي فكرة ابداعية انه نعمل تطبيق للوصفات');
      expect(i.kind, ItemKind.idea);
      expect(i.due, isNull);
      expect(i.title, 'نعمل تطبيق للوصفات');
    });

    test('idea with colon', () {
      final i = one('فكرة: محل قهوة متنقل');
      expect(i.kind, ItemKind.idea);
      expect(i.title, 'محل قهوة متنقل');
    });

    test('task without time needs time', () {
      final i = one('لازم اشتري حليب');
      expect(i.needsTime, isTrue);
      expect(i.title, 'اشتري حليب');
    });

    test('several tasks in one sentence', () {
      final items = ReminderParser.parse(
        'لازم اشتري على الساعه 8 الصبح خبز ولازم على الساعه 4 اروح اجيب الاولاد وعندي على الساعه 5 موعد',
        now: now,
      );
      expect(items.map((e) => e.title).toList(), ['اشتري خبز', 'اروح اجيب الاولاد', 'موعد']);
      expect(items.map((e) => e.due!.hour).toList(), [8, 16, 17]);
    });

    test('tomorrow is inherited by the next task', () {
      final items = ReminderParser.parse('بكرة الساعة 9 الصبح الجامعة وكمان الساعة 2 الظهر الغدا مع سامي', now: now);
      expect(items, hasLength(2));
      expect(items[0].due, DateTime(2026, 10, 19, 9, 0));
      expect(items[1].due, DateTime(2026, 10, 19, 14, 0));
      expect(items[1].title, 'الغدا مع سامي');
    });

    test('negative answers', () {
      expect(ReminderParser.isNegative('لا شكرا'), isTrue);
      expect(ReminderParser.isNegative('خلص هيك'), isTrue);
      expect(ReminderParser.isNegative('لا، بس الساعة 5 الجيم'), isFalse);
    });
  });

  group('English', () {
    test('at 6:30 pm tomorrow', () {
      final i = one('Remind me to call mom tomorrow at 6:30 pm');
      expect(i.title, 'Call mom');
      expect(i.due, DateTime(2026, 10, 19, 18, 30));
    });

    test('4pm pick up kids', () {
      final i = one('I have to pick up the kids at 4');
      expect(i.title, 'Pick up the kids');
      expect(i.due, DateTime(2026, 10, 18, 16, 0));
    });

    test('in 20 minutes', () {
      final i = one('in 20 minutes take the pills');
      expect(i.due, DateTime(2026, 10, 18, 7, 20));
      expect(i.title, 'Take the pills');
    });

    test('half past eight in the morning', () {
      final i = one('gym at half past eight in the morning');
      expect(i.due, DateTime(2026, 10, 18, 8, 30));
      expect(i.title, 'Gym');
    });

    test('idea', () {
      final i = one('I have an idea: a podcast about local history');
      expect(i.kind, ItemKind.idea);
      expect(i.title, 'A podcast about local history');
    });

    test('two tasks', () {
      final items = ReminderParser.parse('buy bread at 8 am and then dentist appointment at 5 pm', now: now);
      expect(items.map((e) => e.title).toList(), ['Buy bread', 'Dentist appointment']);
      expect(items.map((e) => e.due!.hour).toList(), [8, 17]);
    });

    test('tonight', () {
      final i = one('watch the match tonight');
      expect(i.due, DateTime(2026, 10, 18, 19, 0));
      expect(i.title, 'Watch the match');
    });

    test('negative', () {
      expect(ReminderParser.isNegative("No thanks, that's it"), isTrue);
    });
  });
}
