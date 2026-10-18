import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models.dart';
import '../core/store.dart';
import 'edit_sheet.dart';
import 'theme.dart';

class MicButton extends StatefulWidget {
  const MicButton({super.key, required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 96,
          height: 96,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = _pulse.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72 + 24 * t,
                    height: 72 + 24 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Brand.violet.withValues(alpha: 0.25 * (1 - t)),
                    ),
                  ),
                  child!,
                ],
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: Brand.gradient,
                boxShadow: [
                  BoxShadow(color: Brand.violet.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 56, 40, 0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.primaryContainer.withValues(alpha: 0.6),
              ),
              child: Icon(icon, size: 40, color: context.colors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onSurfaceVariant, height: 1.5, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key, required this.reminder, required this.now});
  final Reminder reminder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = reminder;
    final store = AppStore.instance;
    final overdue = !r.done && r.due != null && r.due!.isBefore(now);
    final soon = !r.done && r.due != null && !overdue && r.due!.difference(now) < const Duration(hours: 2);
    final chipColor = overdue
        ? Brand.coral
        : soon
        ? Brand.amber
        : r.isIdea
        ? Brand.teal
        : context.colors.primary;

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(color: Brand.coral, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        store.delete(r);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${s.deleted}: ${r.text}', maxLines: 1, overflow: TextOverflow.ellipsis),
              action: SnackBarAction(label: s.undo, onPressed: () => store.restore(r)),
            ),
          );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showEditSheet(context, reminder: r),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 16, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    store.toggleDone(r);
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      r.done
                          ? Icons.check_circle_rounded
                          : r.isIdea
                          ? Icons.lightbulb_outline_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey('${r.done}${r.isIdea}'),
                      color: r.done ? Brand.teal : chipColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          decoration: r.done ? TextDecoration.lineThrough : null,
                          color: r.done ? context.colors.onSurfaceVariant : null,
                        ),
                      ),
                      if (r.due != null || r.isIdea) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                r.isIdea ? Icons.auto_awesome_rounded : Icons.schedule_rounded,
                                size: 14,
                                color: chipColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                r.due != null ? s.when(r.due!, now) : s.dayLabel(r.createdAt, now),
                                style: TextStyle(fontSize: 12.5, color: chipColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
