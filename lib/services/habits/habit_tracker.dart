import 'dart:convert';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../ai/ai_service.dart';
import '../calendar/calendar_service.dart';
import '../../data/user_profile.dart';

/// Habit Tracking & Insights
///
/// Helps users build better habits by:
/// - Tracking daily habits
/// - Counting streaks
/// - Generating insights
/// - Suggesting optimal times based on calendar
class HabitTracker {
  static final HabitTracker _instance = HabitTracker._internal();
  static HabitTracker get instance => _instance;

  HabitTracker._internal();

  List<Habit> _habits = [];
  Map<String, List<HabitLog>> _logs = {}; // habitId -> logs

  /// Initialize service
  Future<void> init() async {
    try {
      await _loadHabits();
      await _loadLogs();
      AppLogger.info('HabitTracker initialized with ${_habits.length} habits');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize HabitTracker', e, stackTrace);
    }
  }

  /// Add a new habit
  Future<Habit> addHabit({
    required String name,
    required String description,
    HabitFrequency frequency = HabitFrequency.daily,
    int targetCount = 1,
    List<int>? preferredDays, // 1=Monday, 7=Sunday
    TimeOfDay? preferredTime,
    String? category,
  }) async {
    try {
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        frequency: frequency,
        targetCount: targetCount,
        preferredDays: preferredDays,
        preferredTime: preferredTime,
        category: category,
        createdAt: DateTime.now(),
      );

      _habits.add(habit);
      _logs[habit.id] = [];
      await _saveHabits();

      AppLogger.info('Added habit: $name');
      return habit;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding habit', e, stackTrace);
      rethrow;
    }
  }

  /// Log habit completion
  Future<HabitLog> logHabit(String habitId, {String? notes}) async {
    try {
      final habit = _habits.firstWhere((h) => h.id == habitId);
      final log = HabitLog(
        habitId: habitId,
        timestamp: DateTime.now(),
        notes: notes,
      );

      _logs[habitId] = _logs[habitId] ?? [];
      _logs[habitId]!.add(log);

      // Update streak
      await _updateStreak(habitId);
      await _saveLogs();

      AppLogger.info('Logged habit: ${habit.name}');
      return log;
    } catch (e, stackTrace) {
      AppLogger.error('Error logging habit', e, stackTrace);
      rethrow;
    }
  }

  /// Update habit streak
  Future<void> _updateStreak(String habitId) async {
    try {
      final habit = _habits.firstWhere((h) => h.id == habitId);
      final logs = _logs[habitId] ?? [];

      if (logs.isEmpty) {
        habit.currentStreak = 0;
        habit.longestStreak = 0;
        await _saveHabits();
        return;
      }

      // Sort logs by date
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Calculate current streak
      int streak = 0;
      DateTime checkDate = DateTime.now();

      for (int i = 0; i < 365; i++) {
        // Check last 365 days
        final logsOnDate = logs.where((log) =>
          log.timestamp.year == checkDate.year &&
          log.timestamp.month == checkDate.month &&
          log.timestamp.day == checkDate.day
        );

        if (logsOnDate.isEmpty) {
          break; // Streak broken
        }

        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      habit.currentStreak = streak;
      if (streak > habit.longestStreak) {
        habit.longestStreak = streak;
      }

      await _saveHabits();
      AppLogger.debug('Updated streak for ${habit.name}: $streak days');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating streak', e, stackTrace);
    }
  }

  /// Get habit by ID
  Habit? getHabit(String habitId) {
    try {
      return _habits.firstWhere((h) => h.id == habitId);
    } catch (e) {
      return null;
    }
  }

  /// Get all habits
  List<Habit> get habits => List.unmodifiable(_habits);

  /// Get habits by category
  List<Habit> getHabitsByCategory(String category) {
    return _habits.where((h) => h.category == category).toList();
  }

  /// Get today's habits
  List<Habit> getTodaysHabits() {
    final today = DateTime.now().weekday; // 1=Monday, 7=Sunday

    return _habits.where((habit) {
      if (habit.frequency == HabitFrequency.daily) {
        return true;
      }

      if (habit.frequency == HabitFrequency.weekly) {
        return habit.preferredDays?.contains(today) ?? false;
      }

      return false;
    }).toList();
  }

  /// Check if habit was completed today
  bool isCompletedToday(String habitId) {
    final logs = _logs[habitId] ?? [];
    final today = DateTime.now();

    return logs.any((log) =>
      log.timestamp.year == today.year &&
      log.timestamp.month == today.month &&
      log.timestamp.day == today.day
    );
  }

  /// Get completion rate for habit (last N days)
  double getCompletionRate(String habitId, {int days = 30}) {
    final logs = _logs[habitId] ?? [];
    if (logs.isEmpty) return 0.0;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentLogs = logs.where((log) => log.timestamp.isAfter(cutoffDate));

    return (recentLogs.length / days) * 100;
  }

  /// Generate weekly insights
  Future<WeeklyInsights> getWeeklyInsights() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final insights = <HabitInsight>[];

      for (final habit in _habits) {
        final logs = _logs[habit.id] ?? [];
        final weekLogs = logs.where((log) =>
          log.timestamp.isAfter(weekStart) && log.timestamp.isBefore(weekEnd)
        ).toList();

        final completionCount = weekLogs.length;
        final targetCount = habit.frequency == HabitFrequency.daily ? 7 : habit.targetCount;
        final completionRate = (completionCount / targetCount) * 100;

        insights.add(HabitInsight(
          habit: habit,
          completionCount: completionCount,
          targetCount: targetCount,
          completionRate: completionRate,
          currentStreak: habit.currentStreak,
        ));
      }

      // Generate AI summary
      final aiSummary = await _generateInsightsSummary(insights);

      // Get suggested times for unscheduled habits
      final suggestions = await _generateTimeSuggestions();

      return WeeklyInsights(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: insights,
        aiSummary: aiSummary,
        suggestions: suggestions,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error generating weekly insights', e, stackTrace);
      rethrow;
    }
  }

  /// Generate AI summary of habit insights
  Future<String> _generateInsightsSummary(List<HabitInsight> insights) async {
    try {
      final prompt = '''
Generate encouraging weekly habit insights based on this data:

${insights.map((i) => '- ${i.habit.name}: ${i.completionCount}/${i.targetCount} completed (${i.completionRate.toStringAsFixed(0)}%), ${i.currentStreak} day streak').join('\n')}

Requirements:
- Be encouraging and positive
- Highlight achievements
- Gently suggest areas for improvement
- Keep it concise (3-4 sentences)
- Sound like a supportive coach

Example: "Great week! You crushed your exercise goal with a 5-day streak. Your meditation practice is building momentum at 71%. Try morning workouts - you have free time at 7 AM and tend to be most energized then."
''';

      return await AIService.instance.chat(prompt);
    } catch (e) {
      AppLogger.error('Error generating AI summary', e);
      return 'Keep up the great work on your habits!';
    }
  }

  /// Generate time suggestions for habits based on calendar
  Future<List<String>> _generateTimeSuggestions() async {
    try {
      final suggestions = <String>[];

      // Get upcoming week's calendar
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));
      final events = await CalendarService.instance.getEventsInRange(now, weekEnd);

      // Find gaps in calendar
      final gaps = <TimeSlot>[];
      DateTime checkTime = now;

      while (checkTime.isBefore(weekEnd)) {
        final dayStart = DateTime(checkTime.year, checkTime.month, checkTime.day, 6);
        final dayEnd = DateTime(checkTime.year, checkTime.month, checkTime.day, 22);

        final dayEvents = events.where((e) =>
          e.startTime.day == checkTime.day
        ).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        DateTime slotStart = dayStart;
        for (final event in dayEvents) {
          if (event.startTime.difference(slotStart).inMinutes >= 30) {
            gaps.add(TimeSlot(
              start: slotStart,
              end: event.startTime,
            ));
          }
          slotStart = event.endTime;
        }

        // Check gap after last event
        if (dayEnd.difference(slotStart).inMinutes >= 30) {
          gaps.add(TimeSlot(
            start: slotStart,
            end: dayEnd,
          ));
        }

        checkTime = checkTime.add(const Duration(days: 1));
      }

      // Suggest best times for habits
      for (final habit in _habits.where((h) => h.preferredTime == null)) {
        if (gaps.isNotEmpty) {
          final bestGap = gaps.first; // Simplified - could use ML to find best time
          suggestions.add(
            '${habit.name}: Try ${_formatTime(bestGap.start)} - you have free time then'
          );
        }
      }

      return suggestions;
    } catch (e) {
      AppLogger.error('Error generating time suggestions', e);
      return [];
    }
  }

  /// Delete habit
  Future<bool> deleteHabit(String habitId) async {
    try {
      final removedCount = _habits.removeWhere((h) => h.id == habitId);
      if (removedCount > 0) {
        _logs.remove(habitId);
        await _saveHabits();
        await _saveLogs();
        AppLogger.info('Deleted habit: $habitId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting habit', e, stackTrace);
      return false;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  /// Load habits from storage
  Future<void> _loadHabits() async {
    try {
      final json = LocalStorageService.instance.getString('habits');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _habits = data.map((item) => Habit.fromJson(item)).toList();
        AppLogger.info('Loaded ${_habits.length} habits');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading habits', e, stackTrace);
    }
  }

  /// Save habits to storage
  Future<void> _saveHabits() async {
    try {
      final json = jsonEncode(_habits.map((h) => h.toJson()).toList());
      await LocalStorageService.instance.setString('habits', json);
      AppLogger.debug('Saved ${_habits.length} habits');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving habits', e, stackTrace);
    }
  }

  /// Load logs from storage
  Future<void> _loadLogs() async {
    try {
      final json = LocalStorageService.instance.getString('habit_logs');
      if (json != null) {
        final Map<String, dynamic> data = jsonDecode(json);
        _logs = data.map((key, value) =>
          MapEntry(
            key,
            (value as List<dynamic>)
              .map((item) => HabitLog.fromJson(item))
              .toList(),
          ),
        );
        AppLogger.info('Loaded habit logs');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading logs', e, stackTrace);
    }
  }

  /// Save logs to storage
  Future<void> _saveLogs() async {
    try {
      final data = _logs.map((key, value) =>
        MapEntry(key, value.map((log) => log.toJson()).toList())
      );
      final json = jsonEncode(data);
      await LocalStorageService.instance.setString('habit_logs', json);
      AppLogger.debug('Saved habit logs');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving logs', e, stackTrace);
    }
  }
}

/// Habit model
class Habit {
  final String id;
  final String name;
  final String description;
  final HabitFrequency frequency;
  final int targetCount;
  final List<int>? preferredDays;
  final TimeOfDay? preferredTime;
  final String? category;
  final DateTime createdAt;
  int currentStreak;
  int longestStreak;
  bool isActive;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    this.targetCount = 1,
    this.preferredDays,
    this.preferredTime,
    this.category,
    required this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isActive = true,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      targetCount: json['targetCount'] as int? ?? 1,
      preferredDays: (json['preferredDays'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(),
      preferredTime: json['preferredTime'] != null
        ? TimeOfDay.fromJson(json['preferredTime'])
        : null,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'frequency': frequency.toString(),
      'targetCount': targetCount,
      if (preferredDays != null) 'preferredDays': preferredDays,
      if (preferredTime != null) 'preferredTime': preferredTime!.toJson(),
      if (category != null) 'category': category,
      'createdAt': createdAt.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'isActive': isActive,
    };
  }
}

/// Habit log model
class HabitLog {
  final String habitId;
  final DateTime timestamp;
  final String? notes;

  HabitLog({
    required this.habitId,
    required this.timestamp,
    this.notes,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      habitId: json['habitId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Habit frequency
enum HabitFrequency {
  daily,
  weekly,
  monthly,
}

/// Time of day
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  @override
  String toString() {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }
}

/// Habit insight
class HabitInsight {
  final Habit habit;
  final int completionCount;
  final int targetCount;
  final double completionRate;
  final int currentStreak;

  HabitInsight({
    required this.habit,
    required this.completionCount,
    required this.targetCount,
    required this.completionRate,
    required this.currentStreak,
  });
}

/// Weekly insights
class WeeklyInsights {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<HabitInsight> habits;
  final String aiSummary;
  final List<String> suggestions;

  WeeklyInsights({
    required this.weekStart,
    required this.weekEnd,
    required this.habits,
    required this.aiSummary,
    required this.suggestions,
  });
}

/// Time slot
class TimeSlot {
  final DateTime start;
  final DateTime end;

  TimeSlot({required this.start, required this.end});
}
