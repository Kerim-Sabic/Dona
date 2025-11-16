/// Autopilot Framework - Domain Models
///
/// Enables Dona to autonomously perform multi-step tasks with user approval
library autopilot_models;

/// Represents a user's intent to trigger an autopilot flow
class AutopilotIntent {
  final String id;
  final String intentType; // 'plan_day', 'study_session', 'organize_files', etc.
  final String userGoal; // Natural language description
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const AutopilotIntent({
    required this.id,
    required this.intentType,
    required this.userGoal,
    this.parameters = const {},
    required this.timestamp,
  });

  factory AutopilotIntent.fromMap(Map<String, dynamic> map) {
    return AutopilotIntent(
      id: map['id'] as String,
      intentType: map['intentType'] as String,
      userGoal: map['userGoal'] as String,
      parameters: map['parameters'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'intentType': intentType,
      'userGoal': userGoal,
      'parameters': parameters,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// A complete autopilot execution plan with steps
class AutopilotPlan {
  final String id;
  final String intentId;
  final String planName;
  final String description;
  final List<AutopilotAction> actions;
  final AutopilotPlanStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? failureReason;

  const AutopilotPlan({
    required this.id,
    required this.intentId,
    required this.planName,
    required this.description,
    required this.actions,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.failureReason,
  });

  AutopilotPlan copyWith({
    String? id,
    String? intentId,
    String? planName,
    String? description,
    List<AutopilotAction>? actions,
    AutopilotPlanStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return AutopilotPlan(
      id: id ?? this.id,
      intentId: intentId ?? this.intentId,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      actions: actions ?? this.actions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  /// Get progress as 0.0 - 1.0
  double get progress {
    if (actions.isEmpty) return 0.0;
    final completedCount = actions.where((a) => a.status == AutopilotActionStatus.completed).length;
    return completedCount / actions.length;
  }

  /// Get current action being executed
  AutopilotAction? get currentAction {
    return actions.firstWhere(
      (a) => a.status == AutopilotActionStatus.inProgress,
      orElse: () => actions.firstWhere(
        (a) => a.status == AutopilotActionStatus.pending,
        orElse: () => actions.last,
      ),
    );
  }

  /// Check if plan is complete
  bool get isComplete {
    return status == AutopilotPlanStatus.completed ||
        status == AutopilotPlanStatus.failed ||
        status == AutopilotPlanStatus.cancelled;
  }

  factory AutopilotPlan.fromMap(Map<String, dynamic> map) {
    return AutopilotPlan(
      id: map['id'] as String,
      intentId: map['intentId'] as String,
      planName: map['planName'] as String,
      description: map['description'] as String,
      actions: (map['actions'] as List)
          .map((a) => AutopilotAction.fromMap(a as Map<String, dynamic>))
          .toList(),
      status: AutopilotPlanStatus.values.firstWhere(
        (s) => s.toString() == 'AutopilotPlanStatus.${map['status']}',
        orElse: () => AutopilotPlanStatus.draft,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      failureReason: map['failureReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'intentId': intentId,
      'planName': planName,
      'description': description,
      'actions': actions.map((a) => a.toMap()).toList(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'failureReason': failureReason,
    };
  }
}

/// A single action within an autopilot plan
class AutopilotAction {
  final String id;
  final String actionType; // 'create_event', 'send_email', 'create_task', etc.
  final String description;
  final Map<String, dynamic> parameters;
  final AutopilotActionStatus status;
  final bool requiresApproval;
  final int stepNumber;
  final DateTime? executedAt;
  final String? resultMessage;
  final dynamic resultData;

  const AutopilotAction({
    required this.id,
    required this.actionType,
    required this.description,
    required this.parameters,
    required this.status,
    this.requiresApproval = true,
    required this.stepNumber,
    this.executedAt,
    this.resultMessage,
    this.resultData,
  });

  AutopilotAction copyWith({
    String? id,
    String? actionType,
    String? description,
    Map<String, dynamic>? parameters,
    AutopilotActionStatus? status,
    bool? requiresApproval,
    int? stepNumber,
    DateTime? executedAt,
    String? resultMessage,
    dynamic resultData,
  }) {
    return AutopilotAction(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      stepNumber: stepNumber ?? this.stepNumber,
      executedAt: executedAt ?? this.executedAt,
      resultMessage: resultMessage ?? this.resultMessage,
      resultData: resultData ?? this.resultData,
    );
  }

  factory AutopilotAction.fromMap(Map<String, dynamic> map) {
    return AutopilotAction(
      id: map['id'] as String,
      actionType: map['actionType'] as String,
      description: map['description'] as String,
      parameters: map['parameters'] as Map<String, dynamic>? ?? {},
      status: AutopilotActionStatus.values.firstWhere(
        (s) => s.toString() == 'AutopilotActionStatus.${map['status']}',
        orElse: () => AutopilotActionStatus.pending,
      ),
      requiresApproval: map['requiresApproval'] as bool? ?? true,
      stepNumber: map['stepNumber'] as int,
      executedAt: map['executedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['executedAt'] as int)
          : null,
      resultMessage: map['resultMessage'] as String?,
      resultData: map['resultData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType,
      'description': description,
      'parameters': parameters,
      'status': status.toString().split('.').last,
      'requiresApproval': requiresApproval,
      'stepNumber': stepNumber,
      'executedAt': executedAt?.millisecondsSinceEpoch,
      'resultMessage': resultMessage,
      'resultData': resultData,
    };
  }
}

/// Result of an autopilot execution
class AutopilotResult {
  final String planId;
  final bool success;
  final String summary;
  final List<String> completedActions;
  final List<String> failedActions;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AutopilotResult({
    required this.planId,
    required this.success,
    required this.summary,
    required this.completedActions,
    required this.failedActions,
    this.metadata = const {},
    required this.timestamp,
  });

  factory AutopilotResult.fromMap(Map<String, dynamic> map) {
    return AutopilotResult(
      planId: map['planId'] as String,
      success: map['success'] as bool,
      summary: map['summary'] as String,
      completedActions: List<String>.from(map['completedActions'] as List),
      failedActions: List<String>.from(map['failedActions'] as List),
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'success': success,
      'summary': summary,
      'completedActions': completedActions,
      'failedActions': failedActions,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Status of an autopilot plan
enum AutopilotPlanStatus {
  draft, // Plan is being generated
  pendingApproval, // Waiting for user approval
  approved, // User approved, ready to execute
  inProgress, // Currently executing
  completed, // Successfully completed
  failed, // Failed during execution
  cancelled, // User cancelled
}

/// Status of an individual action
enum AutopilotActionStatus {
  pending, // Not started yet
  inProgress, // Currently executing
  completed, // Successfully completed
  failed, // Failed during execution
  skipped, // Skipped by user or system
}

/// Types of autopilot intents
class AutopilotIntentType {
  static const String planDay = 'plan_day';
  static const String studySession = 'study_session';
  static const String organizeFiles = 'organize_files';
  static const String prepareMeeting = 'prepare_meeting';
  static const String emailSummary = 'email_summary';
  static const String focusMode = 'focus_mode';
  static const String morningRoutine = 'morning_routine';
  static const String eveningWindDown = 'evening_wind_down';
}

/// Types of autopilot actions
class AutopilotActionType {
  static const String createEvent = 'create_event';
  static const String createTask = 'create_task';
  static const String updateTask = 'update_task';
  static const String sendEmail = 'send_email';
  static const String sendSMS = 'send_sms';
  static const String makeCall = 'make_call';
  static const String createNote = 'create_note';
  static const String setReminder = 'set_reminder';
  static const String updateCalendar = 'update_calendar';
  static const String searchWeb = 'search_web';
  static const String generateDocument = 'generate_document';
  static const String analyzeData = 'analyze_data';
}
