import 'package:uuid/uuid.dart';
import '../autopilot_models.dart';
import '../autopilot_engine.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../assistant/context/context_models.dart';
import '../../../core/utils/logger.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../services/google_tasks/google_tasks_service.dart';

/// Email / Task Triage Autopilot
///
/// Helps users organize their inbox and tasks by:
/// - Reading email metadata (subjects, labels, dates)
/// - Categorizing items into Do Today, Schedule, Delegate, Maybe Later
/// - Suggesting concrete actions (create tasks, events, apply tags)
/// - NEVER sends or deletes emails automatically
/// - Only executes actions user explicitly approves
class TriageAutopilot {
  static final TriageAutopilot _instance = TriageAutopilot._internal();
  static TriageAutopilot get instance => _instance;

  TriageAutopilot._internal();

  final _uuid = const Uuid();

  /// Generate a Triage autopilot plan
  Future<AutopilotPlan> generatePlan({
    String triageType = 'both', // 'tasks', 'inbox', or 'both'
    Map<String, dynamic>? preferences,
  }) async {
    try {
      AppLogger.info('Generating Triage autopilot: $triageType');

      // Analyze tasks and emails
      final analysis = await _analyzeTriageItems(triageType);

      // Build triage suggestions
      final actions = await _buildTriageActions(analysis, triageType, preferences);

      final plan = AutopilotPlan(
        id: _uuid.v4(),
        intentId: _uuid.v4(),
        planName: 'Triage - ${_formatTriageType(triageType)}',
        description: 'Organize and prioritize ${triageType == 'both' ? 'inbox & tasks' : triageType}',
        actions: actions,
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      AppLogger.info('Generated Triage with ${actions.length} actions');
      return plan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate Triage', e, stackTrace);
      rethrow;
    }
  }

  /// Analyze triage items
  Future<TriageAnalysis> _analyzeTriageItems(String triageType) async {
    try {
      final tasks = triageType != 'inbox'
          ? await GoogleTasksService.instance.getTasks()
          : <dynamic>[];

      // Email metadata would come from Gmail API here
      // For now, we'll use placeholder data
      final emails = triageType != 'tasks' ? <dynamic>[] : <dynamic>[];

      // Categorize tasks
      final doTodayTasks = tasks.where((t) =>
        !t.isCompleted &&
        (t.dueDate != null && t.dueDate!.isBefore(DateTime.now().add(const Duration(days: 1))))
      ).toList();

      final scheduleTasks = tasks.where((t) =>
        !t.isCompleted &&
        (t.dueDate == null || t.dueDate!.isAfter(DateTime.now().add(const Duration(days: 1))))
      ).toList();

      final overdueTasks = tasks.where((t) =>
        !t.isCompleted &&
        (t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
      ).toList();

      return TriageAnalysis(
        totalTasks: tasks.length,
        doTodayCount: doTodayTasks.length,
        scheduleCount: scheduleTasks.length,
        overdueCount: overdueTasks.length,
        totalEmails: emails.length,
        doTodayTasks: doTodayTasks,
        scheduleTasks: scheduleTasks.take(5).toList(),
        overdueTasks: overdueTasks,
        emails: emails,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to analyze triage items', e, stackTrace);
      return TriageAnalysis.empty();
    }
  }

  /// Build triage actions
  Future<List<AutopilotAction>> _buildTriageActions(
    TriageAnalysis analysis,
    String triageType,
    Map<String, dynamic>? preferences,
  ) async {
    final actions = <AutopilotAction>[];
    int stepNumber = 1;

    // 1. Create triage summary note
    final summary = _buildTriageSummary(analysis, triageType);
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createNote,
      description: 'Create triage summary',
      parameters: {
        'title': 'Triage Summary - ${_formatDate(DateTime.now())}',
        'content': summary,
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 2. Reschedule overdue tasks
    if (analysis.overdueCount > 0) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createNote,
        description: 'Note ${analysis.overdueCount} overdue tasks need attention',
        parameters: {
          'title': '⚠️ Overdue Tasks Alert',
          'content': '${analysis.overdueCount} overdue tasks require immediate action or rescheduling.',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));

      // Suggest rescheduling top 3 overdue
      for (final task in analysis.overdueTasks.take(3)) {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.updateTask,
          description: 'Reschedule: ${task.title}',
          parameters: {
            'taskId': task.id,
            'newDueDate': DateTime.now().add(const Duration(days: 1)),
            'addNote': 'Rescheduled during triage',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 3. Prioritize "Do Today" tasks
    if (analysis.doTodayCount > 5) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createNote,
        description: 'Suggest narrowing focus to top 3 tasks',
        parameters: {
          'title': '🎯 Focus Today',
          'content': 'You have ${analysis.doTodayCount} tasks due today. '
              'Consider focusing on the top 3 highest-impact items:\n'
              '${analysis.doTodayTasks.take(3).map((t) => '• ${t.title}').join('\n')}',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 4. Schedule tasks without due dates
    if (analysis.scheduleCount > 0) {
      final tasksNeedingDates = analysis.scheduleTasks.where((t) => t.dueDate == null).take(3);
      for (final task in tasksNeedingDates) {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.updateTask,
          description: 'Add due date: ${task.title}',
          parameters: {
            'taskId': task.id,
            'newDueDate': DateTime.now().add(const Duration(days: 3)),
            'addNote': 'Due date added during triage',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 5. Batch similar tasks together
    final batchable = _identifyBatchableTasks(analysis.doTodayTasks);
    if (batchable.isNotEmpty) {
      for (final batch in batchable.take(2)) {
        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: AutopilotActionType.createEvent,
          description: 'Schedule batch: ${batch['name']}',
          parameters: {
            'title': '📦 Batch: ${batch['name']}',
            'startTime': _findBatchTime(),
            'duration': 30,
            'description': 'Process ${batch['count']} ${batch['name']} tasks together',
          },
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    // 6. Delegate/Maybe Later category
    if (analysis.scheduleCount > 10) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createNote,
        description: 'Identify tasks to delegate or defer',
        parameters: {
          'title': '🔄 Delegate / Defer Review',
          'content': 'You have ${analysis.scheduleCount} tasks scheduled. '
              'Consider which can be:\n'
              '• Delegated to others\n'
              '• Moved to "Someday/Maybe"\n'
              '• Deleted if no longer relevant',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 7. Create daily review task
    if (preferences?['dailyReview'] != false) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createTask,
        description: 'Schedule daily triage for tomorrow',
        parameters: {
          'title': '📋 Daily Triage',
          'due': DateTime.now().add(const Duration(days: 1)),
          'notes': 'Review inbox and tasks, prioritize for the day',
          'priority': 'medium',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    return actions;
  }

  /// Build triage summary
  String _buildTriageSummary(TriageAnalysis analysis, String triageType) {
    final buffer = StringBuffer();

    buffer.writeln('# Triage Summary\n');

    if (triageType != 'inbox') {
      buffer.writeln('## Tasks');
      buffer.writeln('📊 Total: ${analysis.totalTasks}');
      buffer.writeln('🔴 Overdue: ${analysis.overdueCount}');
      buffer.writeln('⏰ Due Today: ${analysis.doTodayCount}');
      buffer.writeln('📅 Scheduled: ${analysis.scheduleCount}\n');
    }

    if (triageType != 'tasks') {
      buffer.writeln('## Emails');
      buffer.writeln('📧 Total: ${analysis.totalEmails}');
      buffer.writeln('(Email triage coming soon)\n');
    }

    buffer.writeln('## Recommendations');
    buffer.writeln('1. Address ${analysis.overdueCount} overdue items first');
    buffer.writeln('2. Focus on top 3 most important tasks today');
    buffer.writeln('3. Schedule unscheduled items');
    buffer.writeln('4. Batch similar tasks for efficiency\n');

    buffer.writeln('---\nGenerated by Dona Triage');

    return buffer.toString();
  }

  /// Identify tasks that can be batched together
  List<Map<String, dynamic>> _identifyBatchableTasks(List<dynamic> tasks) {
    final batches = <String, int>{};

    for (final task in tasks) {
      final title = task.title.toLowerCase();

      // Look for common patterns
      if (title.contains('email') || title.contains('reply')) {
        batches['Emails'] = (batches['Emails'] ?? 0) + 1;
      } else if (title.contains('call') || title.contains('phone')) {
        batches['Calls'] = (batches['Calls'] ?? 0) + 1;
      } else if (title.contains('review') || title.contains('check')) {
        batches['Reviews'] = (batches['Reviews'] ?? 0) + 1;
      } else if (title.contains('meeting') || title.contains('schedule')) {
        batches['Scheduling'] = (batches['Scheduling'] ?? 0) + 1;
      }
    }

    // Only return batches with 2+ items
    return batches.entries
        .where((e) => e.value >= 2)
        .map((e) => {'name': e.key, 'count': e.value})
        .toList();
  }

  /// Find best time for batch processing
  DateTime _findBatchTime() {
    final now = DateTime.now();

    // Prefer end of day (4-5 PM) for admin tasks
    if (now.hour < 16) {
      return DateTime(now.year, now.month, now.day, 16, 0);
    } else {
      // Or tomorrow afternoon
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16, 0);
    }
  }

  /// Format triage type for display
  String _formatTriageType(String type) {
    switch (type) {
      case 'tasks':
        return 'Tasks';
      case 'inbox':
        return 'Inbox';
      case 'both':
        return 'Inbox & Tasks';
      default:
        return type;
    }
  }

  /// Format date as "MMM d"
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Triage analysis data
class TriageAnalysis {
  final int totalTasks;
  final int doTodayCount;
  final int scheduleCount;
  final int overdueCount;
  final int totalEmails;
  final List<dynamic> doTodayTasks;
  final List<dynamic> scheduleTasks;
  final List<dynamic> overdueTasks;
  final List<dynamic> emails;

  const TriageAnalysis({
    required this.totalTasks,
    required this.doTodayCount,
    required this.scheduleCount,
    required this.overdueCount,
    required this.totalEmails,
    required this.doTodayTasks,
    required this.scheduleTasks,
    required this.overdueTasks,
    required this.emails,
  });

  factory TriageAnalysis.empty() {
    return const TriageAnalysis(
      totalTasks: 0,
      doTodayCount: 0,
      scheduleCount: 0,
      overdueCount: 0,
      totalEmails: 0,
      doTodayTasks: [],
      scheduleTasks: [],
      overdueTasks: [],
      emails: [],
    );
  }
}
