import 'dart:convert';
import 'dart:math';
import '../../core/utils/logger.dart';
import '../../data/models/gamification/achievement.dart';
import '../storage/local_storage_service.dart';

/// Gamification Service
/// Manages XP, levels, achievements, streaks, and weekly challenges
class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  static GamificationService get instance => _instance;

  GamificationService._internal();

  UserProgress _progress = UserProgress();
  List<Achievement> _achievements = [];
  List<WeeklyChallenge> _weeklyChallenges = [];

  // Callbacks for UI updates
  Function(int xpGained, String reason)? onXPGained;
  Function(int newLevel)? onLevelUp;
  Function(Achievement)? onAchievementUnlocked;
  Function(int newStreak)? onStreakUpdated;

  /// Initialize gamification service
  Future<void> init() async {
    try {
      await _loadProgress();
      await _loadAchievements();
      await _loadWeeklyChallenges();
      await _initializeDefaultAchievements();
      await _checkAndUpdateStreak();
      await _checkWeeklyChallenges();

      AppLogger.info('GamificationService initialized - Level ${_progress.currentLevel}, ${_progress.totalXP} XP');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize GamificationService', e, stackTrace);
    }
  }

  /// Get current user progress
  UserProgress get progress => _progress;

  /// Get all achievements
  List<Achievement> get allAchievements => List.unmodifiable(_achievements);

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  /// Get locked achievements
  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  /// Get achievements in progress
  List<Achievement> get inProgressAchievements =>
      _achievements.where((a) => a.isInProgress).toList();

  /// Get current weekly challenges
  List<WeeklyChallenge> get activeWeeklyChallenges =>
      _weeklyChallenges.where((c) => c.isActive).toList();

  /// Add XP with reason
  Future<void> addXP(int amount, String reason) async {
    if (amount <= 0) return;

    try {
      final oldLevel = _progress.currentLevel;
      final newTotalXP = _progress.totalXP + amount;
      int newCurrentLevelXP = _progress.currentLevelXP + amount;
      int newLevel = _progress.currentLevel;
      int xpForNextLevel = _progress.xpForNextLevel;

      // Check for level up
      while (newCurrentLevelXP >= xpForNextLevel) {
        newCurrentLevelXP -= xpForNextLevel;
        newLevel++;
        xpForNextLevel = _calculateXPForLevel(newLevel + 1);

        // Notify level up
        onLevelUp?.call(newLevel);
        AppLogger.info('🎉 Level up! Now level $newLevel');

        // Award level up bonus XP
        if (newLevel % 10 == 0) {
          // Every 10 levels, bonus XP
          amount += 500;
        }
      }

      _progress = _progress.copyWith(
        totalXP: newTotalXP,
        currentLevel: newLevel,
        currentLevelXP: newCurrentLevelXP,
        xpForNextLevel: xpForNextLevel,
      );

      await _saveProgress();

      // Notify XP gain
      onXPGained?.call(amount, reason);
      AppLogger.info('Gained $amount XP: $reason');

      // Check for XP-based achievements
      await _checkAchievements();
    } catch (e, stackTrace) {
      AppLogger.error('Error adding XP', e, stackTrace);
    }
  }

  /// Calculate XP required for a specific level
  int _calculateXPForLevel(int level) {
    // Formula: base * level^1.5
    // Level 2: 100 XP
    // Level 10: 316 XP
    // Level 50: 3535 XP
    // Level 100: 10000 XP
    const base = 100;
    return (base * pow(level, 1.5)).round();
  }

  /// Update study streak
  Future<void> updateStudyStreak() async {
    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (_progress.lastStudyDate == null) {
        // First study session ever
        _progress = _progress.copyWith(
          studyStreak: 1,
          lastStudyDate: todayDate,
          longestStreak: 1,
        );
        await addXP(50, 'Started your study streak! 🔥');
      } else {
        final lastStudy = DateTime(
          _progress.lastStudyDate!.year,
          _progress.lastStudyDate!.month,
          _progress.lastStudyDate!.day,
        );

        final daysDifference = todayDate.difference(lastStudy).inDays;

        if (daysDifference == 0) {
          // Already studied today, no change
          return;
        } else if (daysDifference == 1) {
          // Consecutive day - increase streak
          final newStreak = _progress.studyStreak + 1;
          final newLongestStreak = max(_progress.longestStreak, newStreak);

          _progress = _progress.copyWith(
            studyStreak: newStreak,
            lastStudyDate: todayDate,
            longestStreak: newLongestStreak,
          );

          // Award XP for streak
          final streakXP = min(newStreak * 10, 500); // Cap at 500 XP
          await addXP(streakXP, '🔥 $newStreak day streak!');

          onStreakUpdated?.call(newStreak);

          // Check for streak achievements
          await _checkStreakAchievements(newStreak);
        } else {
          // Streak broken
          final oldStreak = _progress.studyStreak;
          _progress = _progress.copyWith(
            studyStreak: 1,
            lastStudyDate: todayDate,
          );

          if (oldStreak > 3) {
            AppLogger.info('Streak broken! Was at $oldStreak days. Starting fresh!');
          }
        }
      }

      await _saveProgress();
    } catch (e, stackTrace) {
      AppLogger.error('Error updating study streak', e, stackTrace);
    }
  }

  /// Record study session completion
  Future<void> recordStudySession({
    required Duration duration,
    required int productivityScore,
  }) async {
    try {
      _progress = _progress.copyWith(
        totalStudySessions: _progress.totalStudySessions + 1,
      );

      await updateStudyStreak();

      // Award XP based on duration and productivity
      final durationXP = min((duration.inMinutes / 5).round(), 200);
      final productivityBonus = (productivityScore / 100 * 50).round();
      await addXP(durationXP + productivityBonus, 'Completed study session');

      await _saveProgress();
      await _checkAchievements();
    } catch (e, stackTrace) {
      AppLogger.error('Error recording study session', e, stackTrace);
    }
  }

  /// Record assignment completion
  Future<void> recordAssignmentCompleted({double? grade}) async {
    try {
      _progress = _progress.copyWith(
        totalAssignmentsCompleted: _progress.totalAssignmentsCompleted + 1,
      );

      // Base XP for completion
      int xp = 100;

      // Bonus for good grades
      if (grade != null) {
        if (grade >= 90) {
          xp += 100; // A grade bonus
        } else if (grade >= 80) {
          xp += 50; // B grade bonus
        }
      }

      await addXP(xp, 'Completed assignment');
      await _saveProgress();
      await _checkAchievements();
    } catch (e, stackTrace) {
      AppLogger.error('Error recording assignment completion', e, stackTrace);
    }
  }

  /// Record flashcards reviewed
  Future<void> recordFlashcardsReviewed(int count) async {
    try {
      _progress = _progress.copyWith(
        totalFlashcardsReviewed: _progress.totalFlashcardsReviewed + count,
      );

      await addXP(count * 5, 'Reviewed $count flashcards');
      await _saveProgress();
      await _checkAchievements();
    } catch (e, stackTrace) {
      AppLogger.error('Error recording flashcards', e, stackTrace);
    }
  }

  /// Record quiz taken
  Future<void> recordQuizTaken({required int score, required int totalQuestions}) async {
    try {
      _progress = _progress.copyWith(
        totalQuizzesTaken: _progress.totalQuizzesTaken + 1,
      );

      final percentage = (score / totalQuestions) * 100;
      final xp = (percentage * 2).round(); // Max 200 XP for perfect score

      await addXP(xp, 'Completed quiz - ${percentage.round()}%');
      await _saveProgress();
      await _checkAchievements();
    } catch (e, stackTrace) {
      AppLogger.error('Error recording quiz', e, stackTrace);
    }
  }

  /// Check and unlock achievements
  Future<void> _checkAchievements() async {
    for (var achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;
      int currentValue = 0;

      switch (achievement.id) {
        // Level achievements
        case 'level_5':
          currentValue = _progress.currentLevel;
          shouldUnlock = currentValue >= 5;
          break;
        case 'level_10':
          currentValue = _progress.currentLevel;
          shouldUnlock = currentValue >= 10;
          break;
        case 'level_25':
          currentValue = _progress.currentLevel;
          shouldUnlock = currentValue >= 25;
          break;
        case 'level_50':
          currentValue = _progress.currentLevel;
          shouldUnlock = currentValue >= 50;
          break;
        case 'level_100':
          currentValue = _progress.currentLevel;
          shouldUnlock = currentValue >= 100;
          break;

        // Study session achievements
        case 'first_study':
          currentValue = _progress.totalStudySessions;
          shouldUnlock = currentValue >= 1;
          break;
        case 'study_10':
          currentValue = _progress.totalStudySessions;
          shouldUnlock = currentValue >= 10;
          break;
        case 'study_50':
          currentValue = _progress.totalStudySessions;
          shouldUnlock = currentValue >= 50;
          break;
        case 'study_100':
          currentValue = _progress.totalStudySessions;
          shouldUnlock = currentValue >= 100;
          break;

        // Assignment achievements
        case 'first_assignment':
          currentValue = _progress.totalAssignmentsCompleted;
          shouldUnlock = currentValue >= 1;
          break;
        case 'assignment_10':
          currentValue = _progress.totalAssignmentsCompleted;
          shouldUnlock = currentValue >= 10;
          break;
        case 'assignment_50':
          currentValue = _progress.totalAssignmentsCompleted;
          shouldUnlock = currentValue >= 50;
          break;

        // Flashcard achievements
        case 'flashcard_100':
          currentValue = _progress.totalFlashcardsReviewed;
          shouldUnlock = currentValue >= 100;
          break;
        case 'flashcard_500':
          currentValue = _progress.totalFlashcardsReviewed;
          shouldUnlock = currentValue >= 500;
          break;
        case 'flashcard_1000':
          currentValue = _progress.totalFlashcardsReviewed;
          shouldUnlock = currentValue >= 1000;
          break;
      }

      if (shouldUnlock) {
        await _unlockAchievement(achievement.id);
      } else {
        // Update progress
        final progress = currentValue / achievement.targetValue;
        await _updateAchievementProgress(achievement.id, currentValue, progress);
      }
    }
  }

  /// Check streak-specific achievements
  Future<void> _checkStreakAchievements(int streak) async {
    final streakAchievements = {
      'streak_3': 3,
      'streak_7': 7,
      'streak_14': 14,
      'streak_30': 30,
      'streak_100': 100,
    };

    for (var entry in streakAchievements.entries) {
      if (streak >= entry.value) {
        await _unlockAchievement(entry.key);
      }
    }
  }

  /// Unlock achievement
  Future<void> _unlockAchievement(String achievementId) async {
    try {
      final index = _achievements.indexWhere((a) => a.id == achievementId);
      if (index == -1) return;

      final achievement = _achievements[index];
      if (achievement.isUnlocked) return;

      final unlockedAchievement = achievement.copyWith(
        unlockedAt: DateTime.now(),
        progress: 1.0,
      );

      _achievements[index] = unlockedAchievement;
      await _saveAchievements();

      // Award XP
      final xp = achievement.xpReward * achievement.rarity.xpMultiplier;
      await addXP(xp, 'Unlocked: ${achievement.title}');

      // Notify
      onAchievementUnlocked?.call(unlockedAchievement);
      AppLogger.info('🏆 Unlocked achievement: ${achievement.title}');
    } catch (e, stackTrace) {
      AppLogger.error('Error unlocking achievement', e, stackTrace);
    }
  }

  /// Update achievement progress
  Future<void> _updateAchievementProgress(String achievementId, int currentValue, double progress) async {
    try {
      final index = _achievements.indexWhere((a) => a.id == achievementId);
      if (index == -1) return;

      _achievements[index] = _achievements[index].copyWith(
        currentValue: currentValue,
        progress: progress.clamp(0.0, 1.0),
      );

      await _saveAchievements();
    } catch (e, stackTrace) {
      AppLogger.error('Error updating achievement progress', e, stackTrace);
    }
  }

  /// Check and update streak
  Future<void> _checkAndUpdateStreak() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_progress.lastStudyDate != null) {
      final lastStudy = DateTime(
        _progress.lastStudyDate!.year,
        _progress.lastStudyDate!.month,
        _progress.lastStudyDate!.day,
      );

      final daysDifference = todayDate.difference(lastStudy).inDays;

      if (daysDifference > 1) {
        // Streak broken silently on app start
        _progress = _progress.copyWith(studyStreak: 0);
        await _saveProgress();
      }
    }
  }

  /// Check and update weekly challenges
  Future<void> _checkWeeklyChallenges() async {
    final now = DateTime.now();

    // Remove expired challenges
    _weeklyChallenges.removeWhere((c) => c.endDate.isBefore(now));

    // Generate new weekly challenges if needed
    if (_weeklyChallenges.isEmpty) {
      await _generateWeeklyChallenges();
    }

    await _saveWeeklyChallenges();
  }

  /// Generate weekly challenges
  Future<void> _generateWeeklyChallenges() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    _weeklyChallenges = [
      WeeklyChallenge(
        id: 'week_study_${now.millisecondsSinceEpoch}',
        title: 'Study Marathon',
        description: 'Complete 5 study sessions this week',
        icon: '📚',
        targetValue: 5,
        xpReward: 500,
        startDate: weekStart,
        endDate: weekEnd,
        type: ChallengeType.study,
      ),
      WeeklyChallenge(
        id: 'week_flashcards_${now.millisecondsSinceEpoch}',
        title: 'Flashcard Master',
        description: 'Review 100 flashcards this week',
        icon: '🎴',
        targetValue: 100,
        xpReward: 300,
        startDate: weekStart,
        endDate: weekEnd,
        type: ChallengeType.study,
      ),
      WeeklyChallenge(
        id: 'week_assignments_${now.millisecondsSinceEpoch}',
        title: 'Assignment Crusher',
        description: 'Complete 3 assignments this week',
        icon: '✅',
        targetValue: 3,
        xpReward: 400,
        startDate: weekStart,
        endDate: weekEnd,
        type: ChallengeType.academic,
      ),
    ];

    await _saveWeeklyChallenges();
  }

  /// Initialize default achievements
  Future<void> _initializeDefaultAchievements() async {
    if (_achievements.isNotEmpty) return; // Already initialized

    _achievements = [
      // Level achievements
      Achievement(
        id: 'level_5',
        title: 'Rising Star',
        description: 'Reach level 5',
        icon: '⭐',
        category: AchievementCategory.general,
        rarity: AchievementRarity.common,
        xpReward: 100,
        targetValue: 5,
      ),
      Achievement(
        id: 'level_10',
        title: 'Dedicated Student',
        description: 'Reach level 10',
        icon: '🌟',
        category: AchievementCategory.general,
        rarity: AchievementRarity.uncommon,
        xpReward: 200,
        targetValue: 10,
      ),
      Achievement(
        id: 'level_25',
        title: 'Scholar',
        description: 'Reach level 25',
        icon: '💫',
        category: AchievementCategory.general,
        rarity: AchievementRarity.rare,
        xpReward: 500,
        targetValue: 25,
      ),
      Achievement(
        id: 'level_50',
        title: 'Master Student',
        description: 'Reach level 50',
        icon: '✨',
        category: AchievementCategory.general,
        rarity: AchievementRarity.epic,
        xpReward: 1000,
        targetValue: 50,
      ),
      Achievement(
        id: 'level_100',
        title: 'Legend',
        description: 'Reach level 100',
        icon: '👑',
        category: AchievementCategory.general,
        rarity: AchievementRarity.legendary,
        xpReward: 5000,
        targetValue: 100,
      ),

      // Streak achievements
      Achievement(
        id: 'streak_3',
        title: 'Getting Started',
        description: 'Study for 3 days in a row',
        icon: '🔥',
        category: AchievementCategory.study,
        rarity: AchievementRarity.common,
        xpReward: 50,
        targetValue: 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'One Week Warrior',
        description: 'Study for 7 days in a row',
        icon: '🔥🔥',
        category: AchievementCategory.study,
        rarity: AchievementRarity.uncommon,
        xpReward: 150,
        targetValue: 7,
      ),
      Achievement(
        id: 'streak_14',
        title: 'Two Week Champion',
        description: 'Study for 14 days in a row',
        icon: '🔥🔥🔥',
        category: AchievementCategory.study,
        rarity: AchievementRarity.rare,
        xpReward: 300,
        targetValue: 14,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Monthly Master',
        description: 'Study for 30 days in a row',
        icon: '🔥🔥🔥🔥',
        category: AchievementCategory.study,
        rarity: AchievementRarity.epic,
        xpReward: 1000,
        targetValue: 30,
      ),
      Achievement(
        id: 'streak_100',
        title: 'Unstoppable',
        description: 'Study for 100 days in a row',
        icon: '🔥🔥🔥🔥🔥',
        category: AchievementCategory.study,
        rarity: AchievementRarity.legendary,
        xpReward: 5000,
        targetValue: 100,
      ),

      // Study session achievements
      Achievement(
        id: 'first_study',
        title: 'First Steps',
        description: 'Complete your first study session',
        icon: '👶',
        category: AchievementCategory.study,
        rarity: AchievementRarity.common,
        xpReward: 50,
        targetValue: 1,
      ),
      Achievement(
        id: 'study_10',
        title: 'Study Enthusiast',
        description: 'Complete 10 study sessions',
        icon: '📖',
        category: AchievementCategory.study,
        rarity: AchievementRarity.uncommon,
        xpReward: 100,
        targetValue: 10,
      ),
      Achievement(
        id: 'study_50',
        title: 'Study Expert',
        description: 'Complete 50 study sessions',
        icon: '📚',
        category: AchievementCategory.study,
        rarity: AchievementRarity.rare,
        xpReward: 300,
        targetValue: 50,
      ),
      Achievement(
        id: 'study_100',
        title: 'Study Master',
        description: 'Complete 100 study sessions',
        icon: '🎓',
        category: AchievementCategory.study,
        rarity: AchievementRarity.epic,
        xpReward: 500,
        targetValue: 100,
      ),

      // Assignment achievements
      Achievement(
        id: 'first_assignment',
        title: 'Task Tackler',
        description: 'Complete your first assignment',
        icon: '✅',
        category: AchievementCategory.academic,
        rarity: AchievementRarity.common,
        xpReward: 50,
        targetValue: 1,
      ),
      Achievement(
        id: 'assignment_10',
        title: 'Assignment Pro',
        description: 'Complete 10 assignments',
        icon: '✔️',
        category: AchievementCategory.academic,
        rarity: AchievementRarity.uncommon,
        xpReward: 150,
        targetValue: 10,
      ),
      Achievement(
        id: 'assignment_50',
        title: 'Assignment Master',
        description: 'Complete 50 assignments',
        icon: '💯',
        category: AchievementCategory.academic,
        rarity: AchievementRarity.rare,
        xpReward: 500,
        targetValue: 50,
      ),

      // Flashcard achievements
      Achievement(
        id: 'flashcard_100',
        title: 'Memory Builder',
        description: 'Review 100 flashcards',
        icon: '🧠',
        category: AchievementCategory.study,
        rarity: AchievementRarity.uncommon,
        xpReward: 100,
        targetValue: 100,
      ),
      Achievement(
        id: 'flashcard_500',
        title: 'Knowledge Collector',
        description: 'Review 500 flashcards',
        icon: '🎴',
        category: AchievementCategory.study,
        rarity: AchievementRarity.rare,
        xpReward: 300,
        targetValue: 500,
      ),
      Achievement(
        id: 'flashcard_1000',
        title: 'Flashcard Champion',
        description: 'Review 1000 flashcards',
        icon: '👑',
        category: AchievementCategory.study,
        rarity: AchievementRarity.epic,
        xpReward: 1000,
        targetValue: 1000,
      ),
    ];

    await _saveAchievements();
  }

  /// Save progress
  Future<void> _saveProgress() async {
    try {
      final json = jsonEncode(_progress.toJson());
      await LocalStorageService.instance.setString('user_progress', json);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving progress', e, stackTrace);
    }
  }

  /// Load progress
  Future<void> _loadProgress() async {
    try {
      final json = LocalStorageService.instance.getString('user_progress');
      if (json != null) {
        _progress = UserProgress.fromJson(jsonDecode(json));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading progress', e, stackTrace);
    }
  }

  /// Save achievements
  Future<void> _saveAchievements() async {
    try {
      final json = jsonEncode(_achievements.map((a) => a.toJson()).toList());
      await LocalStorageService.instance.setString('achievements', json);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving achievements', e, stackTrace);
    }
  }

  /// Load achievements
  Future<void> _loadAchievements() async {
    try {
      final json = LocalStorageService.instance.getString('achievements');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _achievements = data.map((item) => Achievement.fromJson(item)).toList();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading achievements', e, stackTrace);
    }
  }

  /// Save weekly challenges
  Future<void> _saveWeeklyChallenges() async {
    try {
      final json = jsonEncode(_weeklyChallenges.map((c) => c.toJson()).toList());
      await LocalStorageService.instance.setString('weekly_challenges', json);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving weekly challenges', e, stackTrace);
    }
  }

  /// Load weekly challenges
  Future<void> _loadWeeklyChallenges() async {
    try {
      final json = LocalStorageService.instance.getString('weekly_challenges');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _weeklyChallenges = data.map((item) => WeeklyChallenge.fromJson(item)).toList();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading weekly challenges', e, stackTrace);
    }
  }
}
