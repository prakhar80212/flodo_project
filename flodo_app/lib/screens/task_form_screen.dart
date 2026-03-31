import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/constants.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  // If task is null we are creating. If not null we are editing.
  final Task? task;
  final List<Task> allTasks;

  const TaskFormScreen({
    super.key,
    this.task,
    required this.allTasks,
  });

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {

  // Controllers hold the text the user types in each field
  late TextEditingController _titleController;
  late TextEditingController _descController;

  // Form key lets us validate all fields at once
  final _formKey = GlobalKey<FormState>();

  // State variables
  String  _status          = 'To-Do';
  String? _dueDate;
  int?    _blockedById;
  bool    _isRecurring     = false;
  String? _recurrenceType;
  bool    _isLoading       = false; // true during the 2-second API call

  // Draft keys — used to save/load from SharedPreferences
  static const _draftTitleKey = 'draft_title';
  static const _draftDescKey  = 'draft_desc';

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Editing — pre-fill all fields with existing task data
      _titleController = TextEditingController(text: widget.task!.title);
      _descController  = TextEditingController(text: widget.task!.description);
      _status          = widget.task!.status;
      _dueDate         = widget.task!.dueDate;
      _blockedById     = widget.task!.blockedById;
      _isRecurring     = widget.task!.isRecurring;
      _recurrenceType  = widget.task!.recurrenceType;
    } else {
      // Creating — start empty but load any saved draft
      _titleController = TextEditingController();
      _descController  = TextEditingController();
      _loadDraft();
    }
  }

  // ── Draft: load saved text from SharedPreferences ──────────────────────────
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTitle = prefs.getString(_draftTitleKey) ?? '';
    final savedDesc  = prefs.getString(_draftDescKey)  ?? '';
    if (savedTitle.isNotEmpty || savedDesc.isNotEmpty) {
      setState(() {
        _titleController.text = savedTitle;
        _descController.text  = savedDesc;
      });
    }
  }

  // ── Draft: save current text to SharedPreferences ──────────────────────────
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTitleKey, _titleController.text);
    await prefs.setString(_draftDescKey,  _descController.text);
  }

  // ── Draft: clear after successful save ────────────────────────────────────
  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTitleKey);
    await prefs.remove(_draftDescKey);
  }

  @override
  void dispose() {
    // Save draft whenever user leaves the screen (back swipe, minimize, etc.)
    if (!_isEditing) _saveDraft();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate != null
          ? DateTime.parse(_dueDate!)
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ── Save (create or update) ────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return; // prevent double-tap

    setState(() => _isLoading = true);

    final data = {
      'title':           _titleController.text.trim(),
      'description':     _descController.text.trim(),
      'due_date':        _dueDate,
      'status':          _status,
      'blocked_by_id':   _blockedById,
      'is_recurring':    _isRecurring,
      'recurrence_type': _isRecurring ? _recurrenceType : null,
    };

    try {
      final notifier = ref.read(taskNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateTask(widget.task!.id, data);
      } else {
        await notifier.createTask(data);
        await _clearDraft(); // clear draft after successful creation
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tasks available to be selected as blockers
    // Exclude the current task from the list (can't block itself)
    final blockableTask = widget.allTasks
        .where((t) => t.id != widget.task?.id)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Title field ────────────────────────────────────────────────
            _buildLabel('Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Enter task title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),

            const SizedBox(height: 20),

            // ── Description field ──────────────────────────────────────────
            _buildLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              decoration: _inputDecoration('Optional details...'),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // ── Due date picker ────────────────────────────────────────────
            _buildLabel('Due Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: Colors.grey.shade400),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate ?? 'Select a date',
                      style: TextStyle(
                        color: _dueDate != null
                            ? Colors.grey.shade800
                            : Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close,
                            size: 16, color: Colors.grey.shade400),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Status dropdown ────────────────────────────────────────────
            _buildLabel('Status'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _status,
              items: AppConstants.statusOptions,
              labelBuilder: (s) => s,
              onChanged: (v) => setState(() => _status = v!),
            ),

            const SizedBox(height: 20),

            // ── Blocked by dropdown ────────────────────────────────────────
            _buildLabel('Blocked By (optional)'),
            const SizedBox(height: 8),
            _buildDropdown<int?>(
              value: _blockedById,
              items: [null, ...blockableTask.map((t) => t.id)],
              labelBuilder: (id) => id == null
                  ? 'None'
                  : blockableTask
                      .firstWhere((t) => t.id == id)
                      .title,
              onChanged: (v) => setState(() => _blockedById = v),
            ),

            const SizedBox(height: 20),

            // ── Recurring toggle ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat,
                          size: 20, color: Colors.indigo),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Recurring Task',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15)),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (v) => setState(() {
                          _isRecurring    = v;
                          _recurrenceType = v ? 'Daily' : null;
                        }),
                        activeThumbColor: Colors.indigo,
                      ),
                    ],
                  ),

                  // Show recurrence type selector only when toggle is ON
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: AppConstants.recurrenceOptions.map((option) {
                        final selected = _recurrenceType == option;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _recurrenceType = option),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.indigo
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                option,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                // Button is null (disabled) when loading
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  disabledBackgroundColor: Colors.indigo.shade200,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Create Task',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helper: section label ──────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Helper: consistent input decoration ───────────────────────────────────
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Helper: reusable dropdown ──────────────────────────────────────────────
  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: Colors.grey.shade400),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}