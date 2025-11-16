import 'dart:convert';

/// Achievement/Badge model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int xpReward;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0
  final int targetValue;
  final int currentValue;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.rarity = AchievementRarity.common,
    this.xpReward = 100,
    this.unlockedAt,
    this.progress = 0.0,
    this.targetValue = 1,
    this.currentValue = 0,
  });

  bool get isUnlocked => unlockedAt != null;
  bool get isInProgress => currentValue > 0 && !isUnlocked;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: AchievementCategory.values.firstWhere(
        (c) => c.toString() == json['category'],
        orElse: () => AchievementCategory.general,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (r) => r.toString() == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      xpReward: json['xpReward'] as int,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      targetValue: json['targetValue'] as int? ?? 1,
      currentValue: json['currentValue'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category.toString(),
      'rarity': rarity.toString(),
      'xpReward': xpReward,
      if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
      'progress': progress,
      'targetValue': targetValue,
      'currentValue': currentValue,
    };
  }

  Achievement copyWith({
    String? title,
    String? description,
    String? icon,
    DateTime? unlockedAt,
    double? progress,
    int? currentValue,
  }) {
    return Achievement(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category,
      rarity: rarity,
      xpReward: xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

/// Achievement categories
enum AchievementCategory {
  general,
  academic,
  study,
  social,
  productivity,
  wellness,
}

/// Achievement rarity levels
enum AchievementRarity {
  common,    // Bronze
  uncommon,  // Silver
  rare,      // Gold
  epic,      // Platinum
  legendary, // Diamond
}

/// User gamification progress
class UserProgress {
  final int totalXP;
  final int currentLevel;
  final int xpForNextLevel;
  final int currentLevelXP;
  final int studyStreak;
  final DateTime? lastStudyDate;
  final int longestStreak;
  final int totalStudySessions;
  final int totalAssignmentsCompleted;
  final int totalFlashcardsReviewed;
  final int totalQuizzesTaken;
  final double averageGrade;

  UserProgress({
    this.totalXP = 0,
    this.currentLevel = 1,
    this.xpForNextLevel = 100,
    this.currentLevelXP = 0,
    this.studyStreak = 0,
    this.lastStudyDate,
    this.longestStreak = 0,
    this.totalStudySessions = 0,
    this.totalAssignmentsCompleted = 0,
    this.totalFlashcardsReviewed = 0,
    this.totalQuizzesTaken = 0,
    this.averageGrade = 0.0,
  });

  /// Calculate progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    if (xpForNextLevel == 0) return 0.0;
    return currentLevelXP / xpForNextLevel;
  }

  /// Get current rank title
  String get rankTitle {
    if (currentLevel < 5) return 'Beginner';
    if (currentLevel < 10) return 'Novice';
    if (currentLevel < 20) return 'Student';
    if (currentLevel < 30) return 'Scholar';
    if (currentLevel < 40) return 'Expert';
    if (currentLevel < 50) return 'Master';
    if (currentLevel < 75) return 'Grandmaster';
    if (currentLevel < 100) return 'Legend';
    return 'Mythic';
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalXP: json['totalXP'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      xpForNextLevel: json['xpForNextLevel'] as int? ?? 100,
      currentLevelXP: json['currentLevelXP'] as int? ?? 0,
      studyStreak: json['studyStreak'] as int? ?? 0,
      lastStudyDate: json['lastStudyDate'] != null
          ? DateTime.parse(json['lastStudyDate'] as String)
          : null,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalStudySessions: json['totalStudySessions'] as int? ?? 0,
      totalAssignmentsCompleted: json['totalAssignmentsCompleted'] as int? ?? 0,
      totalFlashcardsReviewed: json['totalFlashcardsReviewed'] as int? ?? 0,
      totalQuizzesTaken: json['totalQuizzesTaken'] as int? ?? 0,
      averageGrade: (json['averageGrade'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXP': totalXP,
      'currentLevel': currentLevel,
      'xpForNextLevel': xpForNextLevel,
      'currentLevelXP': currentLevelXP,
      'studyStreak': studyStreak,
      if (lastStudyDate != null) 'lastStudyDate': lastStudyDate!.toIso8601String(),
      'longestStreak': longestStreak,
      'totalStudySessions': totalStudySessions,
      'totalAssignmentsCompleted': totalAssignmentsCompleted,
      'totalFlashcardsReviewed': totalFlashcardsReviewed,
      'totalQuizzesTaken': totalQuizzesTaken,
      'averageGrade': averageGrade,
    };
  }

  UserProgress copyWith({
    int? totalXP,
    int? currentLevel,
    int? xpForNextLevel,
    int? currentLevelXP,
    int? studyStreak,
    DateTime? lastStudyDate,
    int? longestStreak,
    int? totalStudySessions,
    int? totalAssignmentsCompleted,
    int? totalFlashcardsReviewed,
    int? totalQuizzesTaken,
    double? averageGrade,
  }) {
    return UserProgress(
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
      currentLevelXP: currentLevelXP ?? this.currentLevelXP,
      studyStreak: studyStreak ?? this.studyStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      longestStreak: longestStreak ?? this.longestStreak,
      totalStudySessions: totalStudySessions ?? this.totalStudySessions,
      totalAssignmentsCompleted: totalAssignmentsCompleted ?? this.totalAssignmentsCompleted,
      totalFlashcardsReviewed: totalFlashcardsReviewed ?? this.totalFlashcardsReviewed,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      averageGrade: averageGrade ?? this.averageGrade,
    );
  }
}

/// Weekly challenge
class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int targetValue;
  final int currentProgress;
  final int xpReward;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeType type;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    this.currentProgress = 0,
    required this.xpReward,
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  bool get isCompleted => currentProgress >= targetValue;
  bool get isActive => DateTime.now().isBefore(endDate) && DateTime.now().isAfter(startDate);
  double get progress => currentProgress / targetValue;
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      targetValue: json['targetValue'] as int,
      currentProgress: json['currentProgress'] as int? ?? 0,
      xpReward: json['xpReward'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: ChallengeType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => ChallengeType.study,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'xpReward': xpReward,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.toString(),
    };
  }

  WeeklyChallenge copyWith({int? currentProgress}) {
    return WeeklyChallenge(
      id: id,
      title: title,
      description: description,
      icon: icon,
      targetValue: targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      xpReward: xpReward,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }
}

enum ChallengeType {
  study,
  academic,
  social,
  productivity,
}

/// Extension for achievement category display
extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.general:
        return 'General';
      case AchievementCategory.academic:
        return 'Academic';
      case AchievementCategory.study:
        return 'Study';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.productivity:
        return 'Productivity';
      case AchievementCategory.wellness:
        return 'Wellness';
    }
  }

  String get icon {
    switch (this) {
      case AchievementCategory.general:
        return '⭐';
      case AchievementCategory.academic:
        return '🎓';
      case AchievementCategory.study:
        return '📚';
      case AchievementCategory.social:
        return '👥';
      case AchievementCategory.productivity:
        return '⚡';
      case AchievementCategory.wellness:
        return '💚';
    }
  }
}

/// Extension for achievement rarity display
extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  String get color {
    switch (this) {
      case AchievementRarity.common:
        return '#808080'; // Gray
      case AchievementRarity.uncommon:
        return '#C0C0C0'; // Silver
      case AchievementRarity.rare:
        return '#FFD700'; // Gold
      case AchievementRarity.epic:
        return '#E5E4E2'; // Platinum
      case AchievementRarity.legendary:
        return '#B9F2FF'; // Diamond
    }
  }

  int get xpMultiplier {
    switch (this) {
      case AchievementRarity.common:
        return 1;
      case AchievementRarity.uncommon:
        return 2;
      case AchievementRarity.rare:
        return 3;
      case AchievementRarity.epic:
        return 5;
      case AchievementRarity.legendary:
        return 10;
    }
  }
}
