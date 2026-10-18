import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/platform.dart';
import '../core/store.dart';
import '../services/notifications.dart';
import '../services/voice.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final store = AppStore.instance;
  bool _exactOk = true;

  Settings get st => store.settings;

  @override
  void initState() {
    super.initState();
    Voice.instance.initSpeech().then((_) => mounted ? setState(() {}) : null);
    Notifications.instance.canScheduleExact().then((v) => mounted ? setState(() => _exactOk = v) : null);
  }

  void _save() {
    store.saveSettings();
    setState(() {});
  }

  String _hm(int minutes) {
    final t = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return MaterialLocalizations.of(context).formatTimeOfDay(t);
  }

  Future<int?> _pick(int minutes) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 8),
    child: Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.primary),
    ),
  );

  Widget _card(List<Widget> children) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Card(child: Column(children: children)),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dialects = Voice.instance.arabicLocales;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _header(s.language),
          _card([
            RadioGroup<AppLanguage>(
              groupValue: st.appLanguage,
              onChanged: (v) {
                st.appLanguage = v!;
                _save();
              },
              child: Column(
                children: [
                  for (final l in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      value: l,
                      title: Text(switch (l) {
                        AppLanguage.system => s.systemDefault,
                        AppLanguage.ar => 'العربية',
                        AppLanguage.en => 'English',
                      }),
                    ),
                ],
              ),
            ),
          ]),
          _header(s.voiceSection),
          _card([
            ListTile(
              title: Text(s.speechLanguage),
              trailing: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('عربي')),
                  ButtonSegment(value: 'en', label: Text('EN')),
                ],
                selected: {st.speechLanguage},
                onSelectionChanged: (v) {
                  st.speechLanguage = v.first;
                  _save();
                },
              ),
            ),
            if (dialects.length > 1)
              ListTile(
                title: Text(s.dialect),
                trailing: DropdownButton<String>(
                  value: dialects.any((d) => d.localeId == st.arabicLocaleId)
                      ? st.arabicLocaleId
                      : Voice.instance.localeFor('ar'),
                  underline: const SizedBox(),
                  items: [for (final d in dialects) DropdownMenuItem(value: d.localeId, child: Text(d.name))],
                  onChanged: (v) {
                    st.arabicLocaleId = v;
                    _save();
                  },
                ),
              ),
            SwitchListTile(
              title: Text(s.listenOnOpen),
              value: st.listenOnOpen,
              onChanged: (v) {
                st.listenOnOpen = v;
                _save();
              },
            ),
            ListTile(
              leading: Icon(
                isIOS ? Icons.mic_external_on_rounded : Icons.assistant_rounded,
                color: context.colors.primary,
              ),
              title: Text(
                isIOS ? s.siriHelpIos : s.assistantHelpAndroid,
                style: const TextStyle(height: 1.45),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(s.wakeWordNote, style: const TextStyle(height: 1.4)),
              ),
            ),
          ]),
          _header(s.tasks),
          _card([
            ListTile(
              title: Text(s.preAlert),
              trailing: DropdownButton<int>(
                value: st.preAlertMinutes,
                underline: const SizedBox(),
                items: [
                  for (final m in [0, 5, 10, 15, 30, 60])
                    DropdownMenuItem(value: m, child: Text(m == 0 ? s.atTimeOnly : s.minutes(m))),
                ],
                onChanged: (v) {
                  st.preAlertMinutes = v!;
                  _save();
                },
              ),
            ),
            if (isAndroid && !_exactOk)
              ListTile(
                leading: const Icon(Icons.alarm_on_rounded, color: Brand.amber),
                title: Text(s.exactAlarms),
                onTap: () async {
                  await Notifications.instance.requestExactAlarms();
                  final ok = await Notifications.instance.canScheduleExact();
                  if (mounted) setState(() => _exactOk = ok);
                  await store.refreshSchedules();
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(s.testNotification),
              onTap: () => Notifications.instance.showTest(),
            ),
          ]),
          _header(s.ideasSection),
          _card([
            SwitchListTile(
              title: Text(s.ideasEnabled),
              value: st.ideasEnabled,
              onChanged: (v) {
                st.ideasEnabled = v;
                _save();
              },
            ),
            if (st.ideasEnabled) ...[
              ListTile(
                title: Text(s.freeFrom),
                trailing: Text(_hm(st.freeStartMinutes), style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  final v = await _pick(st.freeStartMinutes);
                  if (v == null) return;
                  st.freeStartMinutes = v;
                  _save();
                },
              ),
              ListTile(
                title: Text(s.freeTo),
                trailing: Text(_hm(st.freeEndMinutes), style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  final v = await _pick(st.freeEndMinutes);
                  if (v == null) return;
                  st.freeEndMinutes = v;
                  _save();
                },
              ),
              ListTile(
                title: Text(s.perDay),
                trailing: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                  ],
                  selected: {st.ideasPerDay},
                  onSelectionChanged: (v) {
                    st.ideasPerDay = v.first;
                    _save();
                  },
                ),
              ),
            ],
          ]),
          _header(s.about),
          _card([
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(s.privacyNote),
              subtitle: const Text('ذكرني · Thakkirni 1.0.0'),
            ),
          ]),
        ],
      ),
    );
  }
}
