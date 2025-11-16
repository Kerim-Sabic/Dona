import 'dart:async';
import '../../core/utils/logger.dart';
import '../notifications/smart_notification_service.dart';
import '../calendar/calendar_service.dart';
import '../../data/user_profile.dart';
import '../storage/local_storage_service.dart';
import '../analytics/activity_tracker.dart';
import 'dart:convert';

/// Focus Mode Service
/// Helps users maintain deep work sessions by:
/// - Blocking distractions
/// - Silencing non-critical notifications
/// - Tracking focus time
/// - Providing focus analytics
/// - Auto-enabling based on calendar
class FocusModeService {
  static final FocusModeService _instance = FocusModeService._internal();
  static FocusModeService get instance => _instance;

  FocusModeService._internal();

  bool _isActive = false;
  FocusSession? _currentSession;
  final List<FocusSession> _history = [];
  Timer? _sessionTimer;

  // Focus mode presets
  final Map<String, FocusPreset> _presets = {
    'deep_work': FocusPreset(
      name: 'Deep Work',
      duration: const Duration(hours: 2),
      allowedCategories: [NotificationCategory.critical],
      blockEmails: true,
      blockMessages: true,
      enableDoNotDisturb: true,
    ),
    'meeting': FocusPreset(
      name: 'Meeting',
      duration: const Duration(hours: 1),
      allowedCategories: [NotificationCategory.critical],
      blockEmails: true,
      blockMessages: true,
      enableDoNotDisturb: true,
    ),
    'light_focus': FocusPreset(
      name: 'Light Focus',
      duration: const Duration(minutes: 45),
      allowedCategories: [
        NotificationCategory.critical,
        NotificationCategory.work,
      ],
      blockEmails: false,
      blockMessages: true,
      enableDoNotDisturb: false,
    ),
    'pomodoro': FocusPreset(
      name: 'Pomodoro',
      duration: const Duration(minutes: 25),
      allowedCategories: [NotificationCategory.critical],
      blockEmails: true,
      blockMessages: true,
      enableDoNotDisturb: true,
    ),
  };

  // Callbacks
  Function(bool)? onFocusModeChanged;
  Function(FocusSession)? onSessionComplete;

  /// Initialize focus mode service
  Future<void> init() async {
    try {
      await _loadHistory();
      AppLogger.info('FocusModeService initialized with ${_history.length} past sessions');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize FocusModeService', e, stackTrace);
    }
  }

  /// Start focus mode with preset
  Future<void> startFocus({
    String preset = 'deep_work',
    Duration? customDuration,
    String? goal,
  }) async {
    try {
      if (_isActive) {
        AppLogger.warning('Focus mode already active');
        return;
      }

      final focusPreset = _presets[preset] ?? _presets['deep_work']!;
      final duration = customDuration ?? focusPreset.duration;

      _currentSession = FocusSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        preset: focusPreset,
        startTime: DateTime.now(),
        plannedDuration: duration,
        goal: goal,
      );

      _isActive = true;

      // Enable Do Not Disturb if required
      if (focusPreset.enableDoNotDisturb) {
        await SmartNotificationService.instance.enableDoNotDisturb(
          duration: duration,
        );
      }

      // Set timer to auto-end session
      _sessionTimer = Timer(duration, () {
        endFocus();
      });

      if (onFocusModeChanged != null) {
        onFocusModeChanged!(_isActive);
      }

      // Track activity
      ActivityTracker.instance.startActivity(
        ActivityType.focusWork,
        metadata: {'preset': focusPreset.name, 'goal': goal},
      );

      AppLogger.info('Started focus session: ${focusPreset.name} for ${duration.inMinutes}min');
    } catch (e, stackTrace) {
      AppLogger.error('Error starting focus mode', e, stackTrace);
    }
  }

  /// End focus mode
  Future<void> endFocus() async {
    try {
      if (!_isActive || _currentSession == null) {
        AppLogger.warning('No active focus session');
        return;
      }

      _currentSession!.endTime = DateTime.now();
      _currentSession!.actualDuration = _currentSession!.endTime!.difference(
        _currentSession!.startTime,
      );

      // Calculate productivity score
      _currentSession!.productivityScore = _calculateProductivityScore(
        _currentSession!,
      );

      // Save to history
      _history.add(_currentSession!);
      await _saveHistory();

      // Stop timer
      _sessionTimer?.cancel();
      _sessionTimer = null;

      // Disable Do Not Disturb
      SmartNotificationService.instance.disableDoNotDisturb();

      // End activity tracking
      ActivityTracker.instance.endCurrentActivity();

      // Also log the session to insights
      ActivityTracker.instance.trackFocusSession(
        _currentSession!.actualDuration!,
        metadata: {
          'preset': _currentSession!.preset.name,
          'goal': _currentSession!.goal,
          'productivityScore': _currentSession!.productivityScore,
        },
      );

      if (onSessionComplete != null) {
        onSessionComplete!(_currentSession!);
      }

      if (onFocusModeChanged != null) {
        onFocusModeChanged!(false);
      }

      AppLogger.info('Ended focus session. Duration: ${_currentSession!.actualDuration!.inMinutes}min');

      _isActive = false;
      _currentSession = null;
    } catch (e, stackTrace) {
      AppLogger.error('Error ending focus mode', e, stackTrace);
    }
  }

  /// Calculate productivity score (0-100)
  double _calculateProductivityScore(FocusSession session) {
    if (session.actualDuration == null) return 0;

    final plannedMinutes = session.plannedDuration.inMinutes;
    final actualMinutes = session.actualDuration!.inMinutes;

    // Score based on completion percentage
    final completionScore = (actualMinutes / plannedMinutes) * 100;

    // Cap at 100, even if user went over
    return completionScore.clamp(0, 100);
  }

  /// Auto-start focus mode based on calendar event
  Future<void> autoStartFromCalendar(String eventTitle) async {
    try {
      AppLogger.info('Auto-starting focus mode for: $eventTitle');

      // Determine preset based on event title
      String preset = 'deep_work';

      if (eventTitle.toLowerCase().contains('meeting') ||
          eventTitle.toLowerCase().contains('call')) {
        preset = 'meeting';
      } else if (eventTitle.toLowerCase().contains('focus') ||
                 eventTitle.toLowerCase().contains('deep work')) {
        preset = 'deep_work';
      }

      await startFocus(
        preset: preset,
        goal: eventTitle,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error auto-starting focus mode', e, stackTrace);
    }
  }

  /// Get focus analytics
  FocusAnalytics getAnalytics({int days = 7}) {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final recentSessions = _history.where(
        (s) => s.startTime.isAfter(cutoffDate),
      ).toList();

      if (recentSessions.isEmpty) {
        return FocusAnalytics(
          totalSessions: 0,
          totalFocusTime: Duration.zero,
          averageSessionLength: Duration.zero,
          averageProductivityScore: 0,
          mostUsedPreset: 'None',
          streakDays: 0,
        );
      }

      // Calculate total focus time
      final totalMinutes = recentSessions.fold<int>(
        0,
        (sum, session) => sum + (session.actualDuration?.inMinutes ?? 0),
      );

      // Calculate average session length
      final avgMinutes = totalMinutes ~/ recentSessions.length;

      // Calculate average productivity score
      final avgScore = recentSessions.fold<double>(
        0,
        (sum, session) => sum + session.productivityScore,
      ) / recentSessions.length;

      // Find most used preset
      final presetCounts = <String, int>{};
      for (final session in recentSessions) {
        presetCounts[session.preset.name] =
          (presetCounts[session.preset.name] ?? 0) + 1;
      }

      final mostUsed = presetCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

      // Calculate streak
      final streak = _calculateStreak();

      return FocusAnalytics(
        totalSessions: recentSessions.length,
        totalFocusTime: Duration(minutes: totalMinutes),
        averageSessionLength: Duration(minutes: avgMinutes),
        averageProductivityScore: avgScore,
        mostUsedPreset: mostUsed,
        streakDays: streak,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating analytics', e, stackTrace);
      return FocusAnalytics(
        totalSessions: 0,
        totalFocusTime: Duration.zero,
        averageSessionLength: Duration.zero,
        averageProductivityScore: 0,
        mostUsedPreset: 'None',
        streakDays: 0,
      );
    }
  }

  /// Calculate focus streak (consecutive days with focus sessions)
  int _calculateStreak() {
    if (_history.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final sessionsOnDate = _history.where((session) =>
        session.startTime.year == checkDate.year &&
        session.startTime.month == checkDate.month &&
        session.startTime.day == checkDate.day
      );

      if (sessionsOnDate.isEmpty) {
        break;
      }

      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Get current session
  FocusSession? get currentSession => _currentSession;

  /// Check if focus mode is active
  bool get isActive => _isActive;

  /// Get focus presets
  Map<String, FocusPreset> get presets => Map.unmodifiable(_presets);

  /// Get session history
  List<FocusSession> get history => List.unmodifiable(_history);

  /// Add custom preset
  void addPreset(String key, FocusPreset preset) {
    _presets[key] = preset;
    AppLogger.info('Added custom focus preset: ${preset.name}');
  }

  /// Load history from storage
  Future<void> _loadHistory() async {
    try {
      final json = LocalStorageService.instance.getString('focus_history');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _history.clear();
        _history.addAll(
          data.map((item) => FocusSession.fromJson(item)),
        );
        AppLogger.info('Loaded ${_history.length} focus sessions');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading focus history', e, stackTrace);
    }
  }

  /// Save history to storage
  Future<void> _saveHistory() async {
    try {
      final json = jsonEncode(_history.map((s) => s.toJson()).toList());
      await LocalStorageService.instance.setString('focus_history', json);
      AppLogger.debug('Saved ${_history.length} focus sessions');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving focus history', e, stackTrace);
    }
  }
}

/// Focus preset
class FocusPreset {
  final String name;
  final Duration duration;
  final List<NotificationCategory> allowedCategories;
  final bool blockEmails;
  final bool blockMessages;
  final bool enableDoNotDisturb;

  FocusPreset({
    required this.name,
    required this.duration,
    required this.allowedCategories,
    this.blockEmails = true,
    this.blockMessages = true,
    this.enableDoNotDisturb = true,
  });
}

/// Focus session
class FocusSession {
  final String id;
  final FocusPreset preset;
  final DateTime startTime;
  DateTime? endTime;
  final Duration plannedDuration;
  Duration? actualDuration;
  final String? goal;
  double productivityScore;
  int interruptions;

  FocusSession({
    required this.id,
    required this.preset,
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    this.actualDuration,
    this.goal,
    this.productivityScore = 0,
    this.interruptions = 0,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      preset: FocusPreset(
        name: json['presetName'] as String,
        duration: Duration(minutes: json['plannedMinutes'] as int),
        allowedCategories: [],
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
        ? DateTime.parse(json['endTime'] as String)
        : null,
      plannedDuration: Duration(minutes: json['plannedMinutes'] as int),
      actualDuration: json['actualMinutes'] != null
        ? Duration(minutes: json['actualMinutes'] as int)
        : null,
      goal: json['goal'] as String?,
      productivityScore: (json['productivityScore'] as num?)?.toDouble() ?? 0,
      interruptions: json['interruptions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'presetName': preset.name,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      'plannedMinutes': plannedDuration.inMinutes,
      if (actualDuration != null) 'actualMinutes': actualDuration!.inMinutes,
      if (goal != null) 'goal': goal,
      'productivityScore': productivityScore,
      'interruptions': interruptions,
    };
  }
}

/// Focus analytics
class FocusAnalytics {
  final int totalSessions;
  final Duration totalFocusTime;
  final Duration averageSessionLength;
  final double averageProductivityScore;
  final String mostUsedPreset;
  final int streakDays;

  FocusAnalytics({
    required this.totalSessions,
    required this.totalFocusTime,
    required this.averageSessionLength,
    required this.averageProductivityScore,
    required this.mostUsedPreset,
    required this.streakDays,
  });

  @override
  String toString() {
    return '''
Focus Analytics (Last 7 Days):
  Total sessions: $totalSessions
  Total focus time: ${totalFocusTime.inHours}h ${totalFocusTime.inMinutes % 60}m
  Average session: ${averageSessionLength.inMinutes}min
  Avg productivity: ${averageProductivityScore.toStringAsFixed(1)}%
  Favorite preset: $mostUsedPreset
  Current streak: $streakDays days
''';
  }
}
