import 'dart:async';
import '../../core/utils/logger.dart';
import 'productivity_insights.dart';

/// Activity Tracker
/// Automatically tracks user activities for productivity insights
/// This hooks into all services to provide REAL data
class ActivityTracker {
  static final ActivityTracker _instance = ActivityTracker._internal();
  static ActivityTracker get instance => _instance;

  ActivityTracker._internal();

  Timer? _activityTimer;
  ActivityType? _currentActivity;
  DateTime? _currentActivityStart;

  /// Initialize activity tracker
  Future<void> init() async {
    try {
      AppLogger.info('ActivityTracker initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ActivityTracker', e, stackTrace);
    }
  }

  /// Start tracking an activity
  void startActivity(ActivityType type, {Map<String, dynamic>? metadata}) {
    // End current activity if any
    if (_currentActivity != null) {
      endCurrentActivity();
    }

    _currentActivity = type;
    _currentActivityStart = DateTime.now();

    AppLogger.debug('Started tracking activity: ${type.name}');
  }

  /// End current activity
  void endCurrentActivity() {
    if (_currentActivity == null || _currentActivityStart == null) {
      return;
    }

    final duration = DateTime.now().difference(_currentActivityStart!);

    // Log the activity
    ProductivityInsights.instance.logActivity(
      _currentActivity!,
      duration,
    );

    AppLogger.debug('Ended activity: ${_currentActivity!.name} (${duration.inMinutes}min)');

    _currentActivity = null;
    _currentActivityStart = null;
  }

  /// Track email reading session
  void trackEmailSession() {
    startActivity(ActivityType.email);
  }

  /// Track meeting
  void trackMeeting(Duration duration, {Map<String, dynamic>? metadata}) {
    ProductivityInsights.instance.logActivity(
      ActivityType.meeting,
      duration,
      metadata: metadata,
    );
  }

  /// Track focus session
  void trackFocusSession(Duration duration, {Map<String, dynamic>? metadata}) {
    ProductivityInsights.instance.logActivity(
      ActivityType.focusWork,
      duration,
      metadata: metadata,
    );
  }

  /// Track break
  void trackBreak(Duration duration) {
    ProductivityInsights.instance.logActivity(
      ActivityType.break_,
      duration,
    );
  }

  /// Track task completion
  void trackTaskCompletion({Map<String, dynamic>? metadata}) {
    ProductivityInsights.instance.logActivity(
      ActivityType.task,
      const Duration(minutes: 1), // Completion event
      metadata: metadata,
    );
  }

  /// Get current activity
  ActivityType? get currentActivity => _currentActivity;

  /// Check if currently tracking
  bool get isTracking => _currentActivity != null;

  /// Get current session duration
  Duration? get currentSessionDuration {
    if (_currentActivityStart == null) return null;
    return DateTime.now().difference(_currentActivityStart!);
  }
}
