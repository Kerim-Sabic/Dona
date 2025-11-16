import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'autopilot_history_entry.dart';
import '../../../core/utils/logger.dart';
import '../../../services/storage/local_storage_service.dart';

/// Autopilot History Service
///
/// Tracks and persists autopilot execution history
class AutopilotHistoryService {
  static final AutopilotHistoryService _instance = AutopilotHistoryService._internal();
  static AutopilotHistoryService get instance => _instance;

  AutopilotHistoryService._internal();

  static const String _historyKey = 'autopilot_history';
  static const int _maxHistoryEntries = 100; // Keep last 100 entries

  final _uuid = const Uuid();
  final List<AutopilotHistoryEntry> _history = [];
  bool _initialized = false;

  /// Initialize history service
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _loadHistory();
      _initialized = true;
      AppLogger.info('AutopilotHistoryService initialized with ${_history.length} entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AutopilotHistoryService', e, stackTrace);
    }
  }

  /// Record a new autopilot execution
  Future<String> recordExecution({
    required AutopilotType type,
    required String summary,
    required int totalActions,
    required int executedActions,
    required AutopilotHistoryStatus status,
    String? errorMessage,
    List<String>? createdItemIds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final entry = AutopilotHistoryEntry(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        type: type,
        summary: summary,
        totalActions: totalActions,
        executedActions: executedActions,
        status: status,
        errorMessage: errorMessage,
        createdItemIds: createdItemIds,
        metadata: metadata,
      );

      _history.insert(0, entry); // Add to beginning (most recent first)

      // Trim to max entries
      if (_history.length > _maxHistoryEntries) {
        _history.removeRange(_maxHistoryEntries, _history.length);
      }

      await _saveHistory();

      AppLogger.info('Recorded autopilot execution: ${type.displayName} (${status.displayName})');
      return entry.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to record autopilot execution', e, stackTrace);
      rethrow;
    }
  }

  /// Get all history entries
  List<AutopilotHistoryEntry> getAllHistory() {
    return List.unmodifiable(_history);
  }

  /// Get history entries by type
  List<AutopilotHistoryEntry> getHistoryByType(AutopilotType type) {
    return _history.where((entry) => entry.type == type).toList();
  }

  /// Get history entries by date range
  List<AutopilotHistoryEntry> getHistoryByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _history.where((entry) {
      if (startDate != null && entry.timestamp.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && entry.timestamp.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Get recent history (last N entries)
  List<AutopilotHistoryEntry> getRecentHistory({int limit = 10}) {
    return _history.take(limit).toList();
  }

  /// Get history statistics
  Map<String, dynamic> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final relevantEntries = getHistoryByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    if (relevantEntries.isEmpty) {
      return {
        'totalExecutions': 0,
        'successfulExecutions': 0,
        'failedExecutions': 0,
        'partialExecutions': 0,
        'cancelledExecutions': 0,
        'successRate': 0.0,
        'byType': <String, int>{},
      };
    }

    final successful = relevantEntries.where((e) => e.status == AutopilotHistoryStatus.success).length;
    final failed = relevantEntries.where((e) => e.status == AutopilotHistoryStatus.failed).length;
    final partial = relevantEntries.where((e) => e.status == AutopilotHistoryStatus.partial).length;
    final cancelled = relevantEntries.where((e) => e.status == AutopilotHistoryStatus.cancelled).length;

    final byType = <String, int>{};
    for (final entry in relevantEntries) {
      final typeName = entry.type.displayName;
      byType[typeName] = (byType[typeName] ?? 0) + 1;
    }

    return {
      'totalExecutions': relevantEntries.length,
      'successfulExecutions': successful,
      'failedExecutions': failed,
      'partialExecutions': partial,
      'cancelledExecutions': cancelled,
      'successRate': successful / relevantEntries.length,
      'byType': byType,
    };
  }

  /// Get entry by ID
  AutopilotHistoryEntry? getEntryById(String id) {
    try {
      return _history.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    try {
      _history.clear();
      await _saveHistory();
      AppLogger.info('Cleared autopilot history');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear autopilot history', e, stackTrace);
    }
  }

  /// Load history from storage
  Future<void> _loadHistory() async {
    try {
      final stored = LocalStorageService.instance.getString(_historyKey);
      if (stored == null || stored.isEmpty) {
        return;
      }

      final List<dynamic> jsonList = jsonDecode(stored);
      _history.clear();
      _history.addAll(
        jsonList.map((json) => AutopilotHistoryEntry.fromJson(json as Map<String, dynamic>))
      );

      AppLogger.debug('Loaded ${_history.length} autopilot history entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load autopilot history', e, stackTrace);
    }
  }

  /// Save history to storage
  Future<void> _saveHistory() async {
    try {
      final jsonList = _history.map((entry) => entry.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await LocalStorageService.instance.setString(_historyKey, encoded);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save autopilot history', e, stackTrace);
    }
  }
}
