import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/utils/logger.dart';
import '../../assistant/ai_router/ai_router.dart';
import '../../domain/autopilot/history/autopilot_history_service.dart';
import '../../core/config/feature_tiers.dart';

/// Feedback Type
enum FeedbackType {
  bug,
  feature,
  general,
}

/// Feedback Service
///
/// Generates sanitized feedback snapshots for bug reports and feature requests.
/// Respects privacy constraints - NO personal data, messages, or email content.
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  static FeedbackService get instance => _instance;

  FeedbackService._internal();

  /// Create a feedback snapshot with sanitized diagnostic data
  Future<String> createFeedbackSnapshot({
    required FeedbackType type,
    required String title,
    required String description,
    String? email,
  }) async {
    try {
      final snapshot = <String, dynamic>{};

      // Basic info
      snapshot['feedback_type'] = type.name;
      snapshot['title'] = title;
      snapshot['description'] = description;
      snapshot['timestamp'] = DateTime.now().toIso8601String();

      if (email != null && email.isNotEmpty) {
        snapshot['contact_email'] = email;
      }

      // App info
      final packageInfo = await PackageInfo.fromPlatform();
      snapshot['app'] = {
        'name': packageInfo.appName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      };

      // Platform info
      snapshot['platform'] = {
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'locale': Platform.localeName,
      };

      // App mode (Free/Premium/Trial)
      final currentMode = AiRouter.instance.currentMode;
      snapshot['app_mode'] = currentMode.name;

      // Usage statistics (high-level, non-identifying)
      final usageStats = await _getUsageStatistics();
      snapshot['usage_stats'] = usageStats;

      // Sanitized logs (last 30 entries, PII stripped)
      final sanitizedLogs = _getSanitizedLogs();
      snapshot['logs'] = sanitizedLogs;

      // Convert to formatted JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(snapshot);

      // Add text header for readability
      final header = '''
===========================================
DONA FEEDBACK REPORT
===========================================
Type: ${type.name.toUpperCase()}
Date: ${DateTime.now().toString()}
===========================================

''';

      return header + jsonString;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create feedback snapshot', e, stackTrace);
      rethrow;
    }
  }

  /// Get high-level usage statistics (no personal data)
  Future<Map<String, dynamic>> _getUsageStatistics() async {
    try {
      final history = AutopilotHistoryService.instance.getAllHistory();

      // Overall stats
      final stats = AutopilotHistoryService.instance.getStatistics();

      return {
        'total_autopilots_run': history.length,
        'successful_executions': stats['successfulExecutions'] ?? 0,
        'failed_executions': stats['failedExecutions'] ?? 0,
        'partial_executions': stats['partialExecutions'] ?? 0,
        'success_rate': ((stats['successRate'] ?? 0) * 100).toStringAsFixed(1) + '%',
        'autopilot_types_used': _getAutopilotTypeCounts(history),
      };
    } catch (e) {
      return {'error': 'Failed to collect usage stats'};
    }
  }

  /// Get counts of each autopilot type used
  Map<String, int> _getAutopilotTypeCounts(List<dynamic> history) {
    final counts = <String, int>{};

    for (final entry in history) {
      if (entry.type != null) {
        final typeName = entry.type.name;
        counts[typeName] = (counts[typeName] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Get sanitized logs (last 30 entries, PII stripped)
  List<Map<String, String>> _getSanitizedLogs() {
    try {
      final recentLogs = AppLogger.getRecentLogs(limit: 30);

      return recentLogs.map((log) {
        return {
          'timestamp': log.timestamp.toIso8601String(),
          'level': log.level.name,
          'message': _sanitizeMessage(log.message),
          // Note: stack traces are excluded for privacy
        };
      }).toList();
    } catch (e) {
      return [
        {
          'error': 'Failed to retrieve logs',
          'timestamp': DateTime.now().toIso8601String(),
        }
      ];
    }
  }

  /// Sanitize log message to remove PII
  String _sanitizeMessage(String message) {
    // Remove email addresses
    var sanitized = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL_REDACTED]',
    );

    // Remove phone numbers
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE_REDACTED]',
    );

    // Remove potential file paths with user names
    sanitized = sanitized.replaceAll(
      RegExp(r'/Users/[^/\s]+'),
      '/Users/[USER]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'C:\\Users\\[^\\\s]+'),
      'C:\\Users\\[USER]',
    );

    // Remove potential API keys or tokens (long alphanumeric strings)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9]{32,}\b'),
      '[TOKEN_REDACTED]',
    );

    // Remove potential names (capitalized words that might be names)
    // This is conservative - only redact if it looks like a full name pattern
    sanitized = sanitized.replaceAll(
      RegExp(r'\b([A-Z][a-z]+ [A-Z][a-z]+)\b'),
      '[NAME_REDACTED]',
    );

    return sanitized;
  }

  /// Export feedback to JSON file (for advanced users)
  Future<String> exportToJson(String snapshot) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'dona_feedback_$timestamp.json';

      // In a real app, you would save to a file
      // For now, just return the snapshot
      return snapshot;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export feedback', e, stackTrace);
      rethrow;
    }
  }
}
