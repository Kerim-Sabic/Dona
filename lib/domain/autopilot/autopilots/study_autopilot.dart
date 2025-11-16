import 'package:uuid/uuid.dart';
import '../autopilot_models.dart';
import '../autopilot_engine.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../assistant/context/context_models.dart';
import '../../../core/utils/logger.dart';
import '../../../services/student/exam_manager.dart';
import '../../../services/student/assignment_manager.dart';
import '../../../data/models/student/exam.dart';
import '../../../data/models/student/assignment.dart';

/// Study Autopilot
///
/// Automatically sets up an optimized study session:
/// - Identifies what to study based on exams and assignments
/// - Creates structured study plan with Pomodoro technique
/// - Sets up break reminders
/// - Gathers study materials
/// - Tracks progress
class StudyAutopilot {
  static final StudyAutopilot _instance = StudyAutopilot._internal();
  static StudyAutopilot get instance => _instance;

  StudyAutopilot._internal();

  final _uuid = const Uuid();

  /// Generate a Study Session autopilot plan
  Future<AutopilotPlan> generatePlan({
    String? subject,
    int? durationMinutes,
    StudyTechnique? technique,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      AppLogger.info('Generating Study Autopilot plan');

      // Get context and student data
      final context = await ContextEngine.instance.getTodayContext(forceRefresh: true);

      // Determine what to study
      final studyTarget = await _determineStudyTarget(context, subject);

      // Build study plan actions
      final duration = durationMinutes ?? preferences?['defaultDuration'] ?? 120;
      final studyTechnique = technique ?? StudyTechnique.pomodoro;

      final actions = await _buildStudyPlanActions(
        studyTarget,
        duration,
        studyTechnique,
        preferences,
      );

      final plan = AutopilotPlan(
        id: _uuid.v4(),
        intentId: _uuid.v4(),
        planName: 'Study Session - ${studyTarget.title}',
        description: 'Optimized ${duration}min study session using ${studyTechnique.name} technique',
        actions: actions,
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      AppLogger.info('Generated Study Autopilot with ${actions.length} actions');
      return plan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate Study Autopilot', e, stackTrace);
      rethrow;
    }
  }

  /// Determine what to study based on priorities
  Future<StudyTarget> _determineStudyTarget(
    LifeContext context,
    String? specifiedSubject,
  ) async {
    // If subject is specified, use that
    if (specifiedSubject != null) {
      return StudyTarget(
        title: specifiedSubject,
        type: StudyTargetType.subject,
        urgency: 0.7,
      );
    }

    // Otherwise, find most urgent exam or assignment
    final upcomingExams = context.studentContext.upcomingExams;
    final dueAssignments = context.studentContext.dueAssignments;

    if (upcomingExams.isNotEmpty) {
      final nextExam = upcomingExams.first;
      final daysUntil = nextExam.examDate.difference(DateTime.now()).inDays;
      final urgency = daysUntil <= 3 ? 0.95 : daysUntil <= 7 ? 0.8 : 0.6;

      return StudyTarget(
        title: nextExam.examName,
        type: StudyTargetType.exam,
        courseName: nextExam.courseName,
        dueDate: nextExam.examDate,
        urgency: urgency,
        relatedData: nextExam,
      );
    }

    if (dueAssignments.isNotEmpty) {
      final nextAssignment = dueAssignments.first;
      final daysUntil = nextAssignment.dueDate.difference(DateTime.now()).inDays;
      final urgency = daysUntil == 0 ? 0.9 : daysUntil <= 2 ? 0.7 : 0.5;

      return StudyTarget(
        title: nextAssignment.title,
        type: StudyTargetType.assignment,
        courseName: nextAssignment.courseName,
        dueDate: nextAssignment.dueDate,
        urgency: urgency,
        relatedData: nextAssignment,
      );
    }

    // Default: general review
    return StudyTarget(
      title: 'General Review',
      type: StudyTargetType.review,
      urgency: 0.5,
    );
  }

  /// Build study plan actions
  Future<List<AutopilotAction>> _buildStudyPlanActions(
    StudyTarget target,
    int durationMinutes,
    StudyTechnique technique,
    Map<String, dynamic>? preferences,
  ) async {
    final actions = <AutopilotAction>[];
    int stepNumber = 1;

    // 1. Create study session event
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createEvent,
      description: 'Block calendar for study session',
      parameters: {
        'title': '📚 Study: ${target.title}',
        'startTime': DateTime.now().add(const Duration(minutes: 5)),
        'duration': durationMinutes,
        'description': _buildStudyEventDescription(target, technique),
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 2. Set up Pomodoro timers
    if (technique == StudyTechnique.pomodoro) {
      final pomodoroCount = (durationMinutes / 30).ceil(); // 25min work + 5min break

      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.setReminder,
        description: 'Set up Pomodoro timers (${pomodoroCount} cycles)',
        parameters: {
          'title': 'Pomodoro Study Session',
          'cycles': pomodoroCount,
          'workDuration': 25,
          'breakDuration': 5,
          'longBreakAfter': 4,
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 3. Create task checklist for study goals
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createTask,
      description: 'Create study goals checklist',
      parameters: {
        'title': 'Study Goals: ${target.title}',
        'notes': _buildStudyGoals(target),
        'due': DateTime.now().add(Duration(minutes: durationMinutes)),
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 4. Gather study materials note
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createNote,
      description: 'Create note with study materials and resources',
      parameters: {
        'title': 'Study Materials - ${target.title}',
        'content': _buildMaterialsNote(target),
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 5. Set focus mode reminder
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.setReminder,
      description: 'Reminder to enable Do Not Disturb mode',
      parameters: {
        'title': 'Enable Focus Mode',
        'time': DateTime.now().add(const Duration(minutes: 3)),
        'message': 'Turn on Do Not Disturb and close distracting apps',
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 6. Mid-session hydration reminder
    if (durationMinutes >= 60) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.setReminder,
        description: 'Mid-session hydration and stretch reminder',
        parameters: {
          'title': 'Hydration Check',
          'time': DateTime.now().add(Duration(minutes: durationMinutes ~/ 2)),
          'message': 'Take a moment to drink water and stretch',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 7. Post-study review task
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createTask,
      description: 'Schedule post-study review',
      parameters: {
        'title': 'Review: ${target.title}',
        'due': DateTime.now().add(const Duration(hours: 24)),
        'notes': 'Review what you studied today to reinforce learning',
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    return actions;
  }

  String _buildStudyEventDescription(StudyTarget target, StudyTechnique technique) {
    final parts = <String>[
      'Focused study session for ${target.title}',
      '',
      'Technique: ${technique.displayName}',
    ];

    if (target.dueDate != null) {
      final daysUntil = target.dueDate!.difference(DateTime.now()).inDays;
      parts.add('Due in: $daysUntil days');
    }

    parts.add('');
    parts.add('Remember: Stay focused, take breaks, and stay hydrated!');

    return parts.join('\n');
  }

  String _buildStudyGoals(StudyTarget target) {
    if (target.type == StudyTargetType.exam) {
      return '''Study Goals:
☐ Review key concepts and formulas
☐ Practice problem sets
☐ Review past assignments and quizzes
☐ Create summary notes
☐ Identify weak areas for focused review

Course: ${target.courseName ?? 'N/A'}
Exam Date: ${target.dueDate != null ? _formatDate(target.dueDate!) : 'TBD'}
''';
    } else if (target.type == StudyTargetType.assignment) {
      return '''Assignment Goals:
☐ Review assignment requirements
☐ Complete research/reading
☐ Draft outline
☐ Work on main content
☐ Review and edit

Course: ${target.courseName ?? 'N/A'}
Due: ${target.dueDate != null ? _formatDate(target.dueDate!) : 'TBD'}
''';
    } else {
      return '''Study Goals:
☐ Review recent lecture notes
☐ Complete practice problems
☐ Identify areas needing clarification
☐ Prepare questions for instructor/TA
''';
    }
  }

  String _buildMaterialsNote(StudyTarget target) {
    return '''Study Materials for ${target.title}

📚 Resources Needed:
- Textbook chapters
- Lecture notes
- Practice problems
- Previous assignments/quizzes

💡 Study Tips:
- Use active recall (test yourself)
- Explain concepts out loud
- Create visual aids (diagrams, charts)
- Take regular breaks (Pomodoro technique)

✅ Success Criteria:
- Understand core concepts
- Can solve practice problems independently
- Ready to teach the material to someone else
''';
  }

  String _formatDate(DateTime date) {
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
    return '$month ${date.day}';
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

/// Study target - what to study
class StudyTarget {
  final String title;
  final StudyTargetType type;
  final String? courseName;
  final DateTime? dueDate;
  final double urgency;
  final dynamic relatedData;

  const StudyTarget({
    required this.title,
    required this.type,
    this.courseName,
    this.dueDate,
    required this.urgency,
    this.relatedData,
  });
}

enum StudyTargetType {
  exam,
  assignment,
  subject,
  review,
}

enum StudyTechnique {
  pomodoro,
  timeBlocking,
  feynman,
  spacedRepetition,
}

extension StudyTechniqueExtension on StudyTechnique {
  String get name {
    switch (this) {
      case StudyTechnique.pomodoro:
        return 'pomodoro';
      case StudyTechnique.timeBlocking:
        return 'time_blocking';
      case StudyTechnique.feynman:
        return 'feynman';
      case StudyTechnique.spacedRepetition:
        return 'spaced_repetition';
    }
  }

  String get displayName {
    switch (this) {
      case StudyTechnique.pomodoro:
        return 'Pomodoro (25min focus + 5min break)';
      case StudyTechnique.timeBlocking:
        return 'Time Blocking';
      case StudyTechnique.feynman:
        return 'Feynman Technique';
      case StudyTechnique.spacedRepetition:
        return 'Spaced Repetition';
    }
  }
}
