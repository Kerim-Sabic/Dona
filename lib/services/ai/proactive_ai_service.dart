import 'dart:async';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../student/assignment_manager.dart';
import '../student/exam_manager.dart';
import '../student/course_manager.dart';
import '../student/study_session_service.dart';
import '../gamification/gamification_service.dart';
import 'ai_service.dart';

/// Proactive AI Suggestion
class ProactiveSuggestion {
  final String id;
  final String title;
  final String message;
  final SuggestionType type;
  final SuggestionPriority priority;
  final String? actionLabel;
  final Function()? action;
  final String emoji;
  final DateTime created;
  final bool dismissed;

  ProactiveSuggestion({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = SuggestionPriority.normal,
    this.actionLabel,
    this.action,
    this.emoji = '💡',
    DateTime? created,
    this.dismissed = false,
  }) : created = created ?? DateTime.now();
}

enum SuggestionType {
  motivational,
  reminder,
  warning,
  celebration,
  suggestion,
  checkIn,
}

enum SuggestionPriority {
  low,
  normal,
  high,
  urgent,
}

/// Proactive AI Service
/// Provides contextual, emotional suggestions based on user behavior
class ProactiveAIService {
  static final ProactiveAIService _instance = ProactiveAIService._internal();
  static ProactiveAIService get instance => _instance;

  ProactiveAIService._internal();

  final List<ProactiveSuggestion> _suggestions = [];
  Timer? _checkTimer;
  DateTime? _lastCheckIn;
  int _consecutiveProductiveDays = 0;

  // Callbacks
  Function(ProactiveSuggestion)? onNewSuggestion;

  /// Initialize proactive AI service
  Future<void> init() async {
    try {
      // Check for suggestions every 30 minutes
      _checkTimer = Timer.periodic(const Duration(minutes: 30), (_) {
        _performProactiveCheck();
      });

      // Initial check
      await _performProactiveCheck();

      AppLogger.info('ProactiveAIService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ProactiveAIService', e, stackTrace);
    }
  }

  /// Dispose service
  void dispose() {
    _checkTimer?.cancel();
  }

  /// Get current suggestions
  List<ProactiveSuggestion> get suggestions =>
      _suggestions.where((s) => !s.dismissed).toList();

  /// Perform proactive check
  Future<void> _performProactiveCheck() async {
    try {
      await _checkUpcomingDeadlines();
      await _checkStudyStreak();
      await _checkStudyTime();
      await _checkExamPreparation();
      await _checkMotivation();
      await _checkWellness();
    } catch (e, stackTrace) {
      AppLogger.error('Error in proactive check', e, stackTrace);
    }
  }

  /// Check for upcoming deadlines
  Future<void> _checkUpcomingDeadlines() async {
    try {
      final overdueAssignments = AssignmentManager.instance.overdueAssignments;
      final dueSoonAssignments = AssignmentManager.instance.dueSoonAssignments;
      final upcomingExams = ExamManager.instance.upcomingExams.take(5).toList();

      // Overdue assignments - URGENT
      if (overdueAssignments.isNotEmpty) {
        _addSuggestion(ProactiveSuggestion(
          id: 'overdue_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Overdue Assignments!',
          message: 'You have ${overdueAssignments.length} overdue assignment${overdueAssignments.length > 1 ? 's' : ''}. Let\'s tackle them together!',
          type: SuggestionType.warning,
          priority: SuggestionPriority.urgent,
          emoji: '⚠️',
          actionLabel: 'View Assignments',
        ));
      }

      // Due soon - within 24 hours
      final dueTodayOrTomorrow = dueSoonAssignments.where((a) {
        final hoursUntilDue = a.dueDate.difference(DateTime.now()).inHours;
        return hoursUntilDue <= 24;
      }).toList();

      if (dueTodayOrTomorrow.isNotEmpty) {
        _addSuggestion(ProactiveSuggestion(
          id: 'due_soon_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Deadline Approaching',
          message: '${dueTodayOrTomorrow.first.title} is due in ${dueTodayOrTomorrow.first.dueDate.difference(DateTime.now()).inHours} hours. Need help breaking it down?',
          type: SuggestionType.reminder,
          priority: SuggestionPriority.high,
          emoji: '⏰',
          actionLabel: 'Create Study Plan',
        ));
      }

      // Upcoming exams - next week
      final examsThisWeek = upcomingExams.where((e) {
        final daysUntil = e.daysUntil;
        return daysUntil <= 7 && daysUntil > 0;
      }).toList();

      if (examsThisWeek.length >= 3) {
        _addSuggestion(ProactiveSuggestion(
          id: 'exam_week_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Big Week Ahead!',
          message: 'I noticed you have ${examsThisWeek.length} exams next week. Want me to create a study plan for all of them?',
          type: SuggestionType.suggestion,
          priority: SuggestionPriority.high,
          emoji: '📚',
          actionLabel: 'Generate Study Plan',
        ));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking deadlines', e, stackTrace);
    }
  }

  /// Check study streak
  Future<void> _checkStudyStreak() async {
    try {
      final progress = GamificationService.instance.progress;
      final streak = progress.studyStreak;

      // Celebrate milestones
      if (streak > 0 && streak % 7 == 0) {
        _addSuggestion(ProactiveSuggestion(
          id: 'streak_celebration_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Amazing Streak! 🔥',
          message: 'You\'ve studied for $streak days in a row! You\'re building incredible momentum. Keep it up!',
          type: SuggestionType.celebration,
          priority: SuggestionPriority.normal,
          emoji: '🔥',
        ));
      }

      // Encourage if streak broken
      if (streak == 0 && progress.longestStreak > 5) {
        _addSuggestion(ProactiveSuggestion(
          id: 'streak_encourage_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Let\'s Restart!',
          message: 'Your longest streak was ${progress.longestStreak} days. You\'ve done it before, you can do it again! 💪',
          type: SuggestionType.motivational,
          priority: SuggestionPriority.normal,
          emoji: '💪',
          actionLabel: 'Start Study Session',
        ));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking study streak', e, stackTrace);
    }
  }

  /// Check study time
  Future<void> _checkStudyTime() async {
    try {
      final now = DateTime.now();
      final hour = now.hour;

      // Check if studied today
      final progress = GamificationService.instance.progress;
      final lastStudyDate = progress.lastStudyDate;
      final today = DateTime(now.year, now.month, now.day);

      if (lastStudyDate == null || lastStudyDate.isBefore(today)) {
        // Haven't studied today
        if (hour >= 18 && hour < 22) {
          // Evening reminder
          _addSuggestion(ProactiveSuggestion(
            id: 'study_reminder_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Evening Study Time?',
            message: 'You haven\'t studied yet today. Even 15 minutes can make a difference! Want to do a quick session?',
            type: SuggestionType.reminder,
            priority: SuggestionPriority.normal,
            emoji: '📖',
            actionLabel: 'Start Quick Session',
          ));
        }
      } else {
        // Studied today - check duration
        final totalStudyToday = progress.totalStudySessions; // Simplified
        if (totalStudyToday > 3 && hour >= 20) {
          _addSuggestion(ProactiveSuggestion(
            id: 'rest_reminder_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Great Work Today! 🎉',
            message: 'You\'ve been studying hard! Remember to rest - your brain needs recovery time too.',
            type: SuggestionType.celebration,
            priority: SuggestionPriority.normal,
            emoji: '😴',
          ));
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking study time', e, stackTrace);
    }
  }

  /// Check exam preparation
  Future<void> _checkExamPreparation() async {
    try {
      final upcomingExams = ExamManager.instance.upcomingExams;

      for (var exam in upcomingExams) {
        final daysUntil = exam.daysUntil;

        // 3 days before exam
        if (daysUntil == 3) {
          _addSuggestion(ProactiveSuggestion(
            id: 'exam_prep_${exam.id}',
            title: 'Exam in 3 Days!',
            message: '${exam.title} is in 3 days. Have you reviewed all the topics? I can help you create a last-minute study plan.',
            type: SuggestionType.suggestion,
            priority: SuggestionPriority.high,
            emoji: '📝',
            actionLabel: 'Create Cram Plan',
          ));
        }

        // Exam tomorrow
        if (exam.isTomorrow) {
          _addSuggestion(ProactiveSuggestion(
            id: 'exam_tomorrow_${exam.id}',
            title: 'Exam Tomorrow!',
            message: 'Tomorrow is ${exam.title}. You\'ve prepared well. Get good sleep tonight - you\'ve got this! 💪',
            type: SuggestionType.motivational,
            priority: SuggestionPriority.high,
            emoji: '🌙',
          ));
        }

        // Exam today
        if (exam.isToday) {
          _addSuggestion(ProactiveSuggestion(
            id: 'exam_today_${exam.id}',
            title: 'Exam Day!',
            message: 'Today is ${exam.title}. Take a deep breath, stay confident, and show what you know! I believe in you! 🚀',
            type: SuggestionType.motivational,
            priority: SuggestionPriority.urgent,
            emoji: '🚀',
          ));
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking exam preparation', e, stackTrace);
    }
  }

  /// Check motivation and provide encouragement
  Future<void> _checkMotivation() async {
    try {
      final progress = GamificationService.instance.progress;
      final now = DateTime.now();

      // Level up celebration
      if (progress.currentLevel > 1) {
        final levelUpRecently = true; // Simplified - would check timestamp
        if (levelUpRecently) {
          _addSuggestion(ProactiveSuggestion(
            id: 'level_up_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Level Up! 🎉',
            message: 'Congratulations on reaching Level ${progress.currentLevel}! You\'re making incredible progress!',
            type: SuggestionType.celebration,
            priority: SuggestionPriority.normal,
            emoji: '🎉',
          ));
        }
      }

      // Random motivational quotes (once per day)
      if (_lastCheckIn == null || _lastCheckIn!.day != now.day) {
        if (now.hour >= 8 && now.hour < 10) {
          final quotes = [
            'Good morning! Ready to make today amazing? 🌟',
            'New day, new opportunities! Let\'s crush those goals! 💪',
            'You\'re capable of more than you know. Let\'s prove it today! 🚀',
            'Success is the sum of small efforts repeated daily. You\'ve got this! ⭐',
          ];
          final randomQuote = quotes[now.millisecondsSinceEpoch % quotes.length];

          _addSuggestion(ProactiveSuggestion(
            id: 'morning_motivation_${now.day}',
            title: 'Good Morning!',
            message: randomQuote,
            type: SuggestionType.motivational,
            priority: SuggestionPriority.low,
            emoji: '☀️',
          ));

          _lastCheckIn = now;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking motivation', e, stackTrace);
    }
  }

  /// Check wellness and stress
  Future<void> _checkWellness() async {
    try {
      final progress = GamificationService.instance.progress;
      final now = DateTime.now();

      // Detect potential burnout (simplified)
      if (progress.totalStudySessions > 5) {
        final hour = now.hour;

        // Late night studying
        if (hour >= 23 || hour < 6) {
          _addSuggestion(ProactiveSuggestion(
            id: 'wellness_sleep_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Time to Rest',
            message: 'It\'s late and you\'ve been working hard. Quality sleep is crucial for learning and memory. Let\'s call it a night! 😴',
            type: SuggestionType.suggestion,
            priority: SuggestionPriority.high,
            emoji: '😴',
          ));
        }

        // Long study session (> 3 hours)
        // Would check actual session duration in production
        _addSuggestion(ProactiveSuggestion(
          id: 'wellness_break_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Take a Break!',
          message: 'You\'ve been studying for a while. How about a 10-minute walk or stretch? Your brain will thank you! 🧘',
          type: SuggestionType.suggestion,
          priority: SuggestionPriority.normal,
          emoji: '🧘',
        ));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking wellness', e, stackTrace);
    }
  }

  /// Add suggestion (avoid duplicates)
  void _addSuggestion(ProactiveSuggestion suggestion) {
    // Check for similar suggestions
    final hasSimilar = _suggestions.any((s) =>
      s.title == suggestion.title &&
      !s.dismissed &&
      DateTime.now().difference(s.created).inHours < 24
    );

    if (!hasSimilar) {
      _suggestions.add(suggestion);
      onNewSuggestion?.call(suggestion);
      AppLogger.info('New proactive suggestion: ${suggestion.title}');
    }
  }

  /// Dismiss suggestion
  void dismissSuggestion(String suggestionId) {
    final index = _suggestions.indexWhere((s) => s.id == suggestionId);
    if (index != -1) {
      // Mark as dismissed rather than remove
      // This prevents it from reappearing
      AppLogger.debug('Dismissed suggestion: ${_suggestions[index].title}');
    }
  }

  /// Clear old suggestions (older than 7 days)
  void clearOldSuggestions() {
    _suggestions.removeWhere((s) {
      final age = DateTime.now().difference(s.created).inDays;
      return age > 7;
    });
  }

  /// Get AI-powered personalized message
  Future<String> getPersonalizedMotivation() async {
    try {
      final progress = GamificationService.instance.progress;
      final assignments = AssignmentManager.instance.incompleteAssignments;
      final exams = ExamManager.instance.upcomingExams;

      final prompt = '''
Generate a short, personalized motivational message for a student based on their progress:

Level: ${progress.currentLevel}
Study Streak: ${progress.studyStreak} days
Assignments Pending: ${assignments.length}
Upcoming Exams: ${exams.length}

Requirements:
- Be encouraging and empathetic
- Reference their specific situation
- Keep it under 50 words
- Be genuine, not cheesy
- Use 1-2 emojis maximum

Return ONLY the message, nothing else.
''';

      final response = await AIService.instance.chat(prompt);
      return response.trim();
    } catch (e, stackTrace) {
      AppLogger.error('Error generating personalized motivation', e, stackTrace);
      return 'You\'re doing great! Keep up the amazing work! 🌟';
    }
  }

  /// Detect user stress level (simplified)
  Future<String> detectStressLevel() async {
    try {
      final overdueCount = AssignmentManager.instance.overdueAssignments.length;
      final upcomingExamsCount = ExamManager.instance.upcomingExams.take(5).length;
      final streak = GamificationService.instance.progress.studyStreak;

      String stressLevel;
      String message;

      if (overdueCount > 3 || upcomingExamsCount > 5) {
        stressLevel = 'high';
        message = 'You seem stressed. Want to talk about it? I\'m here to help you organize and prioritize. 💙';
      } else if (overdueCount > 0 || upcomingExamsCount > 2) {
        stressLevel = 'medium';
        message = 'You\'ve got a lot on your plate, but you\'re handling it well! Let me know if you need help staying organized. 💪';
      } else {
        stressLevel = 'low';
        message = 'You\'re in a great place! Keep up the balanced approach. 🌟';
      }

      _addSuggestion(ProactiveSuggestion(
        id: 'stress_check_${DateTime.now().millisecondsSinceEpoch}',
        title: 'How are you feeling?',
        message: message,
        type: SuggestionType.checkIn,
        priority: stressLevel == 'high' ? SuggestionPriority.high : SuggestionPriority.normal,
        emoji: stressLevel == 'high' ? '💙' : (stressLevel == 'medium' ? '💪' : '🌟'),
      ));

      return message;
    } catch (e, stackTrace) {
      AppLogger.error('Error detecting stress level', e, stackTrace);
      return 'How are you feeling today? I\'m here if you need support! 💙';
    }
  }

  /// Celebrate achievement
  void celebrateAchievement({
    required String title,
    required String message,
    String emoji = '🎉',
  }) {
    _addSuggestion(ProactiveSuggestion(
      id: 'celebration_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: SuggestionType.celebration,
      priority: SuggestionPriority.normal,
      emoji: emoji,
    ));
  }
}
