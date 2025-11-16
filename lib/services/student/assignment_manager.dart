import 'dart:convert';
import '../../core/utils/logger.dart';
import '../../data/models/student/assignment.dart';
import '../../data/models/student/course.dart';
import '../storage/local_storage_service.dart';
import '../calendar/calendar_service.dart';
import '../notifications/smart_notification_service.dart';
import '../ai/ai_service.dart';
import '../../data/models/calendar_event.dart';
import 'course_manager.dart';

/// Assignment Manager Service
/// Manages all assignments with AI-powered features
class AssignmentManager {
  static final AssignmentManager _instance = AssignmentManager._internal();
  static AssignmentManager get instance => _instance;

  AssignmentManager._internal();

  List<Assignment> _assignments = [];
  final Map<String, Duration> _typicalDurations = {};  // Track actual time taken

  /// Initialize assignment manager
  Future<void> init() async {
    try {
      await _loadAssignments();
      await _loadTypicalDurations();
      AppLogger.info('AssignmentManager initialized with ${_assignments.length} assignments');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AssignmentManager', e, stackTrace);
    }
  }

  /// Add a new assignment
  Future<Assignment> addAssignment({
    required String courseId,
    required String title,
    String? description,
    required AssignmentType type,
    required DateTime dueDate,
    Priority priority = Priority.medium,
    Duration? estimatedTime,
    List<Subtask>? subtasks,
    double? totalPoints,
    List<String>? attachments,
  }) async {
    try {
      // AI-suggested estimated time if not provided
      if (estimatedTime == null) {
        estimatedTime = await _suggestEstimatedTime(type, description ?? title);
      }

      final assignment = Assignment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId,
        title: title,
        description: description,
        type: type,
        dueDate: dueDate,
        priority: priority,
        estimatedTime: estimatedTime,
        subtasks: subtasks ?? [],
        totalPoints: totalPoints,
        attachments: attachments ?? [],
        created: DateTime.now(),
      );

      _assignments.add(assignment);
      await _saveAssignments();

      // Schedule smart reminders
      await _scheduleReminders(assignment);

      // Sync to calendar if major assignment
      if (type == AssignmentType.project || type == AssignmentType.exam || type == AssignmentType.final_exam) {
        await _syncToCalendar(assignment);
      }

      AppLogger.info('Added assignment: $title');
      return assignment;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding assignment', e, stackTrace);
      rethrow;
    }
  }

  /// Update assignment
  Future<void> updateAssignment(Assignment assignment) async {
    try {
      final index = _assignments.indexWhere((a) => a.id == assignment.id);
      if (index != -1) {
        _assignments[index] = assignment;
        await _saveAssignments();

        // Update reminders if due date changed
        await _scheduleReminders(assignment);

        AppLogger.info('Updated assignment: ${assignment.title}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating assignment', e, stackTrace);
      rethrow;
    }
  }

  /// Delete assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      final removedCount = _assignments.removeWhere((a) => a.id == assignmentId);
      if (removedCount > 0) {
        await _saveAssignments();
        AppLogger.info('Deleted assignment: $assignmentId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting assignment', e, stackTrace);
      return false;
    }
  }

  /// Complete assignment
  Future<void> completeAssignment(String assignmentId, {double? earnedPoints}) async {
    final assignment = getAssignment(assignmentId);
    if (assignment != null) {
      final completed = assignment.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
        completionPercentage: 100,
        earnedPoints: earnedPoints,
      );
      await updateAssignment(completed);

      // Track actual time taken for future estimates
      if (assignment.estimatedTime != null) {
        final actualTime = DateTime.now().difference(assignment.created);
        _typicalDurations['${assignment.type}_${assignment.courseId}'] = actualTime;
        await _saveTypicalDurations();
      }
    }
  }

  /// Update progress
  Future<void> updateProgress(String assignmentId, int percentage) async {
    final assignment = getAssignment(assignmentId);
    if (assignment != null) {
      await updateAssignment(assignment.copyWith(completionPercentage: percentage));
    }
  }

  /// AI-powered task breakdown
  Future<List<Subtask>> breakdownIntoSubtasks(Assignment assignment) async {
    try {
      AppLogger.info('Generating subtasks for: ${assignment.title}');

      final prompt = '''
Break down this assignment into 3-5 manageable subtasks:

Title: ${assignment.title}
Description: ${assignment.description ?? 'No description'}
Type: ${assignment.type.displayName}
Due Date: ${assignment.dueDate}

Requirements:
- Return ONLY a JSON array of subtasks
- Each subtask should have: "title" (string)
- Subtasks should be actionable and specific
- Order by logical completion sequence

Example format:
[
  {"title": "Research topic and gather sources"},
  {"title": "Create outline"},
  {"title": "Write first draft"}
]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        // Extract JSON from response
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          return data.map((item) => Subtask(
            id: DateTime.now().millisecondsSinceEpoch.toString() + data.indexOf(item).toString(),
            title: item['title'] as String,
          )).toList();
        }
      } catch (e) {
        AppLogger.warning('Could not parse AI subtasks: $e');
      }

      // Fallback: create generic subtasks
      return [
        Subtask(id: '1', title: 'Start ${assignment.title}'),
        Subtask(id: '2', title: 'Complete main work'),
        Subtask(id: '3', title: 'Review and finalize'),
      ];
    } catch (e, stackTrace) {
      AppLogger.error('Error generating subtasks', e, stackTrace);
      return [];
    }
  }

  /// Get assignment by ID
  Assignment? getAssignment(String assignmentId) {
    try {
      return _assignments.firstWhere((a) => a.id == assignmentId);
    } catch (e) {
      return null;
    }
  }

  /// Get all assignments
  List<Assignment> get allAssignments => List.unmodifiable(_assignments);

  /// Get assignments for course
  List<Assignment> getAssignmentsForCourse(String courseId) =>
      _assignments.where((a) => a.courseId == courseId).toList();

  /// Get incomplete assignments
  List<Assignment> get incompleteAssignments =>
      _assignments.where((a) => !a.isCompleted).toList();

  /// Get completed assignments
  List<Assignment> get completedAssignments =>
      _assignments.where((a) => a.isCompleted).toList();

  /// Get overdue assignments
  List<Assignment> get overdueAssignments =>
      _assignments.where((a) => a.isOverdue).toList();

  /// Get assignments due soon (next 7 days)
  List<Assignment> get dueSoonAssignments {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return _assignments.where((a) =>
      !a.isCompleted &&
      a.dueDate.isAfter(now) &&
      a.dueDate.isBefore(weekFromNow)
    ).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Get today's assignments
  List<Assignment> get todaysAssignments {
    final today = DateTime.now();
    return _assignments.where((a) {
      final due = a.dueDate;
      return !a.isCompleted &&
             due.year == today.year &&
             due.month == today.month &&
             due.day == today.day;
    }).toList();
  }

  /// Get assignments by priority
  List<Assignment> getAssignmentsByPriority(Priority priority) =>
      _assignments.where((a) => a.priority == priority && !a.isCompleted).toList();

  /// Get upcoming assignments (sorted by due date)
  List<Assignment> getUpcomingAssignments({int limit = 10}) {
    return incompleteAssignments
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate))
      ..take(limit);
  }

  /// Suggest estimated time based on past data and AI
  Future<Duration> _suggestEstimatedTime(AssignmentType type, String description) async {
    try {
      // First, check if we have historical data
      final key = '${type}_*';  // Match any course for this type
      final historicalTimes = _typicalDurations.entries
          .where((e) => e.key.startsWith(type.toString()))
          .map((e) => e.value)
          .toList();

      if (historicalTimes.isNotEmpty) {
        // Average historical time
        final avgMinutes = historicalTimes
            .map((d) => d.inMinutes)
            .reduce((a, b) => a + b) ~/ historicalTimes.length;
        return Duration(minutes: avgMinutes);
      }

      // Fallback: AI-suggested time
      final prompt = '''
Estimate the time needed to complete this assignment (in hours).
Return ONLY a number (e.g., "2.5" for 2.5 hours).

Type: ${type.displayName}
Description: $description

Consider:
- Assignment type complexity
- Typical student workload
- Research and preparation time
''';

      final response = await AIService.instance.chat(prompt);
      final hoursMatch = RegExp(r'(\d+\.?\d*)').firstMatch(response);

      if (hoursMatch != null) {
        final hours = double.parse(hoursMatch.group(1)!);
        return Duration(minutes: (hours * 60).round());
      }

      // Default estimates by type
      return _getDefaultEstimate(type);
    } catch (e) {
      return _getDefaultEstimate(type);
    }
  }

  Duration _getDefaultEstimate(AssignmentType type) {
    switch (type) {
      case AssignmentType.homework:
        return const Duration(hours: 1);
      case AssignmentType.project:
        return const Duration(hours: 10);
      case AssignmentType.quiz:
        return const Duration(minutes: 30);
      case AssignmentType.exam:
        return const Duration(hours: 2);
      case AssignmentType.midterm:
      case AssignmentType.final_exam:
        return const Duration(hours: 3);
      case AssignmentType.lab:
        return const Duration(hours: 2);
      case AssignmentType.presentation:
        return const Duration(hours: 4);
      case AssignmentType.paper:
        return const Duration(hours: 8);
      case AssignmentType.reading:
        return const Duration(hours: 2);
      case AssignmentType.discussion:
        return const Duration(minutes: 45);
      default:
        return const Duration(hours: 2);
    }
  }

  /// Schedule smart reminders
  Future<void> _scheduleReminders(Assignment assignment) async {
    try {
      if (assignment.isCompleted) return;

      final course = CourseManager.instance.getCourse(assignment.courseId);
      final courseName = course?.code ?? 'Assignment';

      // Reminder schedule based on type and due date
      final reminders = <DateTime>[];
      final now = DateTime.now();

      // For projects and major assignments
      if (assignment.type == AssignmentType.project ||
          assignment.type == AssignmentType.paper) {
        // 1 week before
        final weekBefore = assignment.dueDate.subtract(const Duration(days: 7));
        if (weekBefore.isAfter(now)) reminders.add(weekBefore);

        // 3 days before
        final threeDays = assignment.dueDate.subtract(const Duration(days: 3));
        if (threeDays.isAfter(now)) reminders.add(threeDays);
      }

      // 1 day before (for all)
      final dayBefore = assignment.dueDate.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(now)) reminders.add(dayBefore);

      // 2 hours before (for quizzes/exams)
      if (assignment.type == AssignmentType.quiz ||
          assignment.type == AssignmentType.exam) {
        final twoHours = assignment.dueDate.subtract(const Duration(hours: 2));
        if (twoHours.isAfter(now)) reminders.add(twoHours);
      }

      // Schedule notifications
      for (final reminderTime in reminders) {
        // This would integrate with SmartNotificationService
        // For now, we log it
        AppLogger.debug('Scheduled reminder for ${assignment.title} at $reminderTime');
      }
    } catch (e) {
      AppLogger.warning('Could not schedule reminders', e);
    }
  }

  /// Sync to calendar
  Future<void> _syncToCalendar(Assignment assignment) async {
    try {
      if (!CalendarService.instance.isAuthenticated) return;

      final course = CourseManager.instance.getCourse(assignment.courseId);
      final event = CalendarEvent(
        id: 'assignment_${assignment.id}',
        title: '${assignment.type.emoji} ${assignment.title}',
        description: '${course?.name ?? 'Assignment'}\n${assignment.description ?? ''}',
        startTime: assignment.dueDate.subtract(assignment.estimatedTime ?? const Duration(hours: 2)),
        endTime: assignment.dueDate,
      );

      await CalendarService.instance.createEvent(event);
      AppLogger.debug('Synced assignment to calendar: ${assignment.title}');
    } catch (e) {
      AppLogger.warning('Could not sync to calendar', e);
    }
  }

  /// Get assignment statistics
  AssignmentStatistics getStatistics() {
    return AssignmentStatistics(
      total: _assignments.length,
      completed: completedAssignments.length,
      incomplete: incompleteAssignments.length,
      overdue: overdueAssignments.length,
      dueSoon: dueSoonAssignments.length,
      completionRate: _assignments.isEmpty ? 0 :
          (completedAssignments.length / _assignments.length) * 100,
    );
  }

  /// Save assignments
  Future<void> _saveAssignments() async {
    try {
      final json = jsonEncode(_assignments.map((a) => a.toJson()).toList());
      await LocalStorageService.instance.setString('assignments', json);
      AppLogger.debug('Saved ${_assignments.length} assignments');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving assignments', e, stackTrace);
    }
  }

  /// Load assignments
  Future<void> _loadAssignments() async {
    try {
      final json = LocalStorageService.instance.getString('assignments');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _assignments = data.map((item) => Assignment.fromJson(item)).toList();
        AppLogger.info('Loaded ${_assignments.length} assignments');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading assignments', e, stackTrace);
    }
  }

  /// Save typical durations
  Future<void> _saveTypicalDurations() async {
    try {
      final map = _typicalDurations.map((k, v) => MapEntry(k, v.inMinutes));
      final json = jsonEncode(map);
      await LocalStorageService.instance.setString('assignment_durations', json);
    } catch (e) {
      AppLogger.error('Error saving durations', e);
    }
  }

  /// Load typical durations
  Future<void> _loadTypicalDurations() async {
    try {
      final json = LocalStorageService.instance.getString('assignment_durations');
      if (json != null) {
        final Map<String, dynamic> data = jsonDecode(json);
        _typicalDurations.clear();
        data.forEach((key, value) {
          _typicalDurations[key] = Duration(minutes: value as int);
        });
      }
    } catch (e) {
      AppLogger.error('Error loading durations', e);
    }
  }
}

/// Assignment statistics
class AssignmentStatistics {
  final int total;
  final int completed;
  final int incomplete;
  final int overdue;
  final int dueSoon;
  final double completionRate;

  AssignmentStatistics({
    required this.total,
    required this.completed,
    required this.incomplete,
    required this.overdue,
    required this.dueSoon,
    required this.completionRate,
  });

  @override
  String toString() {
    return '''
Assignment Statistics:
  Total: $total
  Completed: $completed (${ completionRate.toStringAsFixed(1)}%)
  Incomplete: $incomplete
  Overdue: $overdue
  Due Soon: $dueSoon
''';
  }
}
