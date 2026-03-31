import 'package:dio/dio.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class ApiService {
  // Dio is our HTTP client — more powerful than Flutter's built-in http
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      // connectTimeout: how long to wait for server to respond
      // receiveTimeout: how long to wait for data to arrive
      // We set 10 seconds because POST/PUT have a 2s server-side delay
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // ── GET /tasks ─────────────────────────────────────────────────────────────
  // Fetches all tasks. Optionally filters by search text and/or status.
  Future<List<Task>> getTasks({
    String? search,
    String? status,
  }) async {
    try {
      // Build query parameters — only add them if they have values
      final Map<String, dynamic> params = {};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null && status != 'All')   params['status'] = status;

      final response = await _dio.get(
        '/tasks',
        queryParameters: params,
      );

      // response.data is a List of maps — convert each one to a Task object
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST /tasks ────────────────────────────────────────────────────────────
  // Creates a new task. Will take ~2 seconds due to server delay.
  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post('/tasks', data: taskData);
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PUT /tasks/{id} ────────────────────────────────────────────────────────
  // Updates an existing task. Will take ~2 seconds due to server delay.
  Future<Task> updateTask(int id, Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.put('/tasks/$id', data: taskData);
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE /tasks/{id} ─────────────────────────────────────────────────────
  // Deletes a task permanently.
  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete('/tasks/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PATCH /tasks/reorder ───────────────────────────────────────────────────
  // Stretch goal: saves new drag-and-drop order to the backend.
  // Sends a list of {id, position} pairs.
  Future<void> reorderTasks(List<Map<String, dynamic>> reorderData) async {
    try {
      await _dio.patch('/tasks/reorder', data: reorderData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error handler ──────────────────────────────────────────────────────────
  // Converts raw Dio errors into readable messages for the UI
  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timed out. Is the server running?');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('Cannot reach server. Check your connection.');
    }
    if (e.response != null) {
      final status = e.response!.statusCode;
      final detail = e.response!.data?['detail'] ?? 'Unknown error';
      return Exception('Server error $status: $detail');
    }
    return Exception('Unexpected error: ${e.message}');
  }
}