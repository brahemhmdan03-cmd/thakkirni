import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/parser.dart';
import '../core/store.dart';
import 'theme.dart';

/// Edit an existing reminder, or type a new one (parsed like speech).
Future<void> showEditSheet(BuildContext context, {Reminder? reminder}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: reminder == null ? const _QuickAdd() : _Edit(reminder: reminder),
    ),
  );
}

class _QuickAdd extends StatefulWidget {
  const _QuickAdd();

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _ctrl = TextEditingController();
  List<ParsedItem> _items = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final items = ReminderParser.parse(_ctrl.text);
    for (final i in items) {
      await AppStore.instance.addParsed(i);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.whatToRemind, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: s.typeHint),
            onChanged: (t) => setState(() => _items = ReminderParser.parse(t)),
            onSubmitted: (_) => _save(),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(s.preview, style: TextStyle(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: 6),
            for (final i in _items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  i.kind == ItemKind.idea || i.due == null ? Icons.lightbulb_outline_rounded : Icons.schedule_rounded,
                  color: i.due == null ? Brand.teal : context.colors.primary,
                ),
                title: Text(i.title),
                subtitle: Text(i.due == null ? s.idea : s.when(i.due!, now)),
              ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _items.isEmpty ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(s.save),
          ),
        ],
      ),
    );
  }
}

class _Edit extends StatefulWidget {
  const _Edit({required this.reminder});
  final Reminder reminder;

  @override
  State<_Edit> createState() => _EditState();
}

class _EditState extends State<_Edit> {
  late final _ctrl = TextEditingController(text: widget.reminder.text);
  late ItemKind _kind = widget.reminder.kind;
  late DateTime? _due = widget.reminder.due;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final start = _due ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: start.isBefore(now) ? now : start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
    if (time == null) return;
    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _kind = ItemKind.task;
    });
  }

  Future<void> _save() async {
    final r = widget.reminder;
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) r.text = text;
    r
      ..kind = _due == null ? ItemKind.idea : _kind
      ..due = _kind == ItemKind.idea ? null : _due;
    if (r.due != null && r.due!.isAfter(DateTime.now())) r.done = false;
    await AppStore.instance.update(r);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.edit, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(controller: _ctrl, minLines: 1, maxLines: 5),
          const SizedBox(height: 14),
          SegmentedButton<ItemKind>(
            segments: [
              ButtonSegment(value: ItemKind.task, label: Text(s.task), icon: const Icon(Icons.schedule_rounded)),
              ButtonSegment(
                value: ItemKind.idea,
                label: Text(s.idea),
                icon: const Icon(Icons.lightbulb_outline_rounded),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (v) {
              setState(() => _kind = v.first);
              if (_kind == ItemKind.task && _due == null) _pickTime();
            },
          ),
          if (_kind == ItemKind.task) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(_due == null ? s.setTime : s.when(_due!, now)),
              trailing: _due == null
                  ? null
                  : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _due = null)),
              onTap: _pickTime,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  await AppStore.instance.delete(widget.reminder);
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Brand.coral),
                label: Text(s.delete, style: const TextStyle(color: Brand.coral)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32)),
                child: Text(s.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
