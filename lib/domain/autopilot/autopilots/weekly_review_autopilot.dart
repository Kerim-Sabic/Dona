import 'package:uuid/uuid.dart';
import '../autopilot_models.dart';
import '../autopilot_engine.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../assistant/context/context_models.dart';
import '../../../core/utils/logger.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../services/google_tasks/google_tasks_service.dart';

/// Weekly Review Autopilot
///
/// Helps users reflect on the past week and plan the upcoming week by:
/// - Summarizing tasks completed vs created
/// - Reviewing events attended
/// - Identifying overdue tasks
/// - Highlighting upcoming critical deadlines
/// - Suggesting weekly goals and focus blocks
/// - Creating tasks/events for chosen goals
class WeeklyReviewAutopilot {
  static final WeeklyReviewAutopilot _instance = WeeklyReviewAutopilot._internal();
  static WeeklyReviewAutopilot get instance => _instance;

  WeeklyReviewAutopilot._internal();

  final _uuid = const Uuid();

  /// Generate a Weekly Review autopilot plan
  Future<AutopilotPlan> generatePlan({
    DateTime? reviewDate,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final date = reviewDate ?? DateTime.now();
      AppLogger.info('Generating Weekly Review autopilot for week of ${date.toString().split(' ')[0]}');

      // Get data for analysis
      final analysis = await _analyzeWeek(date);

      // Build actions based on analysis
      final actions = await _buildWeeklyReviewActions(analysis, preferences);

      final plan = AutopilotPlan(
        id: _uuid.v4(),
        intentId: _uuid.v4(),
        planName: 'Weekly Review - ${_formatWeekRange(date)}',
        description: 'Review last week and plan the upcoming week',
        actions: actions,
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      AppLogger.info('Generated Weekly Review with ${actions.length} actions');
      return plan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate Weekly Review', e, stackTrace);
      rethrow;
    }
  }

  /// Analyze the past week
  Future<WeekAnalysis> _analyzeWeek(DateTime date) async {
    try {
      // Get tasks from last 7 days
      final tasks = await GoogleTasksService.instance.getTasks();
      final lastWeek = date.subtract(const Duration(days: 7));

      final completedTasks = tasks.where((t) =>
        t.completed != null &&
        t.completed!.isAfter(lastWeek) &&
        t.completed!.isBefore(date)
      ).toList();

      final createdTasks = tasks.where((t) =>
        t.createdAt.isAfter(lastWeek) &&
        t.createdAt.isBefore(date)
      ).toList();

      final overdueTasks = tasks.where((t) =>
        t.dueDate != null &&
        t.dueDate!.isBefore(DateTime.now()) &&
        !t.isCompleted
      ).toList();

      // Get events from last 7 days
      final events = await CalendarService.instance.getEvents(
        startDate: lastWeek,
        endDate: date,
      );

      // Get upcoming events (next 7 days)
      final upcomingEvents = await CalendarService.instance.getEvents(
        startDate: date,
        endDate: date.add(const Duration(days: 7)),
      );

      // Get critical upcoming deadlines
      final criticalDeadlines = upcomingEvents.where((e) =>
        e.summary.toLowerCase().contains('deadline') ||
        e.summary.toLowerCase().contains('due') ||
        e.summary.toLowerCase().contains('review')
      ).toList();

      return WeekAnalysis(
        completedTasksCount: completedTasks.length,
        createdTasksCount: createdTasks.length,
        overdueTasksCount: overdueTasks.length,
        eventsAttendedCount: events.length,
        upcomingEventsCount: upcomingEvents.length,
        criticalDeadlinesCount: criticalDeadlines.length,
        completedTasks: completedTasks,
        overdueTasks: overdueTasks,
        criticalDeadlines: criticalDeadlines,
        upcomingEvents: upcomingEvents.take(5).toList(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to analyze week', e, stackTrace);
      return WeekAnalysis.empty();
    }
  }

  /// Build actions for weekly review
  Future<List<AutopilotAction>> _buildWeeklyReviewActions(
    WeekAnalysis analysis,
    Map<String, dynamic>? preferences,
  ) async {
    final actions = <AutopilotAction>[];
    int stepNumber = 1;

    // 1. Create summary note
    final summary = _buildWeeklySummary(analysis);
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createNote,
      description: 'Create weekly summary note',
      parameters: {
        'title': 'Weekly Review - ${_formatWeekRange(DateTime.now())}',
        'content': summary,
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 2. Reschedule overdue tasks if any
    if (analysis.overdueTasksCount > 0) {
      for (final task in analysis.overdueTasks.take(3)) {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.updateTask,
          description: 'Reschedule overdue: ${task.title}',
          parameters: {
            'taskId': task.id,
            'newDueDate': DateTime.now().add(const Duration(days: 2)),
            'addNote': 'Rescheduled during weekly review',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 3. Suggest weekly goals (3-5 major goals)
    final suggestedGoals = _suggestWeeklyGoals(analysis);
    for (final goal in suggestedGoals.take(5)) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createTask,
        description: 'Weekly Goal: $goal',
        parameters: {
          'title': '🎯 $goal',
          'due': DateTime.now().add(const Duration(days: 7)),
          'notes': 'Weekly goal set during review',
          'priority': 'high',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 4. Schedule focus blocks for key projects (2-3 blocks)
    final focusBlocks = _suggestFocusBlocks(analysis);
    for (final block in focusBlocks.take(2)) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createEvent,
        description: 'Schedule focus block: ${block['title']}',
        parameters: {
          'title': '🎯 ${block['title']}',
          'startTime': block['startTime'],
          'duration': 120, // 2 hours
          'description': block['description'],
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 5. Create tasks for critical deadlines preparation
    for (final deadline in analysis.criticalDeadlines.take(2)) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createTask,
        description: 'Prepare for: ${deadline.summary}',
        parameters: {
          'title': 'Prepare: ${deadline.summary}',
          'due': deadline.start.subtract(const Duration(days: 1)),
          'notes': 'Deadline preparation task created during weekly review',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 6. Schedule next weekly review
    if (preferences?['scheduleNextReview'] != false) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createEvent,
        description: 'Schedule next weekly review',
        parameters: {
          'title': '📊 Weekly Review',
          'startTime': DateTime.now().add(const Duration(days: 7)),
          'duration': 30,
          'description': 'Review last week and plan upcoming week',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    return actions;
  }

  /// Build weekly summary text
  String _buildWeeklySummary(WeekAnalysis analysis) {
    final buffer = StringBuffer();

    buffer.writeln('# Last Week Highlights\n');
    buffer.writeln('✅ Tasks Completed: ${analysis.completedTasksCount}');
    buffer.writeln('📝 Tasks Created: ${analysis.createdTasksCount}');
    buffer.writeln('📅 Events Attended: ${analysis.eventsAttendedCount}');

    if (analysis.overdueTasksCount > 0) {
      buffer.writeln('⚠️ Overdue Tasks: ${analysis.overdueTasksCount}');
    }

    buffer.writeln('\n# Upcoming Week\n');
    buffer.writeln('📅 Events Scheduled: ${analysis.upcomingEventsCount}');

    if (analysis.criticalDeadlinesCount > 0) {
      buffer.writeln('🔴 Critical Deadlines: ${analysis.criticalDeadlinesCount}');
    }

    if (analysis.upcomingEvents.isNotEmpty) {
      buffer.writeln('\n## Key Events:');
      for (final event in analysis.upcomingEvents.take(3)) {
        buffer.writeln('- ${event.summary} (${_formatDate(event.start)})');
      }
    }

    buffer.writeln('\n---\nGenerated by Dona Weekly Review');

    return buffer.toString();
  }

  /// Suggest weekly goals based on analysis
  List<String> _suggestWeeklyGoals(WeekAnalysis analysis) {
    final goals = <String>[];

    // Goal based on overdue tasks
    if (analysis.overdueTasksCount > 0) {
      goals.add('Clear ${analysis.overdueTasksCount} overdue task${analysis.overdueTasksCount > 1 ? 's' : ''}');
    }

    // Goal based on critical deadlines
    if (analysis.criticalDeadlinesCount > 0) {
      goals.add('Prepare for ${analysis.criticalDeadlinesCount} upcoming deadline${analysis.criticalDeadlinesCount > 1 ? 's' : ''}');
    }

    // Generic productivity goals
    goals.add('Complete 3 high-priority tasks');
    goals.add('Maintain daily focus sessions');
    goals.add('Review and plan each morning');

    return goals;
  }

  /// Suggest focus blocks for the week
  List<Map<String, dynamic>> _suggestFocusBlocks(WeekAnalysis analysis) {
    final blocks = <Map<String, dynamic>>[];

    // Monday deep work
    final monday = _getNextWeekday(1);
    blocks.add({
      'title': 'Deep Work - Strategic Projects',
      'startTime': DateTime(monday.year, monday.month, monday.day, 9, 0),
      'description': 'Focus on high-leverage strategic work',
    });

    // Wednesday deep work
    final wednesday = _getNextWeekday(3);
    blocks.add({
      'title': 'Deep Work - Creative Work',
      'startTime': DateTime(wednesday.year, wednesday.month, wednesday.day, 14, 0),
      'description': 'Focus on creative and planning tasks',
    });

    // Friday review prep
    final friday = _getNextWeekday(5);
    blocks.add({
      'title': 'Weekly Wrap-up & Planning',
      'startTime': DateTime(friday.year, friday.month, friday.day, 16, 0),
      'description': 'Review week progress and prepare for next week',
    });

    return blocks;
  }

  /// Get next occurrence of a weekday (1 = Monday, 7 = Sunday)
  DateTime _getNextWeekday(int weekday) {
    final now = DateTime.now();
    int daysUntil = weekday - now.weekday;
    if (daysUntil <= 0) {
      daysUntil += 7;
    }
    return now.add(Duration(days: daysUntil));
  }

  /// Format date as "MMM d"
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Format week range as "MMM d - MMM d"
  String _formatWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}';
  }
}

/// Week analysis data
class WeekAnalysis {
  final int completedTasksCount;
  final int createdTasksCount;
  final int overdueTasksCount;
  final int eventsAttendedCount;
  final int upcomingEventsCount;
  final int criticalDeadlinesCount;
  final List<dynamic> completedTasks;
  final List<dynamic> overdueTasks;
  final List<dynamic> criticalDeadlines;
  final List<dynamic> upcomingEvents;

  const WeekAnalysis({
    required this.completedTasksCount,
    required this.createdTasksCount,
    required this.overdueTasksCount,
    required this.eventsAttendedCount,
    required this.upcomingEventsCount,
    required this.criticalDeadlinesCount,
    required this.completedTasks,
    required this.overdueTasks,
    required this.criticalDeadlines,
    required this.upcomingEvents,
  });

  factory WeekAnalysis.empty() {
    return const WeekAnalysis(
      completedTasksCount: 0,
      createdTasksCount: 0,
      overdueTasksCount: 0,
      eventsAttendedCount: 0,
      upcomingEventsCount: 0,
      criticalDeadlinesCount: 0,
      completedTasks: [],
      overdueTasks: [],
      criticalDeadlines: [],
      upcomingEvents: [],
    );
  }
}
