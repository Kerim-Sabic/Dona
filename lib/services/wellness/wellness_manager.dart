import 'dart:async';
import '../../core/utils/logger.dart';
import '../../data/user_profile.dart';
import '../calendar/calendar_service.dart';

/// Wellness Manager for work-life balance
class WellnessManager {
  static final WellnessManager _instance = WellnessManager._internal();
  static WellnessManager get instance => _instance;

  WellnessManager._internal();

  Timer? _monitoringTimer;
  DateTime? _lastBreakReminder;
  DateTime? _workDayStart;
  int _consecutiveWorkHours = 0;

  // Callbacks
  Function(WellnessAlert)? onAlert;

  /// Start wellness monitoring
  void startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkWellness();
    });
    AppLogger.info('Wellness monitoring started');
  }

  /// Stop wellness monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    AppLogger.info('Wellness monitoring stopped');
  }

  Future<void> _checkWellness() async {
    await Future.wait([
      _checkBreakTime(),
      _checkWorkHours(),
      _checkMeetingLoad(),
      _checkLunchBreak(),
      _checkEndOfDay(),
    ]);
  }

  /// Check if user needs a break
  Future<void> _checkBreakTime() async {
    final now = DateTime.now();

    if (_workDayStart == null && UserProfile.instance.isWorkHours) {
      _workDayStart = now;
    }

    if (_workDayStart != null) {
      final workDuration = now.difference(_workDayStart!);

      // Break every 2 hours
      if (workDuration.inMinutes > 120 && workDuration.inMinutes % 120 < 15) {
        if (_lastBreakReminder == null ||
            now.difference(_lastBreakReminder!).inMinutes > 120) {
          _sendAlert(WellnessAlert(
            type: WellnessAlertType.break_needed,
            title: 'Time for a Break',
            message: 'You\'ve been working for ${workDuration.inHours} hours. Take a 10-minute break?',
            priority: WellnessPriority.medium,
            actions: [
              WellnessAction('Take 10 min', () => _startBreak(10)),
              WellnessAction('Take 5 min', () => _startBreak(5)),
              WellnessAction('Later', () {}),
            ],
          ));
          _lastBreakReminder = now;
        }
      }
    }
  }

  /// Check total work hours
  Future<void> _checkWorkHours() async {
    if (_workDayStart == null) return;

    final workDuration = DateTime.now().difference(_workDayStart!);

    // Alert after 8 hours
    if (workDuration.inHours >= 8 && workDuration.inMinutes % 60 < 15) {
      _sendAlert(WellnessAlert(
        type: WellnessAlertType.overwork,
        title: 'Long Day Alert',
        message: 'You\'ve been working for ${workDuration.inHours} hours. Consider wrapping up soon.',
        priority: WellnessPriority.high,
      ));
    }

    // Critical alert after 10 hours
    if (workDuration.inHours >= 10) {
      _sendAlert(WellnessAlert(
        type: WellnessAlertType.overwork,
        title: 'Work-Life Balance',
        message: 'You\'ve worked ${workDuration.inHours} hours today. Time to rest!',
        priority: WellnessPriority.critical,
      ));
    }
  }

  /// Check meeting load
  Future<void> _checkMeetingLoad() async {
    try {
      final now = DateTime.now();
      final events = await CalendarService.instance.getEventsInRange(
        DateTime(now.year, now.month, now.day, 0),
        DateTime(now.year, now.month, now.day, 23, 59),
      );

      final maxMeetings = UserProfile.instance.maxMeetingsPerDay;

      if (events.length >= maxMeetings) {
        _sendAlert(WellnessAlert(
          type: WellnessAlertType.meeting_overload,
          title: 'Heavy Meeting Day',
          message: 'You have ${events.length} meetings today. That\'s a lot! Protect some focus time tomorrow?',
          priority: WellnessPriority.medium,
        ));
      }

      // Check for back-to-back meetings
      for (int i = 0; i < events.length - 1; i++) {
        final gap = events[i + 1].startTime.difference(events[i].endTime);
        if (gap.inMinutes < 10) {
          _sendAlert(WellnessAlert(
            type: WellnessAlertType.no_buffer,
            title: 'Back-to-Back Meetings',
            message: 'No buffer between meetings at ${_formatTime(events[i].endTime)}. Need a reschedule?',
            priority: WellnessPriority.medium,
          ));
          break; // Only alert once
        }
      }
    } catch (e) {
      AppLogger.error('Error checking meeting load', e);
    }
  }

  /// Check lunch break
  Future<void> _checkLunchBreak() async {
    final now = DateTime.now();

    // Check around 12:30 PM
    if (now.hour == 12 && now.minute >= 30 && now.minute < 45) {
      try {
        final events = await CalendarService.instance.getEventsInRange(
          DateTime(now.year, now.month, now.day, 12, 0),
          DateTime(now.year, now.month, now.day, 13, 30),
        );

        if (events.isNotEmpty) {
          _sendAlert(WellnessAlert(
            type: WellnessAlertType.no_lunch,
            title: 'Lunch Break',
            message: 'You have a meeting during lunch. Don\'t forget to eat!',
            priority: WellnessPriority.medium,
          ));
        }
      } catch (e) {
        AppLogger.error('Error checking lunch break', e);
      }
    }
  }

  /// Check end of day
  Future<void> _checkEndOfDay() async {
    final now = DateTime.now();
    final (_, workEnd) = UserProfile.instance.workHours;

    // Remind at end of work day
    if (now.hour == workEnd && now.minute < 15) {
      _sendAlert(WellnessAlert(
        type: WellnessAlertType.end_of_day,
        title: 'End of Day',
        message: 'Great work today! Ready to wrap up?',
        priority: WellnessPriority.low,
        actions: [
          WellnessAction('Show summary', () => _showDaySummary()),
          WellnessAction('Continue working', () {}),
        ],
      ));
    }
  }

  /// Start a break
  void _startBreak(int minutes) {
    AppLogger.info('Starting $minutes minute break');
    _sendAlert(WellnessAlert(
      type: WellnessAlertType.break_started,
      title: 'Break Time',
      message: 'Enjoy your $minutes minute break. I\'ll remind you when it\'s over.',
      priority: WellnessPriority.low,
    ));

    // Set reminder for end of break
    Future.delayed(Duration(minutes: minutes), () {
      _sendAlert(WellnessAlert(
        type: WellnessAlertType.break_ended,
        title: 'Break Over',
        message: 'Ready to get back to it? You\'ve got this!',
        priority: WellnessPriority.low,
      ));
    });
  }

  /// Show day summary
  void _showDaySummary() {
    AppLogger.info('Showing day summary');
    // This would trigger UI to show summary
  }

  /// Send wellness alert
  void _sendAlert(WellnessAlert alert) {
    AppLogger.info('Wellness alert: ${alert.title}');
    if (onAlert != null) {
      onAlert!(alert);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Reset for new day
  void resetDay() {
    _workDayStart = null;
    _consecutiveWorkHours = 0;
    _lastBreakReminder = null;
  }
}

class WellnessAlert {
  final WellnessAlertType type;
  final String title;
  final String message;
  final WellnessPriority priority;
  final List<WellnessAction>? actions;

  WellnessAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    this.actions,
  });
}

class WellnessAction {
  final String label;
  final VoidCallback onTap;

  WellnessAction(this.label, this.onTap);
}

enum WellnessAlertType {
  break_needed,
  overwork,
  meeting_overload,
  no_buffer,
  no_lunch,
  end_of_day,
  break_started,
  break_ended,
}

enum WellnessPriority {
  low,
  medium,
  high,
  critical,
}

typedef VoidCallback = void Function();
