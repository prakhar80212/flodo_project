class AppConstants {
  // When running on Android emulator, 10.0.2.2 is how the emulator
  // reaches your computer's localhost. If you use a real phone,
  // replace this with your computer's actual local IP (e.g. 192.168.1.5)
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Task status options — defined once, used everywhere
  static const List<String> statusOptions = [
    'To-Do',
    'In Progress',
    'Done',
  ];

  // Recurrence options for stretch goal
  static const List<String> recurrenceOptions = [
    'Daily',
    'Weekly',
  ];

  // Debounce delay for search (stretch goal)
  static const int searchDebounceMs = 300;
}