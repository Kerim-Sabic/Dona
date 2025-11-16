/// AI Router Models - Model selection and tier management

/// AI Model identifiers
enum AiModel {
  light, // Fast, cheaper model for simple tasks
  standard, // Standard model for most tasks
  premium, // Most capable model for complex tasks
}

extension AiModelExtension on AiModel {
  String get name {
    switch (this) {
      case AiModel.light:
        return 'light';
      case AiModel.standard:
        return 'standard';
      case AiModel.premium:
        return 'premium';
    }
  }

  String get displayName {
    switch (this) {
      case AiModel.light:
        return 'Fast Model';
      case AiModel.standard:
        return 'Standard Model';
      case AiModel.premium:
        return 'Premium Model';
    }
  }

  /// Estimated cost multiplier (relative to light = 1.0)
  double get costMultiplier {
    switch (this) {
      case AiModel.light:
        return 1.0;
      case AiModel.standard:
        return 2.0;
      case AiModel.premium:
        return 5.0;
    }
  }

  /// Max context length
  int get maxContextLength {
    switch (this) {
      case AiModel.light:
        return 4000;
      case AiModel.standard:
        return 8000;
      case AiModel.premium:
        return 16000;
    }
  }
}

/// App subscription mode
enum AppMode {
  free, // Free tier with limitations
  premiumTrial, // Premium trial period
  premium, // Full premium access
}

extension AppModeExtension on AppMode {
  String get name {
    switch (this) {
      case AppMode.free:
        return 'free';
      case AppMode.premiumTrial:
        return 'premium_trial';
      case AppMode.premium:
        return 'premium';
    }
  }

  String get displayName {
    switch (this) {
      case AppMode.free:
        return 'Free';
      case AppMode.premiumTrial:
        return 'Premium Trial';
      case AppMode.premium:
        return 'Premium';
    }
  }

  bool get isPremium {
    return this == AppMode.premium || this == AppMode.premiumTrial;
  }
}

/// Usage context for AI routing decisions
enum AiUsageContext {
  chat, // General conversation
  planning, // Autopilot planning
  studyHelp, // Study assistance
  summarization, // Document summarization
  flashcardGeneration, // Flashcard creation
  quizGeneration, // Quiz creation
  emailDrafting, // Email composition
  proactiveSuggestion, // Proactive suggestions
}

/// AI Request
class AiRequest {
  final String prompt;
  final AiUsageContext context;
  final List<Map<String, String>>? conversationHistory;
  final Map<String, dynamic>? metadata;

  const AiRequest({
    required this.prompt,
    required this.context,
    this.conversationHistory,
    this.metadata,
  });

  /// Estimate token count (rough approximation)
  int get estimatedTokens {
    var total = prompt.length ~/ 4; // ~4 chars per token

    if (conversationHistory != null) {
      for (final msg in conversationHistory!) {
        total += (msg['content']?.length ?? 0) ~/ 4;
      }
    }

    return total;
  }
}

/// AI Response
class AiResponse {
  final String content;
  final AiModel modelUsed;
  final int tokensUsed;
  final Duration responseTime;
  final Map<String, dynamic>? metadata;

  const AiResponse({
    required this.content,
    required this.modelUsed,
    this.tokensUsed = 0,
    required this.responseTime,
    this.metadata,
  });
}

/// Tier limits configuration
class TierLimits {
  final AppMode mode;
  final int maxDailyRequests;
  final int maxContextLength;
  final bool allowPremiumModels;
  final bool allowProactive;
  final bool allowAutopilot;
  final int maxAutopilotPerDay;

  const TierLimits({
    required this.mode,
    required this.maxDailyRequests,
    required this.maxContextLength,
    required this.allowPremiumModels,
    required this.allowProactive,
    required this.allowAutopilot,
    required this.maxAutopilotPerDay,
  });

  factory TierLimits.forMode(AppMode mode) {
    switch (mode) {
      case AppMode.free:
        return const TierLimits(
          mode: AppMode.free,
          maxDailyRequests: 50,
          maxContextLength: 4000,
          allowPremiumModels: false,
          allowProactive: false,
          allowAutopilot: true,
          maxAutopilotPerDay: 2,
        );

      case AppMode.premiumTrial:
        return const TierLimits(
          mode: AppMode.premiumTrial,
          maxDailyRequests: 200,
          maxContextLength: 8000,
          allowPremiumModels: true,
          allowProactive: true,
          allowAutopilot: true,
          maxAutopilotPerDay: 10,
        );

      case AppMode.premium:
        return const TierLimits(
          mode: AppMode.premium,
          maxDailyRequests: 1000,
          maxContextLength: 16000,
          allowPremiumModels: true,
          allowProactive: true,
          allowAutopilot: true,
          maxAutopilotPerDay: 50,
        );
    }
  }

  bool get hasLimits {
    return !mode.isPremium;
  }
}

/// Usage statistics for tracking
class UsageStats {
  final DateTime date;
  final int totalRequests;
  final int autopilotUsed;
  final Map<AiModel, int> requestsByModel;
  final int estimatedCost; // In cents

  const UsageStats({
    required this.date,
    required this.totalRequests,
    required this.autopilotUsed,
    required this.requestsByModel,
    required this.estimatedCost,
  });

  UsageStats copyWith({
    DateTime? date,
    int? totalRequests,
    int? autopilotUsed,
    Map<AiModel, int>? requestsByModel,
    int? estimatedCost,
  }) {
    return UsageStats(
      date: date ?? this.date,
      totalRequests: totalRequests ?? this.totalRequests,
      autopilotUsed: autopilotUsed ?? this.autopilotUsed,
      requestsByModel: requestsByModel ?? this.requestsByModel,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalRequests': totalRequests,
      'autopilotUsed': autopilotUsed,
      'requestsByModel': requestsByModel.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'estimatedCost': estimatedCost,
    };
  }

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      date: DateTime.parse(json['date'] as String),
      totalRequests: json['totalRequests'] as int,
      autopilotUsed: json['autopilotUsed'] as int,
      requestsByModel: (json['requestsByModel'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          AiModel.values.firstWhere((m) => m.name == k),
          v as int,
        ),
      ),
      estimatedCost: json['estimatedCost'] as int,
    );
  }
}
