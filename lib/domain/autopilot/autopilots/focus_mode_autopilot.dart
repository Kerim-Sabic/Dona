import 'package:uuid/uuid.dart';
import '../autopilot_models.dart';
import '../autopilot_engine.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../assistant/context/context_models.dart';
import '../../../core/utils/logger.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../services/google_tasks/google_tasks_service.dart';

/// Focus Mode Autopilot
///
/// Creates and manages deep work sessions by:
/// - Validating available time (checking for conflicts)
/// - Proposing Pomodoro-style focus blocks
/// - Scheduling calendar events for focused work
/// - Creating session tasks to track work
/// - Setting up break reminders
/// - Optionally marking tasks to work on during session
class FocusModeAutopilot {
  static final FocusModeAutopilot _instance = FocusModeAutopilot._internal();
  static FocusModeAutopilot get instance => _instance;

  FocusModeAutopilot._internal();

  final _uuid = const Uuid();

  /// Generate a Focus Mode autopilot plan
  Future<AutopilotPlan> generatePlan({
    DateTime? startTime,
    int? durationMinutes,
    String? focusOn,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final start = startTime ?? _findNextAvailableSlot();
      final duration = durationMinutes ?? 120; // Default 2 hours
      final sessionName = focusOn ?? 'Deep Work';

      AppLogger.info('Generating Focus Mode autopilot: $duration min session on $sessionName');

      // Get context to check conflicts
      final context = await ContextEngine.instance.getTodayContext(forceRefresh: true);

      // Validate time availability
      final conflicts = await _checkConflicts(start, duration);

      if (conflicts.isNotEmpty && preferences?['forceSchedule'] != true) {
        throw AutopilotException(
          'Time slot has ${conflicts.length} conflict(s). '
          'Choose a different time or enable force schedule.'
        );
      }

      // Build focus session actions
      final actions = await _buildFocusSessionActions(
        start,
        duration,
        sessionName,
        context,
        preferences,
      );

      final plan = AutopilotPlan(
        id: _uuid.v4(),
        intentId: _uuid.v4(),
        planName: 'Focus Session - $sessionName',
        description: 'Deep work session ($duration min) starting ${_formatTime(start)}',
        actions: actions,
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      AppLogger.info('Generated Focus Mode with ${actions.length} actions');
      return plan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate Focus Mode', e, stackTrace);
      rethrow;
    }
  }

  /// Check for calendar conflicts
  Future<List<dynamic>> _checkConflicts(DateTime start, int durationMinutes) async {
    try {
      final end = start.add(Duration(minutes: durationMinutes));
      final events = await CalendarService.instance.getEvents(
        startDate: start,
        endDate: end,
      );

      // Filter to only overlapping events
      return events.where((event) {
        final eventStart = event.start;
        final eventEnd = event.end ?? eventStart.add(const Duration(hours: 1));

        // Check for overlap
        return (eventStart.isBefore(end) && eventEnd.isAfter(start));
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check conflicts', e, stackTrace);
      return [];
    }
  }

  /// Find next available time slot for focus work
  DateTime _findNextAvailableSlot() {
    final now = DateTime.now();

    // Prefer morning slots (9-11 AM)
    if (now.hour < 9) {
      return DateTime(now.year, now.month, now.day, 9, 0);
    }
    // Or afternoon slots (2-4 PM)
    else if (now.hour < 14) {
      return DateTime(now.year, now.month, now.day, 14, 0);
    }
    // Or next morning
    else {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    }
  }

  /// Build actions for focus session
  Future<List<AutopilotAction>> _buildFocusSessionActions(
    DateTime start,
    int duration,
    String sessionName,
    LifeContext context,
    Map<String, dynamic>? preferences,
  ) async {
    final actions = <AutopilotAction>[];
    int stepNumber = 1;

    // Determine Pomodoro structure based on duration
    final pomodoros = _calculatePomodoros(duration);

    // 1. Create main focus event
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createEvent,
      description: 'Block calendar for focus session',
      parameters: {
        'title': '🎯 Focus: $sessionName',
        'startTime': start.millisecondsSinceEpoch,
        'duration': duration,
        'description': 'Deep work session - ${pomodoros['blocks']} × ${pomodoros['workMinutes']} min work blocks',
        'colorId': '9', // Blue color for focus
        'reminders': [
          {'method': 'popup', 'minutes': 5},
        ],
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 2. Create session task to track what was accomplished
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createTask,
      description: 'Create focus session tracking task',
      parameters: {
        'title': '✅ Focus Session: $sessionName',
        'due': start.add(Duration(minutes: duration)),
        'notes': 'Track accomplishments from this focus session:\n- \n- \n- ',
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 3. Add break reminders between Pomodoros
    if (pomodoros['blocks'] > 1) {
      for (int i = 1; i < pomodoros['blocks']; i++) {
        final breakTime = start.add(Duration(
          minutes: i * (pomodoros['workMinutes'] + pomodoros['breakMinutes']),
        ));

        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.setReminder,
          description: 'Set break reminder ${i} of ${pomodoros['blocks'] - 1}',
          parameters: {
            'title': '⏸️ Break Time',
            'time': breakTime.millisecondsSinceEpoch,
            'message': 'Take a ${pomodoros['breakMinutes']}-min break. Stretch, hydrate, rest your eyes!',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 4. Add tasks to work on (if specified or from priorities)
    final tasksToWork = await _selectTasksForSession(context, sessionName, preferences);
    if (tasksToWork.isNotEmpty) {
      for (final task in tasksToWork.take(3)) {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.createNote,
          description: 'Add to session agenda: ${task['title']}',
          parameters: {
            'title': 'Focus Session Agenda',
            'content': '• ${task['title']}\n  Priority: ${task['priority']}\n  Notes: ${task['notes'] ?? 'N/A'}',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 5. Pre-session preparation reminder (5 min before)
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.setReminder,
      description: 'Set pre-session preparation reminder',
      parameters: {
        'title': '🎯 Focus Session Starting Soon',
        'time': start.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        'message': 'Focus session in 5 minutes. Close distractions, gather materials, set DND mode.',
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 6. Post-session review reminder
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.setReminder,
      description: 'Set post-session review reminder',
      parameters: {
        'title': '📝 Review Focus Session',
        'time': start.add(Duration(minutes: duration + 10)).millisecondsSinceEpoch,
        'message': 'Take 5 minutes to note what you accomplished and next steps.',
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    return actions;
  }

  /// Calculate Pomodoro structure based on total duration
  Map<String, int> _calculatePomodoros(int totalMinutes) {
    if (totalMinutes <= 60) {
      // Single 50-min block
      return {'blocks': 1, 'workMinutes': 50, 'breakMinutes': 10};
    } else if (totalMinutes <= 120) {
      // Two 50-min blocks with 10-min break
      return {'blocks': 2, 'workMinutes': 50, 'breakMinutes': 10};
    } else if (totalMinutes <= 180) {
      // Three 50-min blocks with 10-min breaks
      return {'blocks': 3, 'workMinutes': 50, 'breakMinutes': 10};
    } else {
      // Four 50-min blocks with 10-min breaks (plus longer break mid-way)
      return {'blocks': 4, 'workMinutes': 50, 'breakMinutes': 10};
    }
  }

  /// Select tasks to work on during session
  Future<List<Map<String, dynamic>>> _selectTasksForSession(
    LifeContext context,
    String sessionName,
    Map<String, dynamic>? preferences,
  ) async {
    try {
      // If specific tasks provided in preferences
      if (preferences?['taskIds'] != null) {
        final taskIds = preferences!['taskIds'] as List<String>;
        final allTasks = await GoogleTasksService.instance.getTasks();
        return allTasks
            .where((t) => taskIds.contains(t.id))
            .map((t) => {
              'id': t.id,
              'title': t.title,
              'priority': 'high',
              'notes': t.notes,
            })
            .toList();
      }

      // Otherwise, suggest from priorities
      final priorities = await ContextEngine.instance.getTopPriorities(limit: 5);
      return priorities
          .take(3)
          .map((p) => {
            'title': p.title,
            'priority': p.priority,
            'notes': p.description,
          })
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to select tasks for session', e, stackTrace);
      return [];
    }
  }

  /// Format time as "h:mm AM/PM"
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Custom exception for autopilot errors
class AutopilotException implements Exception {
  final String message;
  const AutopilotException(this.message);

  @override
  String toString() => 'AutopilotException: $message';
}
