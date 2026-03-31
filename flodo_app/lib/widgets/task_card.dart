import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/highlighted_text.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final List<Task> allTasks; // needed to show the blocker's title
  final VoidCallback onTap;
  final String searchQuery;  // called when card is tapped to edit

  const TaskCard({
    super.key,
    required this.task,
    required this.allTasks,
    required this.onTap,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // ── Blocked-by logic ───────────────────────────────────────────────────
    // A task is "blocked" if it has a blockedById AND that blocker
    // is not yet marked "Done"
    final blocker = task.blockedById != null
        ? allTasks.where((t) => t.id == task.blockedById).firstOrNull
        : null;
    final isBlocked = blocker != null && blocker.status != 'Done';

    // ── Colors ─────────────────────────────────────────────────────────────
    final cardColor = isBlocked
        ? Colors.grey.shade100   // greyed out when blocked
        : Colors.white;

    final textColor = isBlocked
        ? Colors.grey.shade400
        : Colors.grey.shade800;

    return Dismissible(
      // Dismissible allows swipe-to-delete
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart, // swipe left to delete
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),

      // Ask for confirmation before deleting
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },

      onDismissed: (_) {
        ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${task.title}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },

      child: GestureDetector(
        onTap: isBlocked ? null : onTap, // blocked tasks can't be tapped
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBlocked
                  ? Colors.grey.shade200
                  : Colors.grey.shade100,
            ),
            boxShadow: isBlocked
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Top row: title + status badge ──────────────────────────
              Row(
                children: [
                  Expanded(
                    child: HighlightedText(
                      text: task.title,
                      query: searchQuery,   // we'll pass this in next
                      baseStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        decoration: task.status == 'Done'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: task.status, isBlocked: isBlocked),
                ],
              ),

              // ── Description ────────────────────────────────────────────
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                HighlightedText(
                  text: task.description,
                  query: searchQuery,
                  baseStyle: TextStyle(
                    fontSize: 13,
                    color: isBlocked
                        ? Colors.grey.shade300
                        : Colors.grey.shade500,
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // ── Bottom row: due date + recurring badge + blocked notice ─
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(Icons.calendar_today_outlined,
                        size: 13,
                        color: isBlocked
                            ? Colors.grey.shade300
                            : Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isBlocked
                            ? Colors.grey.shade300
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Recurring badge
                  if (task.isRecurring) ...[
                    Icon(Icons.repeat,
                        size: 13,
                        color: isBlocked
                            ? Colors.grey.shade300
                            : Colors.indigo.shade300),
                    const SizedBox(width: 4),
                    Text(
                      task.recurrenceType ?? 'Recurring',
                      style: TextStyle(
                        fontSize: 12,
                        color: isBlocked
                            ? Colors.grey.shade300
                            : Colors.indigo.shade300,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  const Spacer(),

                  // Blocked notice
                  if (isBlocked)
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Blocked by "${blocker.title}"',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge widget ──────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isBlocked;

  const _StatusBadge({required this.status, required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    // Each status gets its own color
    final colors = {
      'To-Do':       [Colors.grey.shade100,   Colors.grey.shade600],
      'In Progress': [Colors.amber.shade50,   Colors.amber.shade700],
      'Done':        [Colors.green.shade50,   Colors.green.shade700],
    };

    final pair = isBlocked
        ? [Colors.grey.shade100, Colors.grey.shade300]
        : (colors[status] ?? [Colors.grey.shade100, Colors.grey.shade600]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pair[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: pair[1],
        ),
      ),
    );
  }
}