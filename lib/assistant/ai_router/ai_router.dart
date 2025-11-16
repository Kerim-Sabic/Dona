import 'dart:convert';
import 'ai_models.dart';
import '../../core/utils/logger.dart';
import '../../services/ai/ai_service.dart';
import '../../services/storage/local_storage_service.dart';

/// AI Router - Intelligent model selection and tier management
///
/// Routes AI requests to appropriate models based on:
/// - User's subscription tier (free/premium)
/// - Request context (chat, planning, etc.)
/// - Usage limits
class AiRouter {
  static final AiRouter _instance = AiRouter._internal();
  static AiRouter get instance => _instance;

  AiRouter._internal();

  static const String _modeKey = 'app_mode';
  static const String _usageKey = 'usage_stats';

  AppMode _currentMode = AppMode.free;
  UsageStats? _todayStats;

  Future<void> init() async {
    try {
      // Load saved mode
      final modeStr = LocalStorageService.instance.getString(_modeKey);
      if (modeStr != null) {
        _currentMode = AppMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => AppMode.free,
        );
      }

      // Load today's usage stats
      await _loadTodayStats();

      AppLogger.info('AiRouter initialized: Mode=${_currentMode.displayName}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AiRouter', e, stackTrace);
    }
  }

  /// Send AI request with automatic routing
  Future<AiResponse> send(
    AiRequest request, {
    AppMode? overrideMode,
  }) async {
    final mode = overrideMode ?? _currentMode;
    final limits = TierLimits.forMode(mode);

    // Check limits
    if (limits.hasLimits) {
      final canProceed = await _checkLimits(request, limits);
      if (!canProceed) {
        throw AiRouterException('Daily limit reached. Upgrade to Premium for unlimited access.');
      }
    }

    // Select model based on context and mode
    final model = _selectModel(request.context, mode, limits);

    AppLogger.debug('Routing ${request.context} to ${model.displayName}');

    // Execute request
    final startTime = DateTime.now();

    try {
      // For now, all models use the same underlying service
      // In future, different models could use different API endpoints
      final response = await _executeRequest(request, model);

      final responseTime = DateTime.now().difference(startTime);

      // Track usage
      await _trackUsage(model, request);

      return AiResponse(
        content: response,
        modelUsed: model,
        tokensUsed: request.estimatedTokens,
        responseTime: responseTime,
      );
    } catch (e, stackTrace) {
      AppLogger.error('AI request failed', e, stackTrace);
      rethrow;
    }
  }

  /// Select appropriate model based on context and tier
  AiModel _selectModel(
    AiUsageContext context,
    AppMode mode,
    TierLimits limits,
  ) {
    // Premium users can use premium models
    if (limits.allowPremiumModels) {
      // Complex tasks get premium model
      if (context == AiUsageContext.planning ||
          context == AiUsageContext.quizGeneration ||
          context == AiUsageContext.summarization) {
        return AiModel.premium;
      }

      // Most tasks get standard model
      return AiModel.standard;
    }

    // Free users
    // Study help and chat get standard model
    if (context == AiUsageContext.studyHelp ||
        context == AiUsageContext.chat) {
      return AiModel.standard;
    }

    // Everything else gets light model
    return AiModel.light;
  }

  /// Execute request with selected model
  Future<String> _executeRequest(AiRequest request, AiModel model) async {
    // For now, all models use the same AI service
    // In future, different models could map to different API endpoints

    final response = await AIService.instance.chat(
      request.prompt,
      context: request.conversationHistory,
    );

    return response;
  }

  /// Check if request is within limits
  Future<bool> _checkLimits(AiRequest request, TierLimits limits) async {
    final stats = _todayStats;
    if (stats == null) return true;

    // Check daily request limit
    if (stats.totalRequests >= limits.maxDailyRequests) {
      AppLogger.warning('Daily request limit reached: ${stats.totalRequests}/${limits.maxDailyRequests}');
      return false;
    }

    // Check context length
    if (request.estimatedTokens > limits.maxContextLength) {
      AppLogger.warning('Context too long: ${request.estimatedTokens}/${limits.maxContextLength} tokens');
      return false;
    }

    return true;
  }

  /// Track usage for statistics
  Future<void> _trackUsage(AiModel model, AiRequest request) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Load or create today's stats
    var stats = _todayStats;
    if (stats == null || !_isSameDay(stats.date, today)) {
      stats = UsageStats(
        date: today,
        totalRequests: 0,
        autopilotUsed: 0,
        requestsByModel: {},
        estimatedCost: 0,
      );
    }

    // Update stats
    final requestsByModel = Map<AiModel, int>.from(stats.requestsByModel);
    requestsByModel[model] = (requestsByModel[model] ?? 0) + 1;

    // Estimate cost (in cents)
    final tokenCost = (request.estimatedTokens / 1000) * model.costMultiplier;
    final estimatedCost = stats.estimatedCost + tokenCost.toInt();

    final isAutopilot = request.context == AiUsageContext.planning;

    stats = stats.copyWith(
      totalRequests: stats.totalRequests + 1,
      autopilotUsed: stats.autopilotUsed + (isAutopilot ? 1 : 0),
      requestsByModel: requestsByModel,
      estimatedCost: estimatedCost,
    );

    _todayStats = stats;

    // Persist
    await _saveStats(stats);
  }

  /// Get current app mode
  AppMode get currentMode => _currentMode;

  /// Set app mode (for testing/manual upgrade)
  Future<void> setMode(AppMode mode) async {
    _currentMode = mode;
    await LocalStorageService.instance.setString(_modeKey, mode.name);
    AppLogger.info('App mode changed to: ${mode.displayName}');
  }

  /// Get tier limits for current mode
  TierLimits get currentLimits => TierLimits.forMode(_currentMode);

  /// Get today's usage stats
  UsageStats? get todayStats => _todayStats;

  /// Get remaining requests for today
  int get remainingRequests {
    final limits = currentLimits;
    final stats = _todayStats;

    if (!limits.hasLimits) return -1; // Unlimited

    if (stats == null) return limits.maxDailyRequests;

    return (limits.maxDailyRequests - stats.totalRequests).clamp(0, limits.maxDailyRequests);
  }

  /// Check if feature is available in current tier
  bool isFeatureAvailable(String feature) {
    final limits = currentLimits;

    switch (feature) {
      case 'premium_models':
        return limits.allowPremiumModels;
      case 'proactive':
        return limits.allowProactive;
      case 'autopilot':
        return limits.allowAutopilot;
      default:
        return true;
    }
  }

  /// Load today's usage stats
  Future<void> _loadTodayStats() async {
    try {
      final json = LocalStorageService.instance.getString(_usageKey);
      if (json == null) return;

      final data = jsonDecode(json) as Map<String, dynamic>;
      final stats = UsageStats.fromJson(data);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Only use if it's today's stats
      if (_isSameDay(stats.date, today)) {
        _todayStats = stats;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load usage stats', e, stackTrace);
    }
  }

  /// Save usage stats
  Future<void> _saveStats(UsageStats stats) async {
    try {
      final json = jsonEncode(stats.toJson());
      await LocalStorageService.instance.setString(_usageKey, json);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save usage stats', e, stackTrace);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// AI Router Exception
class AiRouterException implements Exception {
  final String message;

  AiRouterException(this.message);

  @override
  String toString() => message;
}
