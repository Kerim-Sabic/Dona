import '../../assistant/ai_router/ai_models.dart';

/// Feature Tiers Configuration
///
/// Defines which features are available at each subscription tier.
/// Client-side only (no billing integration yet).

enum FeatureTier {
  free,
  premium,
}

class FeatureTiers {
  /// Check if a feature is available in the given mode
  static bool isFeatureAvailable(String featureName, AppMode mode) {
    final tier = _featureTiers[featureName] ?? FeatureTier.premium;

    switch (mode) {
      case AppMode.free:
        return tier == FeatureTier.free;
      case AppMode.premiumTrial:
      case AppMode.premium:
        return true; // All features available in premium
    }
  }

  /// Get feature tier
  static FeatureTier getFeatureTier(String featureName) {
    return _featureTiers[featureName] ?? FeatureTier.premium;
  }

  /// Get daily limit for a feature
  static int? getDailyLimit(String featureName, AppMode mode) {
    return _dailyLimits[mode]?[featureName];
  }

  /// Check if feature is limited (has daily cap)
  static bool isLimited(String featureName, AppMode mode) {
    return _dailyLimits[mode]?[featureName] != null;
  }

  /// Feature tier mapping
  static final Map<String, FeatureTier> _featureTiers = {
    // Free Features
    'plan_my_day': FeatureTier.free,
    'study_autopilot': FeatureTier.free,
    'command_center': FeatureTier.free,
    'command_palette_basic': FeatureTier.free,
    'tasks': FeatureTier.free,
    'calendar': FeatureTier.free,
    'courses': FeatureTier.free,
    'chat_basic': FeatureTier.free,

    // Premium Features
    'weekly_review': FeatureTier.premium,
    'focus_mode': FeatureTier.premium,
    'triage': FeatureTier.premium,
    'relationship': FeatureTier.premium,
    'autopilot_history': FeatureTier.premium,
    'advanced_analytics': FeatureTier.premium,
    'priority_support': FeatureTier.premium,
    'extended_ai_context': FeatureTier.premium,
  };

  /// Daily limits per mode
  static final Map<AppMode, Map<String, int>> _dailyLimits = {
    AppMode.free: {
      'plan_my_day': 1,
      'study_autopilot': 2,
      'total_autopilots': 3,
      'ai_requests': 50,
    },
    AppMode.premiumTrial: {
      'total_autopilots': 10,
      'ai_requests': 200,
    },
    AppMode.premium: {
      'total_autopilots': 50,
      'ai_requests': 1000,
    },
  };
}

/// Feature descriptions for upgrade prompts
class FeatureDescriptions {
  static const Map<String, String> descriptions = {
    'weekly_review': 'Review your week and plan ahead with Weekly Review Autopilot',
    'focus_mode': 'Create structured deep work sessions with Pomodoro breaks',
    'triage': 'Organize your inbox and tasks efficiently',
    'relationship': 'Never forget to stay in touch with important people',
    'autopilot_history': 'Track and analyze all your autopilot runs',
    'advanced_analytics': 'Get deeper insights into your productivity',
    'priority_support': 'Get help when you need it most',
    'extended_ai_context': 'More context for better AI responses',
  };

  static String getDescription(String featureName) {
    return descriptions[featureName] ?? 'Premium feature';
  }
}

/// Feature usage tracking
class FeatureUsageTracker {
  static final FeatureUsageTracker _instance = FeatureUsageTracker._internal();
  static FeatureUsageTracker get instance => _instance;

  FeatureUsageTracker._internal();

  final Map<String, Map<String, int>> _dailyUsage = {}; // Date -> Feature -> Count

  /// Record feature usage
  void recordUsage(String featureName) {
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    _dailyUsage[today] ??= {};
    _dailyUsage[today]![featureName] = (_dailyUsage[today]![featureName] ?? 0) + 1;

    // Clean up old entries (keep last 7 days)
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final cutoffStr = cutoff.toIso8601String().split('T')[0];

    _dailyUsage.removeWhere((date, _) => date.compareTo(cutoffStr) < 0);
  }

  /// Get usage count for feature today
  int getTodayUsage(String featureName) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _dailyUsage[today]?[featureName] ?? 0;
  }

  /// Check if under limit
  bool isUnderLimit(String featureName, AppMode mode) {
    final limit = FeatureTiers.getDailyLimit(featureName, mode);
    if (limit == null) return true; // No limit

    return getTodayUsage(featureName) < limit;
  }

  /// Get remaining uses
  int getRemainingUses(String featureName, AppMode mode) {
    final limit = FeatureTiers.getDailyLimit(featureName, mode);
    if (limit == null) return -1; // Unlimited

    final used = getTodayUsage(featureName);
    return (limit - used).clamp(0, limit);
  }

  /// Reset usage (for testing)
  void reset() {
    _dailyUsage.clear();
  }
}
