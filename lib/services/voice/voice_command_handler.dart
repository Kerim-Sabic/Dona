import '../../core/utils/logger.dart';
import '../speech/enhanced_voice_assistant.dart';
import '../gmail/gmail_service.dart';
import '../calendar/calendar_service.dart';
import '../focus/focus_mode_service.dart';
import '../habits/habit_tracker.dart';
import '../reminders/location_reminder_service.dart';
import '../ai/ai_service.dart';
import '../email/email_auto_responder.dart';
import '../relationships/relationship_manager.dart';

/// Voice Command Handler
/// Enables natural language voice control for ALL features
///
/// Examples:
/// - "Check my email"
/// - "Start deep work mode"
/// - "What meetings do I have today?"
/// - "Add habit: morning exercise"
/// - "Send email to john saying I'll be late"
class VoiceCommandHandler {
  static final VoiceCommandHandler _instance = VoiceCommandHandler._internal();
  static VoiceCommandHandler get instance => _instance;

  VoiceCommandHandler._internal();

  // Callback for command results
  Function(VoiceCommandResult)? onCommandExecuted;

  /// Initialize voice command handler
  Future<void> init() async {
    try {
      AppLogger.info('VoiceCommandHandler initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize VoiceCommandHandler', e, stackTrace);
    }
  }

  /// Process voice command
  Future<VoiceCommandResult> processCommand(String command) async {
    try {
      AppLogger.info('Processing voice command: $command');

      final normalizedCommand = command.toLowerCase().trim();

      // Email commands
      if (_isEmailCommand(normalizedCommand)) {
        return await _handleEmailCommand(normalizedCommand);
      }

      // Calendar commands
      if (_isCalendarCommand(normalizedCommand)) {
        return await _handleCalendarCommand(normalizedCommand);
      }

      // Focus mode commands
      if (_isFocusCommand(normalizedCommand)) {
        return await _handleFocusCommand(normalizedCommand);
      }

      // Habit commands
      if (_isHabitCommand(normalizedCommand)) {
        return await _handleHabitCommand(normalizedCommand);
      }

      // Reminder commands
      if (_isReminderCommand(normalizedCommand)) {
        return await _handleReminderCommand(normalizedCommand);
      }

      // Relationship commands
      if (_isRelationshipCommand(normalizedCommand)) {
        return await _handleRelationshipCommand(normalizedCommand);
      }

      // General query
      return await _handleGeneralQuery(normalizedCommand);
    } catch (e, stackTrace) {
      AppLogger.error('Error processing voice command', e, stackTrace);
      return VoiceCommandResult(
        success: false,
        message: 'Sorry, I encountered an error processing that command.',
        action: VoiceAction.error,
      );
    }
  }

  // Email Commands
  bool _isEmailCommand(String command) {
    return command.contains('email') ||
           command.contains('inbox') ||
           command.contains('message') ||
           command.contains('mail');
  }

  Future<VoiceCommandResult> _handleEmailCommand(String command) async {
    // Check email
    if (command.contains('check') || command.contains('show') || command.contains('read')) {
      if (!GmailService.instance.isAuthenticated) {
        return VoiceCommandResult(
          success: false,
          message: 'Please sign in to Gmail first.',
          action: VoiceAction.emailCheck,
        );
      }

      final emails = await GmailService.instance.getInboxMessages(maxResults: 10);
      final unreadCount = emails.where((e) => !(e.isRead ?? true)).length;

      return VoiceCommandResult(
        success: true,
        message: 'You have $unreadCount unread emails out of ${emails.length} recent messages.',
        data: {'emails': emails, 'unreadCount': unreadCount},
        action: VoiceAction.emailCheck,
      );
    }

    // Send email
    if (command.contains('send') || command.contains('compose')) {
      // Extract recipient and message
      final result = await _extractEmailDetails(command);

      return VoiceCommandResult(
        success: true,
        message: 'Ready to send email. Please provide details.',
        data: result,
        action: VoiceAction.emailSend,
      );
    }

    // Triage inbox
    if (command.contains('triage') || command.contains('organize')) {
      final summary = await EmailAutoResponder.instance.processInbox();

      return VoiceCommandResult(
        success: true,
        message: summary.toString(),
        data: {'summary': summary},
        action: VoiceAction.emailTriage,
      );
    }

    return VoiceCommandResult(
      success: false,
      message: 'I didn\'t understand that email command.',
      action: VoiceAction.unknown,
    );
  }

  // Calendar Commands
  bool _isCalendarCommand(String command) {
    return command.contains('meeting') ||
           command.contains('calendar') ||
           command.contains('schedule') ||
           command.contains('appointment');
  }

  Future<VoiceCommandResult> _handleCalendarCommand(String command) async {
    // Check today's schedule
    if (command.contains('today') || command.contains('schedule')) {
      if (!CalendarService.instance.isAuthenticated) {
        return VoiceCommandResult(
          success: false,
          message: 'Please sign in to Google Calendar first.',
          action: VoiceAction.calendarCheck,
        );
      }

      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

      final events = await CalendarService.instance.getEventsInRange(now, endOfDay);

      if (events.isEmpty) {
        return VoiceCommandResult(
          success: true,
          message: 'You have no meetings scheduled for today.',
          data: {'events': events},
          action: VoiceAction.calendarCheck,
        );
      }

      final nextEvent = events.first;
      final timeUntil = nextEvent.startTime.difference(now);

      String message;
      if (timeUntil.inMinutes < 60) {
        message = 'Your next meeting "${nextEvent.title}" is in ${timeUntil.inMinutes} minutes. You have ${events.length} meetings today.';
      } else {
        message = 'You have ${events.length} meetings today. Next: "${nextEvent.title}" at ${_formatTime(nextEvent.startTime)}.';
      }

      return VoiceCommandResult(
        success: true,
        message: message,
        data: {'events': events},
        action: VoiceAction.calendarCheck,
      );
    }

    // Create meeting
    if (command.contains('create') || command.contains('schedule') || command.contains('add')) {
      return VoiceCommandResult(
        success: true,
        message: 'I can help you schedule a meeting. What\'s the meeting about?',
        action: VoiceAction.calendarCreate,
      );
    }

    return VoiceCommandResult(
      success: false,
      message: 'I didn\'t understand that calendar command.',
      action: VoiceAction.unknown,
    );
  }

  // Focus Mode Commands
  bool _isFocusCommand(String command) {
    return command.contains('focus') ||
           command.contains('deep work') ||
           command.contains('pomodoro') ||
           command.contains('don\'t disturb') ||
           command.contains('dnd');
  }

  Future<VoiceCommandResult> _handleFocusCommand(String command) async {
    // Start focus mode
    if (command.contains('start') || command.contains('begin') || command.contains('enable')) {
      String preset = 'deep_work';

      if (command.contains('pomodoro')) {
        preset = 'pomodoro';
      } else if (command.contains('meeting')) {
        preset = 'meeting';
      } else if (command.contains('light')) {
        preset = 'light_focus';
      }

      await FocusModeService.instance.startFocus(preset: preset);

      return VoiceCommandResult(
        success: true,
        message: 'Focus mode started. I\'ll block distractions for you.',
        action: VoiceAction.focusStart,
      );
    }

    // End focus mode
    if (command.contains('stop') || command.contains('end') || command.contains('disable')) {
      await FocusModeService.instance.endFocus();

      return VoiceCommandResult(
        success: true,
        message: 'Focus mode ended. Welcome back!',
        action: VoiceAction.focusEnd,
      );
    }

    // Check focus stats
    if (command.contains('stats') || command.contains('analytics')) {
      final analytics = FocusModeService.instance.getAnalytics(days: 7);

      return VoiceCommandResult(
        success: true,
        message: 'This week: ${analytics.totalSessions} focus sessions, ${analytics.totalFocusTime.inHours} hours total, ${analytics.streakDays} day streak.',
        data: {'analytics': analytics},
        action: VoiceAction.focusStats,
      );
    }

    return VoiceCommandResult(
      success: false,
      message: 'I didn\'t understand that focus command.',
      action: VoiceAction.unknown,
    );
  }

  // Habit Commands
  bool _isHabitCommand(String command) {
    return command.contains('habit') ||
           command.contains('streak') ||
           command.contains('track');
  }

  Future<VoiceCommandResult> _handleHabitCommand(String command) async {
    // Log habit
    if (command.contains('complete') || command.contains('done') || command.contains('log')) {
      return VoiceCommandResult(
        success: true,
        message: 'Which habit did you complete?',
        action: VoiceAction.habitLog,
      );
    }

    // Check habits
    if (command.contains('check') || command.contains('today')) {
      final todaysHabits = HabitTracker.instance.getTodaysHabits();
      final completed = todaysHabits.where(
        (h) => HabitTracker.instance.isCompletedToday(h.id)
      ).length;

      return VoiceCommandResult(
        success: true,
        message: 'You\'ve completed $completed out of ${todaysHabits.length} habits today.',
        data: {'habits': todaysHabits, 'completed': completed},
        action: VoiceAction.habitCheck,
      );
    }

    // Add habit
    if (command.contains('add') || command.contains('create') || command.contains('new')) {
      return VoiceCommandResult(
        success: true,
        message: 'What habit would you like to track?',
        action: VoiceAction.habitAdd,
      );
    }

    return VoiceCommandResult(
      success: false,
      message: 'I didn\'t understand that habit command.',
      action: VoiceAction.unknown,
    );
  }

  // Reminder Commands
  bool _isReminderCommand(String command) {
    return command.contains('remind') ||
           command.contains('reminder');
  }

  Future<VoiceCommandResult> _handleReminderCommand(String command) async {
    // Extract reminder details using AI
    final details = await _extractReminderDetails(command);

    if (details['task'] != null && details['location'] != null) {
      await LocationReminderService.instance.addReminderBySearch(
        task: details['task'],
        searchQuery: details['location'],
      );

      return VoiceCommandResult(
        success: true,
        message: 'I\'ll remind you to ${details['task']} when you\'re near ${details['location']}.',
        action: VoiceAction.reminderAdd,
      );
    }

    return VoiceCommandResult(
      success: true,
      message: 'What should I remind you about?',
      action: VoiceAction.reminderAdd,
    );
  }

  // Relationship Commands
  bool _isRelationshipCommand(String command) {
    return command.contains('contact') ||
           command.contains('follow up') ||
           command.contains('reach out');
  }

  Future<VoiceCommandResult> _handleRelationshipCommand(String command) async {
    if (command.contains('who') || command.contains('follow up')) {
      final needsFollowUp = await RelationshipManager.instance
        .getContactsNeedingFollowUp();

      if (needsFollowUp.isEmpty) {
        return VoiceCommandResult(
          success: true,
          message: 'All your relationships are up to date!',
          action: VoiceAction.relationshipCheck,
        );
      }

      final top3 = needsFollowUp.take(3).map((c) => c.name).join(', ');

      return VoiceCommandResult(
        success: true,
        message: 'Consider following up with: $top3',
        data: {'contacts': needsFollowUp},
        action: VoiceAction.relationshipCheck,
      );
    }

    return VoiceCommandResult(
      success: false,
      message: 'I didn\'t understand that relationship command.',
      action: VoiceAction.unknown,
    );
  }

  // General Query
  Future<VoiceCommandResult> _handleGeneralQuery(String command) async {
    // Use AI to handle general queries
    final response = await AIService.instance.chat(
      'User said: "$command". Respond as Dona, their personal assistant. Be helpful and concise.',
    );

    return VoiceCommandResult(
      success: true,
      message: response,
      action: VoiceAction.generalQuery,
    );
  }

  // Helper: Extract email details
  Future<Map<String, String>> _extractEmailDetails(String command) async {
    try {
      // Use regex to extract basic email components
      final recipientMatch = RegExp(r'to\s+(\w+)').firstMatch(command);
      final sayingMatch = RegExp(r'saying\s+(.+)').firstMatch(command);

      String? recipient;
      String? message;

      if (recipientMatch != null) {
        recipient = recipientMatch.group(1);
      }

      if (sayingMatch != null) {
        message = sayingMatch.group(1);
      } else {
        // If no "saying", the whole command after recipient is the message
        message = command;
      }

      return {
        'recipient': recipient ?? '',
        'subject': 'Quick message',
        'message': message ?? command,
      };
    } catch (e) {
      AppLogger.error('Error extracting email details', e);
      return {'message': command};
    }
  }

  // Helper: Extract reminder details
  Future<Map<String, String>> _extractReminderDetails(String command) async {
    try {
      final lowerCommand = command.toLowerCase();

      // Pattern: "remind me to [task] when/at [location]"
      String? task;
      String? location;

      // Extract task
      final taskMatch = RegExp(r'remind me to\s+(.+?)\s+(?:when|at)').firstMatch(lowerCommand);
      if (taskMatch != null) {
        task = taskMatch.group(1);
      } else {
        // Try without location
        final simpleTaskMatch = RegExp(r'remind me to\s+(.+)').firstMatch(lowerCommand);
        if (simpleTaskMatch != null) {
          task = simpleTaskMatch.group(1);
        }
      }

      // Extract location
      final locationMatch = RegExp(r'(?:when|at|near)\s+(?:i\'m\s+)?(?:at\s+)?(?:the\s+)?(.+)').firstMatch(lowerCommand);
      if (locationMatch != null) {
        location = locationMatch.group(1);
      }

      return {
        'task': task ?? command,
        'location': location ?? '',
      };
    } catch (e) {
      AppLogger.error('Error extracting reminder details', e);
      return {'task': command, 'location': ''};
    }
  }

  // Helper: Format time
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Voice command result
class VoiceCommandResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final VoiceAction action;

  VoiceCommandResult({
    required this.success,
    required this.message,
    this.data,
    required this.action,
  });

  @override
  String toString() => message;
}

/// Voice action types
enum VoiceAction {
  emailCheck,
  emailSend,
  emailTriage,
  calendarCheck,
  calendarCreate,
  focusStart,
  focusEnd,
  focusStats,
  habitLog,
  habitCheck,
  habitAdd,
  reminderAdd,
  relationshipCheck,
  generalQuery,
  unknown,
  error,
}
