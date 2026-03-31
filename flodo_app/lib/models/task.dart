class Task {
  final int id;
  final String title;
  final String description;
  final String? dueDate;       // nullable — user may not set a date
  final String status;         // "To-Do", "In Progress", "Done"
  final int? blockedById;      // nullable — task may not be blocked
  final bool isRecurring;
  final String? recurrenceType; // "Daily", "Weekly", or null
  final int position;           // for drag-and-drop ordering
  final DateTime createdAt;
  final DateTime updatedAt;

  // const constructor — means Task objects are immutable (can't change fields)
  // This is important for Riverpod state management
  const Task({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.status,
    this.blockedById,
    required this.isRecurring,
    this.recurrenceType,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  // fromJson — converts the raw JSON map from FastAPI into a Task object
  // Called automatically when we receive API responses
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id:             json['id'] as int,
      title:          json['title'] as String,
      description:    json['description'] as String? ?? '',
      dueDate:        json['due_date'] as String?,
      status:         json['status'] as String,
      blockedById:    json['blocked_by_id'] as int?,
      isRecurring:    json['is_recurring'] as bool? ?? false,
      recurrenceType: json['recurrence_type'] as String?,
      position:       json['position'] as int? ?? 0,
      createdAt:      DateTime.parse(json['created_at'] as String),
      updatedAt:      DateTime.parse(json['updated_at'] as String),
    );
  }

  // toJson — converts a Task object back into a map for sending to FastAPI
  Map<String, dynamic> toJson() {
    return {
      'title':           title,
      'description':     description,
      'due_date':        dueDate,
      'status':          status,
      'blocked_by_id':   blockedById,
      'is_recurring':    isRecurring,
      'recurrence_type': recurrenceType,
      'position':        position,
    };
  }

  // copyWith — creates a new Task with some fields changed
  // This is how Riverpod updates state without mutating the original object
  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
    int? blockedById,
    bool? isRecurring,
    String? recurrenceType,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id:             id             ?? this.id,
      title:          title          ?? this.title,
      description:    description    ?? this.description,
      dueDate:        dueDate        ?? this.dueDate,
      status:         status         ?? this.status,
      blockedById:    blockedById    ?? this.blockedById,
      isRecurring:    isRecurring    ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      position:       position       ?? this.position,
      createdAt:      createdAt      ?? this.createdAt,
      updatedAt:      updatedAt      ?? this.updatedAt,
    );
  }
}