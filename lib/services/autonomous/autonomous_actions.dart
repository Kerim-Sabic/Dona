import 'dart:async';
import '../../core/utils/logger.dart';
import '../gmail/gmail_service.dart';
import '../calendar/calendar_service.dart';
import '../google_tasks/google_tasks_service.dart';
import '../ai/ai_service.dart';
import '../../data/user_profile.dart';
import '../../data/models/calendar_event.dart';

/// Autonomous Actions System
///
/// Handles tasks automatically with user permission
class AutonomousActions {
  static final AutonomousActions _instance = AutonomousActions._internal();
  static AutonomousActions get instance => _instance;

  AutonomousActions._internal();

  final Map<ActionType, PermissionLevel> _permissions = {};
  final List<AutonomousAction> _actionHistory = [];
  final Set<String> _approvedPatterns = {};

  // Callbacks
  Function(AutonomousAction)? onActionRequested;
  Function(AutonomousAction)? onActionCompleted;

  /// Initialize with default permissions
  Future<void> init() async {
    // Set default permissions (user can change later)
    _permissions[ActionType.checkWeather] = PermissionLevel.autonomous;
    _permissions[ActionType.checkNews] = PermissionLevel.autonomous;
    _permissions[ActionType.organizeTasks] = PermissionLevel.autonomous;
    _permissions[ActionType.prepareResources] = PermissionLevel.autonomous;

    _permissions[ActionType.respondToEmail] = PermissionLevel.askOnce;
    _permissions[ActionType.scheduleEvent] = PermissionLevel.askOnce;
    _permissions[ActionType.rescheduleEvent] = PermissionLevel.askOnce;

    _permissions[ActionType.sendEmail] = PermissionLevel.alwaysAsk;
    _permissions[ActionType.deleteEvent] = PermissionLevel.alwaysAsk;
    _permissions[ActionType.shareDocument] = PermissionLevel.alwaysAsk;

    AppLogger.info('Autonomous Actions initialized');
  }

  /// Execute an action (with permission checks)
  Future<ActionResult> executeAction(AutonomousAction action) async {
    try {
      final permission = _permissions[action.type] ?? PermissionLevel.alwaysAsk;

      AppLogger.info('Executing action: ${action.type.name} (${permission.name})');

      switch (permission) {
        case PermissionLevel.autonomous:
          return await _executeDirectly(action);

        case PermissionLevel.askOnce:
          if (_isApprovedPattern(action)) {
            return await _executeDirectly(action);
          } else {
            return await _requestPermission(action);
          }

        case PermissionLevel.alwaysAsk:
          return await _requestPermission(action);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error executing action', e, stackTrace);
      return ActionResult(
        success: false,
        message: 'Failed to execute action: $e',
      );
    }
  }

  /// Execute action directly
  Future<ActionResult> _executeDirectly(AutonomousAction action) async {
    AppLogger.info('Executing autonomously: ${action.description}');

    ActionResult result;

    switch (action.type) {
      case ActionType.respondToEmail:
        result = await _autoRespondToEmail(action);
        break;

      case ActionType.scheduleEvent:
        result = await _autoScheduleEvent(action);
        break;

      case ActionType.organizeTasks:
        result = await _organizeTasks(action);
        break;

      case ActionType.prepareResources:
        result = await _prepareMeetingResources(action);
        break;

      default:
        result = ActionResult(
          success: false,
          message: 'Action type not implemented: ${action.type.name}',
        );
    }

    // Record in history
    action.result = result;
    action.executedAt = DateTime.now();
    _actionHistory.add(action);

    // Notify completion
    if (onActionCompleted != null) {
      onActionCompleted!(action);
    }

    return result;
  }

  /// Request user permission
  Future<ActionResult> _requestPermission(AutonomousAction action) async {
    AppLogger.info('Requesting permission for: ${action.description}');

    // Notify UI to show permission dialog
    if (onActionRequested != null) {
      onActionRequested!(action);
    }

    // Return pending result (will be updated when user responds)
    return ActionResult(
      success: false,
      message: 'Pending user approval',
      isPending: true,
    );
  }

  /// Check if action pattern is approved
  bool _isApprovedPattern(AutonomousAction action) {
    final pattern = _getActionPattern(action);
    return _approvedPatterns.contains(pattern);
  }

  String _getActionPattern(AutonomousAction action) {
    // Create pattern based on action type and key parameters
    return '${action.type.name}_${action.parameters['category'] ?? 'general'}';
  }

  /// Approve action and remember pattern
  Future<void> approveAction(AutonomousAction action, {bool rememberPattern = false}) async {
    if (rememberPattern) {
      final pattern = _getActionPattern(action);
      _approvedPatterns.add(pattern);
      AppLogger.info('Approved pattern: $pattern');
    }

    // Execute the action
    await _executeDirectly(action);
  }

  // ==================== ACTION IMPLEMENTATIONS ====================

  /// Auto-respond to routine emails
  Future<ActionResult> _autoRespondToEmail(AutonomousAction action) async {
    try {
      final emailId = action.parameters['emailId'] as String;
      final originalEmail = action.parameters['email'] as EmailMessage?;

      if (originalEmail == null) {
        return ActionResult(success: false, message: 'Email not found');
      }

      // Analyze email intent
      final intent = await _analyzeEmailIntent(originalEmail);

      if (intent.isRoutine) {
        // Generate appropriate response
        final response = await _generateEmailResponse(originalEmail, intent);

        // Send response
        await GmailService.instance.sendEmail(response);

        return ActionResult(
          success: true,
          message: 'Auto-responded to ${originalEmail.from}',
          data: response,
        );
      }

      return ActionResult(
        success: false,
        message: 'Email is not routine, requires manual response',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error auto-responding to email', e, stackTrace);
      return ActionResult(success: false, message: 'Failed to respond: $e');
    }
  }

  Future<EmailIntent> _analyzeEmailIntent(EmailMessage email) async {
    final prompt = '''
Analyze this email and determine if it's a routine request:

From: ${email.from}
Subject: ${email.subject}
Body: ${email.body.substring(0, email.body.length > 500 ? 500 : email.body.length)}

Determine:
1. Is this a routine/simple request? (yes/no)
2. What type? (meeting_request|status_update|confirmation|question|other)
3. Can be auto-responded? (yes/no)

Return JSON: {"isRoutine": boolean, "type": "string", "canAutoRespond": boolean, "suggestedResponse": "string"}
''';

    try {
      final response = await AIService.instance.chat(prompt);
      // Parse JSON response
      // For now, return simple intent
      return EmailIntent(
        isRoutine: false, // Conservative default
        type: 'other',
        canAutoRespond: false,
      );
    } catch (e) {
      return EmailIntent(isRoutine: false, type: 'other', canAutoRespond: false);
    }
  }

  Future<EmailMessage> _generateEmailResponse(EmailMessage original, EmailIntent intent) async {
    final prompt = '''
Generate a professional email response:

Original Email:
From: ${original.from}
Subject: ${original.subject}
Body: ${original.body}

Intent: ${intent.type}

Generate a brief, professional response that:
- Acknowledges their email
- Provides helpful information or next steps
- Sounds natural and warm

Keep it under 100 words.
''';

    final responseBody = await AIService.instance.chat(prompt);

    return EmailMessage(
      to: [original.from!],
      subject: 'Re: ${original.subject}',
      body: responseBody,
    );
  }

  /// Auto-schedule events
  Future<ActionResult> _autoScheduleEvent(AutonomousAction action) async {
    try {
      final title = action.parameters['title'] as String;
      final participants = action.parameters['participants'] as List<String>?;
      final duration = action.parameters['duration'] as Duration? ?? const Duration(hours: 1);

      // Find best time (using smart scheduler)
      // For now, simple implementation
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final proposedTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);

      final event = CalendarEvent(
        title: title,
        startTime: proposedTime,
        endTime: proposedTime.add(duration),
        attendees: participants,
      );

      final created = await CalendarService.instance.createEvent(event);

      return ActionResult(
        success: created != null,
        message: created != null
            ? 'Scheduled: $title for ${_formatDateTime(proposedTime)}'
            : 'Failed to schedule event',
        data: created,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error auto-scheduling', e, stackTrace);
      return ActionResult(success: false, message: 'Failed to schedule: $e');
    }
  }

  /// Organize tasks
  Future<ActionResult> _organizeTasks(AutonomousAction action) async {
    try {
      // Get all tasks
      final taskLists = await GoogleTasksService.instance.getTaskLists();
      if (taskLists.isEmpty) {
        return ActionResult(success: false, message: 'No task lists found');
      }

      final tasks = await GoogleTasksService.instance.getTasks(taskLists.first.id);

      // Organize by priority/due date
      tasks.sort((a, b) {
        if (a.due == null && b.due == null) return 0;
        if (a.due == null) return 1;
        if (b.due == null) return -1;
        return a.due!.compareTo(b.due!);
      });

      return ActionResult(
        success: true,
        message: 'Organized ${tasks.length} tasks by priority',
        data: tasks,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Failed to organize: $e');
    }
  }

  /// Prepare meeting resources
  Future<ActionResult> _prepareMeetingResources(AutonomousAction action) async {
    try {
      final eventId = action.parameters['eventId'] as String;
      // Implement meeting preparation
      // This would use CrossServiceWorkflows

      return ActionResult(
        success: true,
        message: 'Meeting resources prepared',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Failed: $e');
    }
  }

  // ==================== PERMISSION MANAGEMENT ====================

  /// Update permission level for action type
  void setPermission(ActionType type, PermissionLevel level) {
    _permissions[type] = level;
    AppLogger.info('Set ${type.name} permission to ${level.name}');
  }

  /// Get current permission level
  PermissionLevel getPermission(ActionType type) {
    return _permissions[type] ?? PermissionLevel.alwaysAsk;
  }

  /// Get action history
  List<AutonomousAction> get actionHistory => List.unmodifiable(_actionHistory);

  /// Clear approved patterns (reset learning)
  void clearApprovedPatterns() {
    _approvedPatterns.clear();
    AppLogger.info('Cleared approved patterns');
  }

  // Helper methods
  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Autonomous action model
class AutonomousAction {
  final String id;
  final ActionType type;
  final String description;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  DateTime? executedAt;
  ActionResult? result;

  AutonomousAction({
    required this.id,
    required this.type,
    required this.description,
    required this.parameters,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ActionResult {
  final bool success;
  final String message;
  final dynamic data;
  final bool isPending;

  ActionResult({
    required this.success,
    required this.message,
    this.data,
    this.isPending = false,
  });
}

class EmailIntent {
  final bool isRoutine;
  final String type;
  final bool canAutoRespond;

  EmailIntent({
    required this.isRoutine,
    required this.type,
    required this.canAutoRespond,
  });
}

enum ActionType {
  respondToEmail,
  sendEmail,
  scheduleEvent,
  rescheduleEvent,
  deleteEvent,
  organizeTasks,
  prepareResources,
  shareDocument,
  checkWeather,
  checkNews,
}

enum PermissionLevel {
  autonomous,    // Execute without asking
  askOnce,       // Ask first time, then remember
  alwaysAsk,     // Always ask for permission
}
