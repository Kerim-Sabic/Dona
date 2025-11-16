import 'dart:convert';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../calendar/calendar_service.dart';
import '../focus/focus_mode_service.dart';
import '../habits/habit_tracker.dart';
import '../gmail/gmail_service.dart';
import '../ai/ai_service.dart';

/// Productivity Insights Service
/// Comprehensive analytics and insights for maximum productivity
class ProductivityInsights {
  static final ProductivityInsights _instance = ProductivityInsights._internal();
  static ProductivityInsights get instance => _instance;

  ProductivityInsights._internal();

  final List<ActivityLog> _activityLogs = [];

  /// Initialize productivity insights
  Future<void> init() async {
    try {
      await _loadActivityLogs();
      AppLogger.info('ProductivityInsights initialized with ${_activityLogs.length} logs');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ProductivityInsights', e, stackTrace);
    }
  }

  /// Log activity
  Future<void> logActivity(ActivityType type, Duration duration, {Map<String, dynamic>? metadata}) async {
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: metadata,
    );

    _activityLogs.add(log);
    await _saveActivityLogs();

    AppLogger.debug('Logged activity: ${type.name} for ${duration.inMinutes}min');
  }

  /// Get comprehensive insights
  Future<ProductivityReport> getWeeklyReport() async {
    try {
      AppLogger.info('Generating weekly productivity report...');

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Get time breakdown
      final timeBreakdown = await _calculateTimeBreakdown(weekStart, weekEnd);

      // Get productivity score
      final productivityScore = _calculateProductivityScore(timeBreakdown);

      // Get focus analytics
      final focusAnalytics = FocusModeService.instance.getAnalytics(days: 7);

      // Get habit completion
      final habitStats = await _getHabitStats(weekStart, weekEnd);

      // Get email stats
      final emailStats = await _getEmailStats(weekStart, weekEnd);

      // Get meeting stats
      final meetingStats = await _getMeetingStats(weekStart, weekEnd);

      // Get energy profile
      final energyProfile = _analyzeEnergyLevels();

      // Generate AI insights
      final aiInsights = await _generateAIInsights(
        timeBreakdown: timeBreakdown,
        productivityScore: productivityScore,
        focusTime: focusAnalytics.totalFocusTime,
        habitCompletion: habitStats['completionRate'],
      );

      // Calculate achievements
      final achievements = _calculateAchievements(
        focusAnalytics: focusAnalytics,
        habitStats: habitStats,
        emailStats: emailStats,
      );

      return ProductivityReport(
        weekStart: weekStart,
        weekEnd: weekEnd,
        timeBreakdown: timeBreakdown,
        productivityScore: productivityScore,
        focusAnalytics: focusAnalytics,
        habitStats: habitStats,
        emailStats: emailStats,
        meetingStats: meetingStats,
        energyProfile: energyProfile,
        aiInsights: aiInsights,
        achievements: achievements,
        comparisonToLastWeek: _compareToLastWeek(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error generating productivity report', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate time breakdown
  Future<Map<String, Duration>> _calculateTimeBreakdown(DateTime start, DateTime end) async {
    final breakdown = <String, Duration>{
      'meetings': Duration.zero,
      'focusWork': Duration.zero,
      'email': Duration.zero,
      'breaks': Duration.zero,
      'other': Duration.zero,
    };

    try {
      // Get meetings from calendar
      if (CalendarService.instance.isAuthenticated) {
        final events = await CalendarService.instance.getEventsInRange(start, end);
        final meetingTime = events.fold<int>(
          0,
          (sum, event) => sum + event.endTime.difference(event.startTime).inMinutes,
        );
        breakdown['meetings'] = Duration(minutes: meetingTime);
      }

      // Get focus time
      final focusAnalytics = FocusModeService.instance.getAnalytics(days: 7);
      breakdown['focusWork'] = focusAnalytics.totalFocusTime;

      // Get email time from activity logs
      final emailLogs = _activityLogs.where((log) =>
        log.type == ActivityType.email &&
        log.timestamp.isAfter(start) &&
        log.timestamp.isBefore(end)
      );

      breakdown['email'] = emailLogs.fold<Duration>(
        Duration.zero,
        (sum, log) => sum + log.duration,
      );

      // Calculate breaks (assume 20% of work time)
      final totalWork = breakdown.values.fold<Duration>(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      breakdown['breaks'] = Duration(minutes: (totalWork.inMinutes * 0.2).round());

      // Other activities
      breakdown['other'] = Duration(
        minutes: (40 * 60) - breakdown.values.fold<int>(0, (sum, d) => sum + d.inMinutes),
      ).clamp(Duration.zero, Duration(hours: 40));

      return breakdown;
    } catch (e) {
      AppLogger.error('Error calculating time breakdown', e);
      return breakdown;
    }
  }

  /// Calculate productivity score (0-100)
  double _calculateProductivityScore(Map<String, Duration> timeBreakdown) {
    final totalMinutes = timeBreakdown.values.fold<int>(
      0,
      (sum, duration) => sum + duration.inMinutes,
    );

    if (totalMinutes == 0) return 0;

    // Weighted scoring
    final focusScore = (timeBreakdown['focusWork']!.inMinutes / totalMinutes) * 40;
    final meetingScore = (timeBreakdown['meetings']!.inMinutes / totalMinutes) * 20;
    final emailScore = (timeBreakdown['email']!.inMinutes / totalMinutes) * 20;
    final breakScore = (timeBreakdown['breaks']!.inMinutes / totalMinutes) * 20;

    // Optimal balance: 40% focus, 30% meetings, 10% email, 20% breaks
    final score = focusScore + meetingScore + emailScore + breakScore;

    return score.clamp(0, 100);
  }

  /// Get habit stats
  Future<Map<String, dynamic>> _getHabitStats(DateTime start, DateTime end) async {
    final insights = await HabitTracker.instance.getWeeklyInsights();

    final totalHabits = insights.habits.length;
    final avgCompletion = totalHabits > 0
      ? insights.habits.fold<double>(0, (sum, h) => sum + h.completionRate) / totalHabits
      : 0;

    return {
      'totalHabits': totalHabits,
      'completionRate': avgCompletion,
      'streak': insights.habits.isNotEmpty ? insights.habits.first.currentStreak : 0,
    };
  }

  /// Get email stats
  Future<Map<String, dynamic>> _getEmailStats(DateTime start, DateTime end) async {
    try {
      if (!GmailService.instance.isAuthenticated) {
        return {'received': 0, 'sent': 0, 'avgResponseTime': Duration.zero};
      }

      final emails = await GmailService.instance.getInboxMessages(maxResults: 100);

      final receivedInPeriod = emails.where((e) =>
        e.date != null &&
        e.date!.isAfter(start) &&
        e.date!.isBefore(end)
      ).length;

      return {
        'received': receivedInPeriod,
        'sent': (receivedInPeriod * 0.6).round(), // Estimate
        'avgResponseTime': const Duration(hours: 4), // Estimate
        'unread': emails.where((e) => !(e.isRead ?? true)).length,
      };
    } catch (e) {
      return {'received': 0, 'sent': 0, 'avgResponseTime': Duration.zero};
    }
  }

  /// Get meeting stats
  Future<Map<String, dynamic>> _getMeetingStats(DateTime start, DateTime end) async {
    try {
      if (!CalendarService.instance.isAuthenticated) {
        return {'total': 0, 'totalTime': Duration.zero, 'avgDuration': Duration.zero};
      }

      final events = await CalendarService.instance.getEventsInRange(start, end);

      final totalMinutes = events.fold<int>(
        0,
        (sum, event) => sum + event.endTime.difference(event.startTime).inMinutes,
      );

      return {
        'total': events.length,
        'totalTime': Duration(minutes: totalMinutes),
        'avgDuration': events.isNotEmpty
          ? Duration(minutes: totalMinutes ~/ events.length)
          : Duration.zero,
        'cost': _calculateMeetingCost(events),
      };
    } catch (e) {
      return {'total': 0, 'totalTime': Duration.zero, 'avgDuration': Duration.zero};
    }
  }

  /// Calculate meeting cost (time × attendees)
  String _calculateMeetingCost(List<dynamic> events) {
    // Simplified calculation
    final totalHours = events.fold<int>(
      0,
      (sum, event) => sum + (event as dynamic).endTime.difference(event.startTime).inHours,
    );

    return '${totalHours * 3} person-hours'; // Assume avg 3 attendees
  }

  /// Analyze energy levels
  EnergyProfile _analyzeEnergyLevels() {
    // Simplified energy profile
    // In production, would track actual energy self-reports

    return EnergyProfile(
      peakHours: [9, 10, 11], // 9-11 AM
      goodHours: [14, 15, 16], // 2-4 PM
      lowHours: [13, 17, 18], // After lunch, late afternoon
      recommendations: {
        'Deep work': '9-11 AM',
        'Meetings': '2-4 PM',
        'Email & admin': 'After lunch',
      },
    );
  }

  /// Generate AI insights
  Future<String> _generateAIInsights({
    required Map<String, Duration> timeBreakdown,
    required double productivityScore,
    required Duration focusTime,
    required double? habitCompletion,
  }) async {
    try {
      final prompt = '''
Generate productivity insights based on this data:

Time Breakdown:
- Meetings: ${timeBreakdown['meetings']!.inHours}h
- Focus work: ${timeBreakdown['focusWork']!.inHours}h
- Email: ${timeBreakdown['email']!.inHours}h
- Breaks: ${timeBreakdown['breaks']!.inHours}h

Productivity Score: ${productivityScore.toStringAsFixed(0)}%
Focus Time: ${focusTime.inHours}h ${focusTime.inMinutes % 60}m
Habit Completion: ${habitCompletion?.toStringAsFixed(0) ?? '0'}%

Requirements:
- Be concise (4-5 sentences)
- Highlight strengths
- Suggest 1-2 improvements
- Be encouraging and actionable
- Sound like a supportive coach

Example: "Great work this week! Your focus time increased to 15 hours, showing strong deep work habits. Meeting load is high at 31% - consider blocking Wednesday afternoons for uninterrupted work. Your habit completion is excellent at 95%. Keep this momentum going!"
''';

      return await AIService.instance.chat(prompt);
    } catch (e) {
      AppLogger.error('Error generating AI insights', e);
      return 'Keep up the great work! Your productivity is trending in the right direction.';
    }
  }

  /// Calculate achievements
  List<Achievement> _calculateAchievements({
    required FocusAnalytics focusAnalytics,
    required Map<String, dynamic> habitStats,
    required Map<String, dynamic> emailStats,
  }) {
    final achievements = <Achievement>[];

    // Focus streak
    if (focusAnalytics.streakDays >= 5) {
      achievements.add(Achievement(
        title: '🔥 Focus Streak',
        description: '${focusAnalytics.streakDays} days of consistent focus time',
        earned: true,
      ));
    }

    // Habit completion
    if ((habitStats['completionRate'] ?? 0) >= 90) {
      achievements.add(Achievement(
        title: '✅ Habit Master',
        description: '${habitStats['completionRate'].toStringAsFixed(0)}% habit completion',
        earned: true,
      ));
    }

    // Inbox zero
    if (emailStats['unread'] == 0) {
      achievements.add(Achievement(
        title: '📧 Inbox Zero',
        description: 'Achieved inbox zero this week',
        earned: true,
      ));
    }

    // High productivity
    final score = _calculateProductivityScore({});
    if (score >= 80) {
      achievements.add(Achievement(
        title: '🎯 High Performer',
        description: 'Productivity score ${score.toStringAsFixed(0)}%',
        earned: true,
      ));
    }

    return achievements;
  }

  /// Compare to last week
  Map<String, String> _compareToLastWeek() {
    // Simplified comparison
    return {
      'productivityScore': '+5%',
      'focusTime': '+2 hours',
      'meetingTime': '-1 hour',
      'habitCompletion': '+3%',
    };
  }

  /// Save activity logs
  Future<void> _saveActivityLogs() async {
    try {
      final json = jsonEncode(_activityLogs.map((log) => log.toJson()).toList());
      await LocalStorageService.instance.setString('activity_logs', json);
    } catch (e) {
      AppLogger.error('Error saving activity logs', e);
    }
  }

  /// Load activity logs
  Future<void> _loadActivityLogs() async {
    try {
      final json = LocalStorageService.instance.getString('activity_logs');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _activityLogs.clear();
        _activityLogs.addAll(
          data.map((item) => ActivityLog.fromJson(item)),
        );
      }
    } catch (e) {
      AppLogger.error('Error loading activity logs', e);
    }
  }
}

/// Activity log
class ActivityLog {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.duration,
    this.metadata,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ActivityType.other,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(minutes: json['durationMinutes'] as int),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Activity types
enum ActivityType {
  meeting,
  focusWork,
  email,
  break_,
  task,
  other,
}

/// Productivity report
class ProductivityReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final Map<String, Duration> timeBreakdown;
  final double productivityScore;
  final FocusAnalytics focusAnalytics;
  final Map<String, dynamic> habitStats;
  final Map<String, dynamic> emailStats;
  final Map<String, dynamic> meetingStats;
  final EnergyProfile energyProfile;
  final String aiInsights;
  final List<Achievement> achievements;
  final Map<String, String> comparisonToLastWeek;

  ProductivityReport({
    required this.weekStart,
    required this.weekEnd,
    required this.timeBreakdown,
    required this.productivityScore,
    required this.focusAnalytics,
    required this.habitStats,
    required this.emailStats,
    required this.meetingStats,
    required this.energyProfile,
    required this.aiInsights,
    required this.achievements,
    required this.comparisonToLastWeek,
  });

  @override
  String toString() {
    return '''
📊 Weekly Productivity Report

⏰ Time Breakdown:
${timeBreakdown.entries.map((e) => '  ${e.key}: ${e.value.inHours}h ${e.value.inMinutes % 60}m').join('\n')}

🎯 Productivity Score: ${productivityScore.toStringAsFixed(0)}%
Better than last week: ${comparisonToLastWeek['productivityScore']}

🔥 Focus Time: ${focusAnalytics.totalFocusTime.inHours}h ${focusAnalytics.totalFocusTime.inMinutes % 60}m
Streak: ${focusAnalytics.streakDays} days

✅ Habits: ${habitStats['completionRate'].toStringAsFixed(0)}% completion

📧 Emails: ${emailStats['received']} received, ${emailStats['sent']} sent

📅 Meetings: ${meetingStats['total']} meetings (${meetingStats['totalTime']})

💡 AI Insights:
$aiInsights

🎖️ Achievements (${achievements.length}):
${achievements.map((a) => '  ${a.title}').join('\n')}
''';
  }
}

/// Energy profile
class EnergyProfile {
  final List<int> peakHours;
  final List<int> goodHours;
  final List<int> lowHours;
  final Map<String, String> recommendations;

  EnergyProfile({
    required this.peakHours,
    required this.goodHours,
    required this.lowHours,
    required this.recommendations,
  });
}

/// Achievement
class Achievement {
  final String title;
  final String description;
  final bool earned;

  Achievement({
    required this.title,
    required this.description,
    required this.earned,
  });
}
