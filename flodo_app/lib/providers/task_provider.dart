import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/api_service.dart';

// ── ApiService provider ────────────────────────────────────────────────────
// Makes a single ApiService instance available to the whole app
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ── Search and filter state providers ─────────────────────────────────────
// searchQueryProvider   — debounced, drives the API call
// displayQueryProvider  — instant, updated on every keystroke for highlighting
final searchQueryProvider  = StateProvider<String>((ref) => '');
final displayQueryProvider = StateProvider<String>((ref) => '');
final statusFilterProvider = StateProvider<String>((ref) => 'All');

// ── Raw task list from API ─────────────────────────────────────────────────
// Only re-fetches when the debounced searchQueryProvider or statusFilter changes
final taskListProvider = FutureProvider<List<Task>>((ref) async {
  final api    = ref.watch(apiServiceProvider);
  final search = ref.watch(searchQueryProvider);
  final status = ref.watch(statusFilterProvider);

  return api.getTasks(search: search, status: status);
});

// ── Filtered task list ─────────────────────────────────────────────────────
// Applies the instant displayQuery client-side so the list updates on every
// keystroke without waiting for the API, giving instant visual feedback.
final filteredTaskListProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final taskAsync    = ref.watch(taskListProvider);
  final displayQuery = ref.watch(displayQueryProvider).toLowerCase().trim();

  return taskAsync.whenData((tasks) {
    if (displayQuery.isEmpty) return tasks;
    return tasks.where((t) {
      return t.title.toLowerCase().contains(displayQuery) ||
             t.description.toLowerCase().contains(displayQuery);
    }).toList();
  });
});

// ── Task notifier ──────────────────────────────────────────────────────────
// Handles all write operations (create, update, delete, reorder)
// After each operation, it invalidates taskListProvider so the UI refreshes
class TaskNotifier extends Notifier<void> {
  @override
  void build() {}  // no initial state needed — we just expose methods

  ApiService get _api => ref.read(apiServiceProvider);

  // Create a new task and refresh the list
  Future<void> createTask(Map<String, dynamic> data) async {
    await _api.createTask(data);
    ref.invalidate(taskListProvider);
  }

  // Update an existing task and refresh the list
  Future<void> updateTask(int id, Map<String, dynamic> data) async {
    await _api.updateTask(id, data);
    ref.invalidate(taskListProvider);
  }

  // Delete a task and refresh the list
  Future<void> deleteTask(int id) async {
    await _api.deleteTask(id);
    ref.invalidate(taskListProvider);
  }

  // Reorder tasks — sends new positions to backend, then refreshes
  Future<void> reorderTasks(List<Task> tasks) async {
    final reorderData = tasks.asMap().entries.map((entry) => {
      'id':       entry.value.id,
      'position': entry.key,
    }).toList();

    await _api.reorderTasks(reorderData);
    ref.invalidate(taskListProvider);
  }
}

// This is the provider the UI uses to call create/update/delete/reorder
final taskNotifierProvider = NotifierProvider<TaskNotifier, void>(
  TaskNotifier.new,
);