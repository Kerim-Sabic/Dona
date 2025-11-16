import 'package:uuid/uuid.dart';
import 'autopilot_models.dart';
import '../../assistant/assistant_brain.dart';
import '../../assistant/context/context_engine.dart';
import '../../core/utils/logger.dart';
import '../../services/storage/local_storage_service.dart';

/// Autopilot Engine - Core orchestrator for autonomous task execution
///
/// Responsibilities:
/// - Intent recognition and validation
/// - AI-powered plan generation
/// - Simulation mode (preview what will happen)
/// - Execution mode (actually perform actions)
/// - Progress tracking and result reporting
class AutopilotEngine {
  static final AutopilotEngine _instance = AutopilotEngine._internal();
  static AutopilotEngine get instance => _instance;

  AutopilotEngine._internal();

  final _uuid = const Uuid();
  final Map<String, AutopilotPlan> _activePlans = {};
  final List<AutopilotResult> _completedResults = [];

  // Callbacks for UI updates
  void Function(AutopilotPlan plan)? onPlanGenerated;
  void Function(AutopilotPlan plan, AutopilotAction action)? onActionStarted;
  void Function(AutopilotPlan plan, AutopilotAction action)? onActionCompleted;
  void Function(AutopilotPlan plan)? onPlanCompleted;

  Future<void> init() async {
    try {
      // Load any persisted plans
      await _loadPersistedPlans();
      AppLogger.info('AutopilotEngine initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AutopilotEngine', e, stackTrace);
    }
  }

  /// Recognize intent from user message
  Future<AutopilotIntent?> recognizeIntent(String userMessage) async {
    try {
      AppLogger.debug('Recognizing intent from: $userMessage');

      // Use AssistantBrain to extract intent
      final intentData = await AssistantBrain.instance.extractIntent(userMessage);

      final intentType = intentData['intent'] as String;

      // Map general intents to autopilot intents
      final autopilotType = _mapToAutopilotIntent(intentType);
      if (autopilotType == null) {
        AppLogger.debug('Intent not autopilot-related: $intentType');
        return null;
      }

      return AutopilotIntent(
        id: _uuid.v4(),
        intentType: autopilotType,
        userGoal: userMessage,
        parameters: intentData['entities'] as Map<String, dynamic>? ?? {},
        timestamp: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recognize intent', e, stackTrace);
      return null;
    }
  }

  /// Generate a plan for the given intent
  Future<AutopilotPlan> generatePlan(AutopilotIntent intent) async {
    try {
      AppLogger.info('Generating plan for intent: ${intent.intentType}');

      // Get current context for intelligent planning
      final context = await ContextEngine.instance.getTodayContext();

      // Generate plan using AI
      final planPrompt = _buildPlanGenerationPrompt(intent, context);
      final aiResponse = await AssistantBrain.instance.generateReply(
        userMessage: planPrompt,
      );

      // Parse AI response into actions
      final actions = _parseActionsFromAI(aiResponse);

      final plan = AutopilotPlan(
        id: _uuid.v4(),
        intentId: intent.id,
        planName: _getPlanName(intent.intentType),
        description: _getPlanDescription(intent.intentType),
        actions: actions,
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      // Cache the plan
      _activePlans[plan.id] = plan;

      // Notify listeners
      onPlanGenerated?.call(plan);

      AppLogger.info('Generated plan with ${actions.length} actions');
      return plan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate plan', e, stackTrace);
      rethrow;
    }
  }

  /// Simulate plan execution (preview mode)
  Future<AutopilotResult> simulatePlan(String planId) async {
    try {
      final plan = _activePlans[planId];
      if (plan == null) {
        throw Exception('Plan not found: $planId');
      }

      AppLogger.info('Simulating plan: ${plan.planName}');

      // Simulate each action
      final simulatedActions = <String>[];
      for (final action in plan.actions) {
        final simulation = await _simulateAction(action);
        simulatedActions.add(simulation);
      }

      return AutopilotResult(
        planId: planId,
        success: true,
        summary: 'Simulation completed for ${plan.planName}',
        completedActions: simulatedActions,
        failedActions: [],
        metadata: {'mode': 'simulation'},
        timestamp: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to simulate plan', e, stackTrace);
      rethrow;
    }
  }

  /// Execute a plan (actually perform the actions)
  Future<AutopilotResult> executePlan(String planId) async {
    try {
      var plan = _activePlans[planId];
      if (plan == null) {
        throw Exception('Plan not found: $planId');
      }

      AppLogger.info('Executing plan: ${plan.planName}');

      // Update plan status
      plan = plan.copyWith(
        status: AutopilotPlanStatus.inProgress,
        startedAt: DateTime.now(),
      );
      _activePlans[planId] = plan;

      final completedActions = <String>[];
      final failedActions = <String>[];

      // Execute each action
      for (int i = 0; i < plan.actions.length; i++) {
        var action = plan.actions[i];

        // Update action status
        action = action.copyWith(status: AutopilotActionStatus.inProgress);
        plan.actions[i] = action;

        // Notify listeners
        onActionStarted?.call(plan, action);

        try {
          // Execute the action
          final result = await _executeAction(action);

          // Update action with result
          action = action.copyWith(
            status: AutopilotActionStatus.completed,
            executedAt: DateTime.now(),
            resultMessage: result,
          );
          plan.actions[i] = action;

          completedActions.add(action.description);

          // Notify listeners
          onActionCompleted?.call(plan, action);

          AppLogger.debug('Completed action: ${action.description}');
        } catch (e, stackTrace) {
          AppLogger.error('Failed to execute action', e, stackTrace);

          action = action.copyWith(
            status: AutopilotActionStatus.failed,
            resultMessage: e.toString(),
          );
          plan.actions[i] = action;
          failedActions.add(action.description);
        }
      }

      // Update final plan status
      final finalStatus = failedActions.isEmpty
          ? AutopilotPlanStatus.completed
          : AutopilotPlanStatus.failed;

      plan = plan.copyWith(
        status: finalStatus,
        completedAt: DateTime.now(),
      );
      _activePlans[planId] = plan;

      // Create result
      final result = AutopilotResult(
        planId: planId,
        success: failedActions.isEmpty,
        summary: failedActions.isEmpty
            ? 'Successfully completed ${completedActions.length} actions'
            : 'Completed ${completedActions.length} actions, ${failedActions.length} failed',
        completedActions: completedActions,
        failedActions: failedActions,
        timestamp: DateTime.now(),
      );

      _completedResults.add(result);

      // Notify listeners
      onPlanCompleted?.call(plan);

      // Persist result
      await _persistResult(result);

      AppLogger.info('Plan execution completed: ${result.summary}');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to execute plan', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel an active plan
  Future<void> cancelPlan(String planId) async {
    final plan = _activePlans[planId];
    if (plan == null) return;

    final updatedPlan = plan.copyWith(
      status: AutopilotPlanStatus.cancelled,
      completedAt: DateTime.now(),
    );

    _activePlans[planId] = updatedPlan;
    AppLogger.info('Cancelled plan: ${plan.planName}');
  }

  /// Get active plan by ID
  AutopilotPlan? getPlan(String planId) {
    return _activePlans[planId];
  }

  /// Get all active plans
  List<AutopilotPlan> getActivePlans() {
    return _activePlans.values.toList();
  }

  /// Get completed results
  List<AutopilotResult> getCompletedResults() {
    return _completedResults;
  }

  // ==================== PRIVATE HELPERS ====================

  String? _mapToAutopilotIntent(String generalIntent) {
    // Map general intents to autopilot intents
    final mapping = {
      'plan_day': AutopilotIntentType.planDay,
      'study_help': AutopilotIntentType.studySession,
      'schedule_event': AutopilotIntentType.planDay,
      'organize': AutopilotIntentType.organizeFiles,
    };

    return mapping[generalIntent];
  }

  String _buildPlanGenerationPrompt(
    AutopilotIntent intent,
    dynamic context,
  ) {
    return '''Generate a step-by-step action plan for the following user goal:

Goal: ${intent.userGoal}
Intent Type: ${intent.intentType}

Current Context:
${context?.toBriefSummary() ?? 'No context available'}

Generate a plan with 3-7 concrete actions. For each action:
1. Specify the action type (create_event, create_task, send_email, etc.)
2. Provide a clear description
3. List required parameters

Format your response as a numbered list with clear action descriptions.
''';
  }

  List<AutopilotAction> _parseActionsFromAI(String aiResponse) {
    // Simple parsing - in production, use structured JSON
    final actions = <AutopilotAction>[];
    final lines = aiResponse.split('\n');
    int stepNumber = 1;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Look for numbered items (1., 2., etc.)
      final match = RegExp(r'^\d+\.\s*(.+)').firstMatch(line.trim());
      if (match != null) {
        final description = match.group(1)!;

        actions.add(AutopilotAction(
          id: _uuid.v4(),
          actionType: _inferActionType(description),
          description: description,
          parameters: {},
          status: AutopilotActionStatus.pending,
          stepNumber: stepNumber++,
        ));
      }
    }

    return actions;
  }

  String _inferActionType(String description) {
    final lower = description.toLowerCase();

    if (lower.contains('create') && lower.contains('event')) {
      return AutopilotActionType.createEvent;
    } else if (lower.contains('create') && lower.contains('task')) {
      return AutopilotActionType.createTask;
    } else if (lower.contains('email')) {
      return AutopilotActionType.sendEmail;
    } else if (lower.contains('reminder')) {
      return AutopilotActionType.setReminder;
    } else if (lower.contains('note')) {
      return AutopilotActionType.createNote;
    }

    return 'generic_action';
  }

  String _getPlanName(String intentType) {
    final names = {
      AutopilotIntentType.planDay: 'Plan My Day',
      AutopilotIntentType.studySession: 'Study Session',
      AutopilotIntentType.organizeFiles: 'Organize Files',
      AutopilotIntentType.prepareMeeting: 'Prepare Meeting',
      AutopilotIntentType.focusMode: 'Focus Mode',
    };

    return names[intentType] ?? 'Autopilot Task';
  }

  String _getPlanDescription(String intentType) {
    final descriptions = {
      AutopilotIntentType.planDay: 'Automatically organize your day with events, tasks, and priorities',
      AutopilotIntentType.studySession: 'Set up an optimized study session with breaks and materials',
      AutopilotIntentType.organizeFiles: 'Clean up and organize your digital files',
      AutopilotIntentType.prepareMeeting: 'Prepare for an upcoming meeting with agenda and materials',
      AutopilotIntentType.focusMode: 'Enter focus mode with notifications silenced and timer set',
    };

    return descriptions[intentType] ?? 'Execute automated task sequence';
  }

  Future<String> _simulateAction(AutopilotAction action) async {
    // Simulate what the action would do
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate processing

    return 'Would execute: ${action.description}';
  }

  Future<String> _executeAction(AutopilotAction action) async {
    // Execute the actual action based on type
    AppLogger.debug('Executing action: ${action.actionType}');

    // TODO: Implement actual execution for each action type
    // For now, simulate execution
    await Future.delayed(const Duration(seconds: 1));

    switch (action.actionType) {
      case AutopilotActionType.createEvent:
        // TODO: Call CalendarService to create event
        return 'Created calendar event';

      case AutopilotActionType.createTask:
        // TODO: Call TasksService to create task
        return 'Created task';

      case AutopilotActionType.sendEmail:
        // TODO: Call GmailService to send email
        return 'Sent email';

      case AutopilotActionType.setReminder:
        // TODO: Set reminder
        return 'Set reminder';

      default:
        return 'Completed: ${action.description}';
    }
  }

  Future<void> _loadPersistedPlans() async {
    try {
      final plansJson = LocalStorageService.instance.getString('autopilot_plans');
      if (plansJson != null) {
        // TODO: Deserialize and load plans
        AppLogger.debug('Loaded persisted plans');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load persisted plans', e, stackTrace);
    }
  }

  Future<void> _persistResult(AutopilotResult result) async {
    try {
      // TODO: Persist result to local storage
      AppLogger.debug('Persisted result for plan: ${result.planId}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to persist result', e, stackTrace);
    }
  }
}
