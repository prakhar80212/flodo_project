import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../utils/constants.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();

  // Debounce timer for search (stretch goal)
  // We declare it here so we can cancel it on each keystroke
  DateTime? _lastTyped;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Debounced search ───────────────────────────────────────────────────────
  // Each time user types, we record the time. After 300ms of no typing,
  // we update the search provider which triggers a refetch.
  void _onSearchChanged(String value) {
    // Update display query instantly — triggers client-side filter + highlight
    ref.read(displayQueryProvider.notifier).state = value;

    // Debounce the API call
    _lastTyped = DateTime.now();
    final capturedTime = _lastTyped;
    Future.delayed(
      Duration(milliseconds: AppConstants.searchDebounceMs),
      () {
        if (_lastTyped == capturedTime) {
          ref.read(searchQueryProvider.notifier).state = value;
        }
      },
    );
  }

  // ── Navigate to create screen ──────────────────────────────────────────────
  void _openCreate(List<Task> allTasks) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(allTasks: allTasks),
      ),
    );
  }

  // ── Navigate to edit screen ────────────────────────────────────────────────
  void _openEdit(Task task, List<Task> allTasks) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task, allTasks: allTasks),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync    = ref.watch(filteredTaskListProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final displayQuery = ref.watch(displayQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Tasks',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      onPressed: () =>
                          ref.invalidate(taskListProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Search bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.grey.shade400, size: 20),
                    suffixIcon: displayQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.grey.shade400,
                            onPressed: () {
                              _searchController.clear();
                              ref.read(displayQueryProvider.notifier).state = '';
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Status filter ────────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: ['All', ...AppConstants.statusOptions]
                      .map((s) => _FilterChip(
                            label: s,
                            selected: statusFilter == s,
                            onTap: () => ref
                                .read(statusFilterProvider.notifier)
                                .state = s,
                          ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ── Task list ────────────────────────────────────────────────
              Expanded(
                child: taskAsync.when(
                  // Loading state
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  ),

                  // Error state
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(taskListProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                  // Data state
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return _EmptyState(
                        onTap: () => _openCreate([]),
                      );
                    }

                    // ── Drag-and-drop reorderable list ─────────────────────
                    return RefreshIndicator(
                      color: Colors.indigo,
                      onRefresh: () async {
                        ref.invalidate(taskListProvider);
                        await ref.read(taskListProvider.future);
                      },
                      child: ReorderableListView.builder(
                        key: ValueKey(displayQuery),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: tasks.length,
                        buildDefaultDragHandles: false,

                        // Called when user finishes dragging
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          final updated = List<Task>.from(tasks);
                          final item = updated.removeAt(oldIndex);
                          updated.insert(newIndex, item);
                          ref
                              .read(taskNotifierProvider.notifier)
                              .reorderTasks(updated);
                        },

                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return ReorderableDragStartListener(
                            key: Key('drag_${task.id}'),
                            index: index,
                            child: Stack(
                              children: [
                                TaskCard(
                                  task: task,
                                  allTasks: tasks,
                                  onTap: () => _openEdit(task, tasks),
                                  searchQuery: displayQuery,
                                ),
                                // Drag handle (right side of card)
                                Positioned(
                                  right: 8,
                                  top: 0,
                                  bottom: 12,
                                  child: Icon(
                                    Icons.drag_handle_rounded,
                                    color: Colors.grey.shade300,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Floating action button ─────────────────────────────────────────
      floatingActionButton: taskAsync.maybeWhen(
        data: (tasks) => FloatingActionButton.extended(
          onPressed: () => _openCreate(tasks),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
          icon: const Icon(Icons.add),
          label: const Text(
            'New Task',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

// ── Filter chip widget ───────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.indigo : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ── Empty state widget ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded,
              size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first task',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add),
            label: const Text('Create Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}