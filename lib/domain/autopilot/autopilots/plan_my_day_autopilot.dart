import 'package:uuid/uuid.dart';
import '../autopilot_models.dart';
import '../autopilot_engine.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../assistant/context/context_models.dart';
import '../../../core/utils/logger.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../services/google_tasks/google_tasks_service.dart';

/// Plan My Day Autopilot
///
/// Automatically organizes the user's day by:
/// - Analyzing calendar events
/// - Reviewing tasks and priorities
/// - Scheduling focus time
/// - Adding breaks
/// - Setting up reminders
class PlanMyDayAutopilot {
  static final PlanMyDayAutopilot _instance = PlanMyDayAutopilot._internal();
  static PlanMyDayAutopilot get instance => _instance;

  PlanMyDayAutopilot._internal();

  final _uuid = const Uuid();

  /// Generate a "Plan My Day" autopilot plan
  Future<AutopilotPlan> generatePlan({
    DateTime? targetDate,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final date = targetDate ?? DateTime.now();
      AppLogger.info('Generating Plan My Day autopilot for ${date.toString().split(' ')[0]}');

      // Get context for the day
      final context = await ContextEngine.instance.getTodayContext(forceRefresh: true);
      final priorities = await ContextEngine.instance.getTopPriorities(limit: 5);

      // Build actions based on context
      final actions = await _buildDayPlanActions(context, priorities, preferences);

      final plan = AutopilotPlan(
        id: _uuid.v4(),
        intentId: _uuid.v4(),
        planName: 'Plan My Day - ${_formatDate(date)}',
        description: 'Automatically organize your day with optimized scheduling',
        actions: actions,
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      AppLogger.info('Generated Plan My Day with ${actions.length} actions');
      return plan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate Plan My Day', e, stackTrace);
      rethrow;
    }
  }

  /// Build actions for the day plan
  Future<List<AutopilotAction>> _buildDayPlanActions(
    LifeContext context,
    List<PriorityItem> priorities,
    Map<String, dynamic>? preferences,
  ) async {
    final actions = <AutopilotAction>[];
    int stepNumber = 1;

    // 1. Morning review task
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createTask,
      description: 'Morning Review: Check priorities and goals for the day',
      parameters: {
        'title': 'Morning Review',
        'due': DateTime.now().add(const Duration(hours: 1)),
        'notes': 'Review top priorities:\n${priorities.take(3).map((p) => '- ${p.title}').join('\n')}',
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 2. Schedule focus time blocks
    if (context.calendarContext.todayEvents.length < 5) {
      // Only add focus time if day isn't too packed
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createEvent,
        description: 'Block focus time (2 hours) for deep work',
        parameters: {
          'title': '🎯 Focus Time - Deep Work',
          'startTime': _findBestFocusTime(context),
          'duration': 120, // 2 hours
          'description': 'Dedicated time for focused, uninterrupted work',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 3. Add break reminders if stress is high
    if (context.stressLevel > 0.6) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.setReminder,
        description: 'Set reminders for regular breaks (every 90 minutes)',
        parameters: {
          'title': 'Take a Break',
          'interval': 90, // minutes
          'message': 'Time for a 10-minute break. Stretch, hydrate, breathe!',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 4. Create tasks for top priorities
    for (final priority in priorities.take(3)) {
      if (priority.type != 'task') {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.createTask,
          description: 'Add task: ${priority.title}',
          parameters: {
            'title': priority.title,
            'due': priority.dueDate,
            'notes': priority.description ?? '',
            'priority': priority.priority,
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 5. Schedule time for urgent exams/assignments
    if (context.studentContext.upcomingExams.isNotEmpty) {
      final nextExam = context.studentContext.upcomingExams.first;
      final daysUntil = nextExam.examDate.difference(DateTime.now()).inDays;

      if (daysUntil <= 7) {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.createEvent,
          description: 'Schedule study time for ${nextExam.examName}',
          parameters: {
            'title': '📚 Study: ${nextExam.examName}',
            'startTime': _findBestStudyTime(context),
            'duration': 90,
            'description': 'Prepare for ${nextExam.courseName} exam on ${_formatDate(nextExam.examDate)}',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 6. Evening wind-down reminder
    if (preferences?['includeEvening'] != false) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.setReminder,
        description: 'Set evening wind-down reminder',
        parameters: {
          'title': 'Evening Wind-Down',
          'time': DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 0),
          'message': 'Time to review your day and prepare for tomorrow',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 7. Add weather-based suggestions
    if (context.environmentContext.weather != null) {
      final weather = context.environmentContext.weather!;
      if (weather.description.toLowerCase().contains('rain')) {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.createNote,
          description: 'Add reminder: Bring umbrella ☂️',
          parameters: {
            'title': 'Weather Alert',
            'content': 'Rain expected today (${weather.description}). Don\'t forget your umbrella!',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    return actions;
  }

  /// Find the best time for focus work (avoiding meetings)
  DateTime _findBestFocusTime(LifeContext context) {
    final now = DateTime.now();
    final events = context.calendarContext.todayEvents;

    // Prefer morning (9-11 AM) for focus time
    var focusStart = DateTime(now.year, now.month, now.day, 9, 0);

    // Check if 9-11 AM is free
    final hasConflict = events.any((event) {
      return event.startTime.isBefore(focusStart.add(const Duration(hours: 2))) &&
          event.endTime.isAfter(focusStart);
    });

    if (!hasConflict) {
      return focusStart;
    }

    // Try afternoon (2-4 PM)
    focusStart = DateTime(now.year, now.month, now.day, 14, 0);
    return focusStart;
  }

  /// Find the best time for studying
  DateTime _findBestStudyTime(LifeContext context) {
    final now = DateTime.now();

    // Prefer late afternoon (4-5:30 PM) for studying
    return DateTime(now.year, now.month, now.day, 16, 0);
  }

  String _formatDate(DateTime date) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
    return '$weekday, $month ${date.day}';
  }

  /// Execute the plan
  Future<AutopilotResult> execute(AutopilotPlan plan) async {
    return await AutopilotEngine.instance.executePlan(plan.id);
  }

  /// Simulate the plan (preview mode)
  Future<AutopilotResult> simulate(AutopilotPlan plan) async {
    return await AutopilotEngine.instance.simulatePlan(plan.id);
  }
}
