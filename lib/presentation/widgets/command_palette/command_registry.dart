import 'package:flutter/material.dart';
import 'command_models.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/autopilot/autopilots/plan_my_day_autopilot.dart';
import '../../../domain/autopilot/autopilots/study_autopilot.dart';
import '../../../domain/autopilot/autopilots/weekly_review_autopilot.dart';
import '../../../domain/autopilot/autopilots/focus_mode_autopilot.dart';
import '../../../domain/autopilot/autopilots/triage_autopilot.dart';
import '../../../domain/autopilot/autopilots/relationship_autopilot.dart';
import '../../../domain/autopilot/autopilot_engine.dart';

/// Central registry for all command palette commands
class CommandRegistry {
  static final CommandRegistry _instance = CommandRegistry._internal();
  static CommandRegistry get instance => _instance;

  CommandRegistry._internal();

  final List<PaletteCommand> _commands = [];
  BuildContext? _context;

  /// Initialize command registry with app context
  void init(BuildContext context) {
    _context = context;
    _registerCommands();
    AppLogger.info('Command Registry initialized with ${_commands.length} commands');
  }

  /// Get all commands
  List<PaletteCommand> get allCommands => List.unmodifiable(_commands);

  /// Search commands by query
  List<PaletteCommand> search(String query) {
    if (query.isEmpty) return _commands;

    return _commands.where((cmd) => cmd.matches(query)).toList();
  }

  /// Get commands by category
  List<PaletteCommand> getByCategory(String category) {
    return _commands.where((cmd) => cmd.category == category).toList();
  }

  /// Register all commands
  void _registerCommands() {
    _commands.clear();

    // Autopilot Commands
    _registerAutopilotCommands();

    // Navigation Commands
    _registerNavigationCommands();

    // Action Commands
    _registerActionCommands();

    // Search Commands
    _registerSearchCommands();
  }

  /// Register autopilot commands
  void _registerAutopilotCommands() {
    // Plan My Day
    _commands.add(PaletteCommand(
      id: 'autopilot_plan_my_day',
      title: 'Plan My Day',
      description: 'Automatically organize your day with optimized scheduling',
      category: 'autopilot',
      keywords: ['plan', 'day', 'schedule', 'organize', 'autopilot'],
      icon: '📅',
      onExecute: () async {
        await _executeAutopilot(
          () => PlanMyDayAutopilot.instance.generatePlan(),
          'Plan My Day',
        );
      },
    ));

    // Study Autopilot
    _commands.add(PaletteCommand(
      id: 'autopilot_study',
      title: 'Study Autopilot',
      description: 'Create a personalized study plan for your courses',
      category: 'autopilot',
      keywords: ['study', 'exam', 'learn', 'autopilot', 'flashcards'],
      icon: '📚',
      onExecute: () async {
        await _executeAutopilot(
          () => StudyAutopilot.instance.generatePlan(),
          'Study Autopilot',
        );
      },
    ));

    // Weekly Review
    _commands.add(PaletteCommand(
      id: 'autopilot_weekly_review',
      title: 'Weekly Review',
      description: 'Review last week and plan the upcoming week',
      category: 'autopilot',
      keywords: ['weekly', 'review', 'plan', 'week', 'autopilot', 'retrospective'],
      icon: '📊',
      onExecute: () async {
        await _executeAutopilot(
          () => WeeklyReviewAutopilot.instance.generatePlan(),
          'Weekly Review',
        );
      },
    ));

    // Focus Mode
    _commands.add(PaletteCommand(
      id: 'autopilot_focus_mode',
      title: 'Start Focus Session',
      description: 'Create a deep work session with Pomodoro breaks',
      category: 'autopilot',
      keywords: ['focus', 'deep work', 'pomodoro', 'concentrate', 'autopilot'],
      icon: '🎯',
      onExecute: () async {
        await _executeAutopilot(
          () => FocusModeAutopilot.instance.generatePlan(),
          'Focus Session',
        );
      },
    ));

    // Triage
    _commands.add(PaletteCommand(
      id: 'autopilot_triage',
      title: 'Triage Inbox & Tasks',
      description: 'Organize and prioritize your inbox and task list',
      category: 'autopilot',
      keywords: ['triage', 'inbox', 'tasks', 'organize', 'autopilot', 'clean'],
      icon: '📋',
      onExecute: () async {
        await _executeAutopilot(
          () => TriageAutopilot.instance.generatePlan(),
          'Triage',
        );
      },
    ));

    // Relationship
    _commands.add(PaletteCommand(
      id: 'autopilot_relationship',
      title: 'Relationship Maintenance',
      description: 'Stay connected with important people in your life',
      category: 'autopilot',
      keywords: ['relationship', 'people', 'connect', 'friends', 'autopilot'],
      icon: '🤝',
      onExecute: () async {
        await _executeAutopilot(
          () => RelationshipAutopilot.instance.generatePlan(),
          'Relationship Maintenance',
        );
      },
    ));
  }

  /// Register navigation commands
  void _registerNavigationCommands() {
    _commands.add(PaletteCommand(
      id: 'nav_command_center',
      title: 'Open Command Center',
      description: 'View your daily context and recommendations',
      category: 'navigation',
      keywords: ['command', 'center', 'home', 'dashboard'],
      icon: '🏠',
      onExecute: () async {
        if (_context != null) {
          Navigator.of(_context!).pushNamed('/command-center');
        }
      },
    ));

    _commands.add(PaletteCommand(
      id: 'nav_tasks',
      title: 'Open Tasks',
      description: 'View and manage your tasks',
      category: 'navigation',
      keywords: ['tasks', 'todo', 'list'],
      icon: '✅',
      onExecute: () async {
        if (_context != null) {
          Navigator.of(_context!).pushNamed('/tasks');
        }
      },
    ));

    _commands.add(PaletteCommand(
      id: 'nav_calendar',
      title: 'Open Calendar',
      description: 'View your calendar and events',
      category: 'navigation',
      keywords: ['calendar', 'events', 'schedule'],
      icon: '📆',
      onExecute: () async {
        if (_context != null) {
          Navigator.of(_context!).pushNamed('/calendar');
        }
      },
    ));

    _commands.add(PaletteCommand(
      id: 'nav_courses',
      title: 'Open Courses',
      description: 'View your courses and academic info',
      category: 'navigation',
      keywords: ['courses', 'classes', 'school', 'study'],
      icon: '🎓',
      onExecute: () async {
        if (_context != null) {
          Navigator.of(_context!).pushNamed('/courses');
        }
      },
    ));

    _commands.add(PaletteCommand(
      id: 'nav_diagnostics',
      title: 'Open Diagnostics',
      description: 'View system diagnostics and logs (debug only)',
      category: 'navigation',
      keywords: ['diagnostics', 'debug', 'logs', 'dev'],
      icon: '🔧',
      onExecute: () async {
        if (_context != null) {
          Navigator.of(_context!).pushNamed('/diagnostics');
        }
      },
    ));
  }

  /// Register action commands
  void _registerActionCommands() {
    _commands.add(PaletteCommand(
      id: 'action_add_task',
      title: 'Add Task',
      description: 'Quickly create a new task',
      category: 'action',
      keywords: ['add', 'task', 'create', 'new', 'todo'],
      icon: '➕',
      onExecute: () async {
        // Show add task dialog
        AppLogger.info('Add task action triggered');
      },
    ));

    _commands.add(PaletteCommand(
      id: 'action_add_event',
      title: 'Add Event',
      description: 'Create a new calendar event',
      category: 'action',
      keywords: ['add', 'event', 'create', 'calendar', 'meeting'],
      icon: '📅',
      onExecute: () async {
        // Show add event dialog
        AppLogger.info('Add event action triggered');
      },
    ));
  }

  /// Register search commands
  void _registerSearchCommands() {
    _commands.add(PaletteCommand(
      id: 'search_courses',
      title: 'Search Courses',
      description: 'Find a specific course',
      category: 'search',
      keywords: ['search', 'find', 'course', 'class'],
      icon: '🔍',
      onExecute: () async {
        AppLogger.info('Search courses triggered');
      },
    ));

    _commands.add(PaletteCommand(
      id: 'search_tasks',
      title: 'Search Tasks',
      description: 'Find a specific task',
      category: 'search',
      keywords: ['search', 'find', 'task', 'todo'],
      icon: '🔍',
      onExecute: () async {
        AppLogger.info('Search tasks triggered');
      },
    ));
  }

  /// Execute an autopilot command
  Future<void> _executeAutopilot(
    Future<dynamic> Function() generatePlan,
    String autopilotName,
  ) async {
    try {
      AppLogger.info('Executing autopilot: $autopilotName');

      final plan = await generatePlan();

      // Show autopilot preview/approval dialog
      // This would be implemented in the UI layer
      if (_context != null) {
        // Navigate to autopilot preview screen or show dialog
        AppLogger.info('Autopilot plan generated: ${plan.planName}');

        // In a real implementation, you'd show a preview dialog here
        // For now, just execute through the engine
        await AutopilotEngine.instance.executePlan(plan.id);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to execute autopilot: $autopilotName', e, stackTrace);
    }
  }
}
