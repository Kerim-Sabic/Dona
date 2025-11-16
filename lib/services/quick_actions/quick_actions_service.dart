import '../../core/utils/logger.dart';
import '../../core/platform/platform_service.dart';
import '../focus/focus_mode_service.dart';
import '../email/email_triage_service.dart';
import '../calendar/calendar_service.dart';
import '../habits/habit_tracker.dart';
import '../voice/voice_command_handler.dart';

/// Quick Actions Service
/// Provides instant access to common tasks via shortcuts, widgets, and commands
class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  static QuickActionsService get instance => _instance;

  QuickActionsService._internal();

  final List<QuickAction> _actions = [];
  final Map<String, int> _usageCount = {}; // Track usage for AI suggestions

  /// Initialize quick actions
  Future<void> init() async {
    try {
      _registerDefaultActions();
      AppLogger.info('QuickActionsService initialized with ${_actions.length} actions');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize QuickActionsService', e, stackTrace);
    }
  }

  /// Register default quick actions
  void _registerDefaultActions() {
    // Email actions
    _actions.add(QuickAction(
      id: 'triage_inbox',
      title: '📧 Triage Inbox',
      description: 'Smart email categorization',
      category: ActionCategory.email,
      execute: () async {
        final result = await EmailTriageService.instance.triageInbox();
        return ActionResult(
          success: result.success,
          message: result.message,
        );
      },
      shortcut: 'Ctrl+E',
    ));

    _actions.add(QuickAction(
      id: 'check_email',
      title: '📬 Check Email',
      description: 'Quick inbox check',
      category: ActionCategory.email,
      execute: () async {
        final result = await VoiceCommandHandler.instance.processCommand('check my email');
        return ActionResult(
          success: result.success,
          message: result.message,
        );
      },
      shortcut: 'Ctrl+Shift+E',
    ));

    // Focus actions
    _actions.add(QuickAction(
      id: 'start_focus',
      title: '🎯 Start Focus Mode',
      description: 'Deep work session',
      category: ActionCategory.focus,
      execute: () async {
        await FocusModeService.instance.startFocus(preset: 'deep_work');
        return ActionResult(
          success: true,
          message: 'Focus mode started',
        );
      },
      shortcut: 'Ctrl+Shift+F',
    ));

    _actions.add(QuickAction(
      id: 'pomodoro',
      title: '🍅 Pomodoro Timer',
      description: '25 min focus session',
      category: ActionCategory.focus,
      execute: () async {
        await FocusModeService.instance.startFocus(preset: 'pomodoro');
        return ActionResult(
          success: true,
          message: 'Pomodoro started - 25 minutes',
        );
      },
      shortcut: 'Ctrl+Shift+P',
    ));

    // Calendar actions
    _actions.add(QuickAction(
      id: 'todays_schedule',
      title: '📅 Today\'s Schedule',
      description: 'View today\'s events',
      category: ActionCategory.calendar,
      execute: () async {
        final result = await VoiceCommandHandler.instance.processCommand('what meetings do I have today');
        return ActionResult(
          success: result.success,
          message: result.message,
        );
      },
      shortcut: 'Ctrl+T',
    ));

    // Habits actions
    _actions.add(QuickAction(
      id: 'check_habits',
      title: '✅ Check Habits',
      description: 'Today\'s habit progress',
      category: ActionCategory.habits,
      execute: () async {
        final result = await VoiceCommandHandler.instance.processCommand('check my habits');
        return ActionResult(
          success: result.success,
          message: result.message,
        );
      },
      shortcut: 'Ctrl+H',
    ));

    // Voice actions
    _actions.add(QuickAction(
      id: 'voice_command',
      title: '🎤 Voice Command',
      description: 'Speak a command',
      category: ActionCategory.voice,
      execute: () async {
        return ActionResult(
          success: true,
          message: 'Listening...',
          data: {'action': 'startListening'},
        );
      },
      shortcut: 'Ctrl+/',
    ));

    // Productivity actions
    _actions.add(QuickAction(
      id: 'daily_summary',
      title: '📊 Daily Summary',
      description: 'Productivity report',
      category: ActionCategory.productivity,
      execute: () async {
        return ActionResult(
          success: true,
          message: 'Generating daily summary...',
          data: {'action': 'showDailySummary'},
        );
      },
      shortcut: 'Ctrl+D',
    ));

    // Quick task
    _actions.add(QuickAction(
      id: 'quick_task',
      title: '✏️ Quick Task',
      description: 'Add task quickly',
      category: ActionCategory.tasks,
      execute: () async {
        return ActionResult(
          success: true,
          message: 'What task would you like to add?',
          data: {'action': 'openQuickTask'},
        );
      },
      shortcut: 'Ctrl+N',
    ));

    // Settings
    _actions.add(QuickAction(
      id: 'settings',
      title: '⚙️ Settings',
      description: 'Open settings',
      category: ActionCategory.system,
      execute: () async {
        return ActionResult(
          success: true,
          message: 'Opening settings',
          data: {'action': 'openSettings'},
        );
      },
      shortcut: 'Ctrl+,',
    ));
  }

  /// Execute quick action
  Future<ActionResult> executeAction(String actionId) async {
    try {
      final action = _actions.firstWhere((a) => a.id == actionId);

      // Track usage
      _usageCount[actionId] = (_usageCount[actionId] ?? 0) + 1;

      AppLogger.info('Executing quick action: ${action.title}');

      final result = await action.execute();

      if (result.success) {
        AppLogger.info('Quick action completed: ${action.title}');
      } else {
        AppLogger.warning('Quick action failed: ${action.title}');
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Error executing quick action', e, stackTrace);
      return ActionResult(
        success: false,
        message: 'Error executing action: $e',
      );
    }
  }

  /// Get all actions
  List<QuickAction> get allActions => List.unmodifiable(_actions);

  /// Get actions by category
  List<QuickAction> getActionsByCategory(ActionCategory category) {
    return _actions.where((a) => a.category == category).toList();
  }

  /// Get frequently used actions
  List<QuickAction> getFrequentActions({int limit = 5}) {
    final sorted = _actions.toList()
      ..sort((a, b) {
        final countA = _usageCount[a.id] ?? 0;
        final countB = _usageCount[b.id] ?? 0;
        return countB.compareTo(countA);
      });

    return sorted.take(limit).toList();
  }

  /// Get suggested actions based on context
  List<QuickAction> getSuggestedActions() {
    final suggestions = <QuickAction>[];

    final hour = DateTime.now().hour;

    // Morning suggestions
    if (hour >= 6 && hour < 9) {
      suggestions.add(_actions.firstWhere((a) => a.id == 'check_habits'));
      suggestions.add(_actions.firstWhere((a) => a.id == 'todays_schedule'));
    }

    // Work hours suggestions
    if (hour >= 9 && hour < 17) {
      if (FocusModeService.instance.isActive) {
        // In focus mode
        suggestions.add(_actions.firstWhere((a) => a.id == 'pomodoro'));
      } else {
        suggestions.add(_actions.firstWhere((a) => a.id == 'start_focus'));
        suggestions.add(_actions.firstWhere((a) => a.id == 'triage_inbox'));
      }
    }

    // Evening suggestions
    if (hour >= 17 && hour < 22) {
      suggestions.add(_actions.firstWhere((a) => a.id == 'daily_summary'));
      suggestions.add(_actions.firstWhere((a) => a.id == 'check_habits'));
    }

    // Always suggest voice command
    if (suggestions.length < 4) {
      suggestions.add(_actions.firstWhere((a) => a.id == 'voice_command'));
    }

    return suggestions.take(5).toList();
  }

  /// Add custom action
  void addCustomAction(QuickAction action) {
    _actions.add(action);
    AppLogger.info('Added custom quick action: ${action.title}');
  }

  /// Remove action
  bool removeAction(String actionId) {
    final removed = _actions.removeWhere((a) => a.id == actionId);
    if (removed > 0) {
      AppLogger.info('Removed quick action: $actionId');
      return true;
    }
    return false;
  }

  /// Get keyboard shortcuts map
  Map<String, QuickAction> get shortcutsMap {
    final map = <String, QuickAction>{};
    for (final action in _actions) {
      if (action.shortcut != null) {
        map[action.shortcut!] = action;
      }
    }
    return map;
  }
}

/// Quick action
class QuickAction {
  final String id;
  final String title;
  final String description;
  final ActionCategory category;
  final Future<ActionResult> Function() execute;
  final String? shortcut;
  final String? icon;

  QuickAction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.execute,
    this.shortcut,
    this.icon,
  });

  @override
  String toString() => '$title${shortcut != null ? " ($shortcut)" : ""}';
}

/// Action result
class ActionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ActionResult({
    required this.success,
    required this.message,
    this.data,
  });

  @override
  String toString() => message;
}

/// Action categories
enum ActionCategory {
  email,
  calendar,
  focus,
  habits,
  tasks,
  voice,
  productivity,
  system,
}
