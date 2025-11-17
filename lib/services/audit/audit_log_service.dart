import 'dart:async';
import 'package:hive/hive.dart';
import '../../core/utils/logger.dart';

/// Action type enum
enum ActionType {
  create,
  update,
  delete,
  send,
  call,
  schedule,
  complete,
  other,
}

/// Audit log entry model
class AuditLogEntry {
  final String id;
  final ActionType actionType;
  final String service;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;
  final DateTime timestamp;
  final bool canUndo;
  final bool wasUndone;

  AuditLogEntry({
    required this.id,
    required this.actionType,
    required this.service,
    required this.action,
    this.entityType,
    this.entityId,
    this.previousState,
    this.newState,
    required this.timestamp,
    this.canUndo = false,
    this.wasUndone = false,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] ?? '',
      actionType: ActionType.values.firstWhere(
        (e) => e.toString() == json['actionType'],
        orElse: () => ActionType.other,
      ),
      service: json['service'] ?? '',
      action: json['action'] ?? '',
      entityType: json['entityType'],
      entityId: json['entityId'],
      previousState: json['previousState'] as Map<String, dynamic>?,
      newState: json['newState'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp']),
      canUndo: json['canUndo'] ?? false,
      wasUndone: json['wasUndone'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType.toString(),
      'service': service,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'previousState': previousState,
      'newState': newState,
      'timestamp': timestamp.toIso8601String(),
      'canUndo': canUndo,
      'wasUndone': wasUndone,
    };
  }

  AuditLogEntry copyWith({bool? wasUndone}) {
    return AuditLogEntry(
      id: id,
      actionType: actionType,
      service: service,
      action: action,
      entityType: entityType,
      entityId: entityId,
      previousState: previousState,
      newState: newState,
      timestamp: timestamp,
      canUndo: canUndo,
      wasUndone: wasUndone ?? this.wasUndone,
    );
  }
}

/// Audit Log Service
/// Tracks all actions and provides undo functionality
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  static AuditLogService get instance => _instance;

  AuditLogService._internal();

  Box? _auditBox;
  final List<AuditLogEntry> _recentLogs = [];
  static const int _maxRecentLogs = 100;

  Future<void> init() async {
    try {
      _auditBox = await Hive.openBox('audit_log');
      await _loadRecentLogs();
      AppLogger.info('AuditLogService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AuditLogService', e, stackTrace);
    }
  }

  /// Log an action
  Future<String> logAction({
    required ActionType actionType,
    required String service,
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? newState,
    bool canUndo = false,
  }) async {
    try {
      final entry = AuditLogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        actionType: actionType,
        service: service,
        action: action,
        entityType: entityType,
        entityId: entityId,
        previousState: previousState,
        newState: newState,
        timestamp: DateTime.now(),
        canUndo: canUndo,
      );

      // Add to recent logs
      _recentLogs.add(entry);
      if (_recentLogs.length > _maxRecentLogs) {
        _recentLogs.removeAt(0);
      }

      // Save to persistent storage
      await _auditBox?.put(entry.id, entry.toJson());

      AppLogger.debug('Logged action: $service.$action');
      return entry.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to log action', e, stackTrace);
      return '';
    }
  }

  /// Get recent actions
  Future<List<AuditLogEntry>> getRecentActions({int limit = 20}) async {
    try {
      if (_recentLogs.length <= limit) {
        return List.from(_recentLogs.reversed);
      }

      return _recentLogs.sublist(_recentLogs.length - limit).reversed.toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get recent actions', e, stackTrace);
      return [];
    }
  }

  /// Get actions by date range
  Future<List<AuditLogEntry>> getActionsByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final entries = <AuditLogEntry>[];

      if (_auditBox == null) return entries;

      for (var key in _auditBox!.keys) {
        final entryJson = _auditBox!.get(key);
        if (entryJson != null) {
          final entry = AuditLogEntry.fromJson(Map<String, dynamic>.from(entryJson));

          if (startDate != null && entry.timestamp.isBefore(startDate)) continue;
          if (endDate != null && entry.timestamp.isAfter(endDate)) continue;

          entries.add(entry);
        }
      }

      // Sort by timestamp (newest first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return entries;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get actions by date range', e, stackTrace);
      return [];
    }
  }

  /// Get actions by service
  Future<List<AuditLogEntry>> getActionsByService(String service) async {
    try {
      final allActions = await getRecentActions(limit: 100);
      return allActions.where((entry) => entry.service == service).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get actions by service', e, stackTrace);
      return [];
    }
  }

  /// Get undoable actions
  Future<List<AuditLogEntry>> getUndoableActions({int limit = 10}) async {
    try {
      final recentActions = await getRecentActions(limit: 50);
      return recentActions
          .where((entry) => entry.canUndo && !entry.wasUndone)
          .take(limit)
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get undoable actions', e, stackTrace);
      return [];
    }
  }

  /// Undo an action
  Future<bool> undoAction(String actionId) async {
    try {
      final entryJson = _auditBox?.get(actionId);
      if (entryJson == null) {
        AppLogger.warning('Action not found: $actionId');
        return false;
      }

      final entry = AuditLogEntry.fromJson(Map<String, dynamic>.from(entryJson));

      if (!entry.canUndo) {
        AppLogger.warning('Action cannot be undone: $actionId');
        return false;
      }

      if (entry.wasUndone) {
        AppLogger.warning('Action already undone: $actionId');
        return false;
      }

      // Mark as undone
      final updatedEntry = entry.copyWith(wasUndone: true);
      await _auditBox?.put(actionId, updatedEntry.toJson());

      // Update in recent logs
      final index = _recentLogs.indexWhere((e) => e.id == actionId);
      if (index != -1) {
        _recentLogs[index] = updatedEntry;
      }

      // Log the undo action
      await logAction(
        actionType: ActionType.other,
        service: 'audit',
        action: 'undo',
        entityType: 'action',
        entityId: actionId,
        canUndo: false,
      );

      AppLogger.info('Undid action: ${entry.service}.${entry.action}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to undo action', e, stackTrace);
      return false;
    }
  }

  /// Get audit log summary
  Future<String> getAuditSummary({int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final actions = await getActionsByDateRange(startDate: startDate);

      final buffer = StringBuffer();
      buffer.writeln('📊 Audit Log Summary (Last $days days):\n');
      buffer.writeln('Total Actions: ${actions.length}\n');

      // Count by action type
      final typeCount = <ActionType, int>{};
      for (var action in actions) {
        typeCount[action.actionType] = (typeCount[action.actionType] ?? 0) + 1;
      }

      buffer.writeln('By Type:');
      for (var entry in typeCount.entries) {
        final typeStr = entry.key.toString().split('.').last;
        buffer.writeln('  • ${typeStr.toUpperCase()}: ${entry.value}');
      }

      // Count by service
      final serviceCount = <String, int>{};
      for (var action in actions) {
        serviceCount[action.service] = (serviceCount[action.service] ?? 0) + 1;
      }

      buffer.writeln('\nBy Service:');
      final sortedServices = serviceCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedServices.take(5)) {
        buffer.writeln('  • ${entry.key}: ${entry.value}');
      }

      // Undoable actions
      final undoable = await getUndoableActions();
      buffer.writeln('\n⏪ Undoable Actions: ${undoable.length}');

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get audit summary', e, stackTrace);
      return 'Unable to generate audit summary.';
    }
  }

  /// Format audit entry for display
  String formatAuditEntry(AuditLogEntry entry) {
    final buffer = StringBuffer();

    // Action icon
    String icon;
    switch (entry.actionType) {
      case ActionType.create:
        icon = '➕';
        break;
      case ActionType.update:
        icon = '✏️';
        break;
      case ActionType.delete:
        icon = '🗑️';
        break;
      case ActionType.send:
        icon = '📤';
        break;
      case ActionType.call:
        icon = '📞';
        break;
      case ActionType.schedule:
        icon = '📅';
        break;
      case ActionType.complete:
        icon = '✅';
        break;
      default:
        icon = '📝';
    }

    buffer.write('$icon ');

    if (entry.wasUndone) {
      buffer.write('[UNDONE] ');
    }

    buffer.write('${entry.service}.${entry.action}');

    if (entry.entityType != null) {
      buffer.write(' (${entry.entityType}');
      if (entry.entityId != null) {
        buffer.write(': ${entry.entityId.substring(0, 8)}...');
      }
      buffer.write(')');
    }

    buffer.write('\n   ${_formatTimestamp(entry.timestamp)}');

    if (entry.canUndo && !entry.wasUndone) {
      buffer.write(' • Undoable');
    }

    return buffer.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Clear old logs
  Future<void> clearOldLogs({Duration age = const Duration(days: 90)}) async {
    try {
      final cutoffDate = DateTime.now().subtract(age);
      final keysToDelete = <String>[];

      if (_auditBox == null) return;

      for (var key in _auditBox!.keys) {
        final entryJson = _auditBox!.get(key);
        if (entryJson != null) {
          final entry = AuditLogEntry.fromJson(Map<String, dynamic>.from(entryJson));
          if (entry.timestamp.isBefore(cutoffDate)) {
            keysToDelete.add(key);
          }
        }
      }

      for (var key in keysToDelete) {
        await _auditBox?.delete(key);
      }

      AppLogger.info('Cleared ${keysToDelete.length} old audit log entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear old logs', e, stackTrace);
    }
  }

  /// Load recent logs from storage
  Future<void> _loadRecentLogs() async {
    try {
      if (_auditBox == null) return;

      final entries = <AuditLogEntry>[];

      for (var key in _auditBox!.keys) {
        final entryJson = _auditBox!.get(key);
        if (entryJson != null) {
          entries.add(AuditLogEntry.fromJson(Map<String, dynamic>.from(entryJson)));
        }
      }

      // Sort by timestamp and take last N entries
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (entries.length > _maxRecentLogs) {
        _recentLogs.addAll(entries.sublist(entries.length - _maxRecentLogs));
      } else {
        _recentLogs.addAll(entries);
      }

      AppLogger.info('Loaded ${_recentLogs.length} audit log entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load recent logs', e, stackTrace);
    }
  }

  /// Export audit log
  Future<String> exportAuditLog({DateTime? startDate, DateTime? endDate}) async {
    try {
      final actions = await getActionsByDateRange(startDate: startDate, endDate: endDate);

      final buffer = StringBuffer();
      buffer.writeln('=== Audit Log Export ===\n');
      buffer.writeln('Generated: ${DateTime.now()}\n');

      if (startDate != null || endDate != null) {
        buffer.writeln('Date Range: ${startDate ?? "Beginning"} to ${endDate ?? "Now"}\n');
      }

      buffer.writeln('Total Actions: ${actions.length}\n');
      buffer.writeln('===========================\n\n');

      for (var action in actions) {
        buffer.writeln(formatAuditEntry(action));
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export audit log', e, stackTrace);
      return 'Unable to export audit log.';
    }
  }
}
