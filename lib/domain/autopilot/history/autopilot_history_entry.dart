/// Autopilot History Entry
///
/// Records what autopilots were run and their outcomes

enum AutopilotType {
  planMyDay,
  studyAutopilot,
  weeklyReview,
  focusMode,
  triage,
  relationship,
}

extension AutopilotTypeExtension on AutopilotType {
  String get displayName {
    switch (this) {
      case AutopilotType.planMyDay:
        return 'Plan My Day';
      case AutopilotType.studyAutopilot:
        return 'Study Autopilot';
      case AutopilotType.weeklyReview:
        return 'Weekly Review';
      case AutopilotType.focusMode:
        return 'Focus Mode';
      case AutopilotType.triage:
        return 'Triage';
      case AutopilotType.relationship:
        return 'Relationship Maintenance';
    }
  }

  String get icon {
    switch (this) {
      case AutopilotType.planMyDay:
        return '📅';
      case AutopilotType.studyAutopilot:
        return '📚';
      case AutopilotType.weeklyReview:
        return '📊';
      case AutopilotType.focusMode:
        return '🎯';
      case AutopilotType.triage:
        return '📋';
      case AutopilotType.relationship:
        return '🤝';
    }
  }
}

enum AutopilotHistoryStatus {
  success,      // Completed successfully
  partial,      // Some actions succeeded, some failed
  failed,       // Failed to complete
  cancelled,    // User cancelled
}

extension AutopilotHistoryStatusExtension on AutopilotHistoryStatus {
  String get displayName {
    switch (this) {
      case AutopilotHistoryStatus.success:
        return 'Success';
      case AutopilotHistoryStatus.partial:
        return 'Partial';
      case AutopilotHistoryStatus.failed:
        return 'Failed';
      case AutopilotHistoryStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get icon {
    switch (this) {
      case AutopilotHistoryStatus.success:
        return '✅';
      case AutopilotHistoryStatus.partial:
        return '⚠️';
      case AutopilotHistoryStatus.failed:
        return '❌';
      case AutopilotHistoryStatus.cancelled:
        return '🚫';
    }
  }
}

class AutopilotHistoryEntry {
  final String id;
  final DateTime timestamp;
  final AutopilotType type;
  final String summary;
  final int totalActions;
  final int executedActions;
  final AutopilotHistoryStatus status;
  final String? errorMessage;
  final List<String>? createdItemIds; // IDs of created tasks/events
  final Map<String, dynamic>? metadata;

  const AutopilotHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.summary,
    required this.totalActions,
    required this.executedActions,
    required this.status,
    this.errorMessage,
    this.createdItemIds,
    this.metadata,
  });

  /// Get success rate (0.0 - 1.0)
  double get successRate {
    if (totalActions == 0) return 0.0;
    return executedActions / totalActions;
  }

  /// Check if fully successful
  bool get isFullSuccess {
    return status == AutopilotHistoryStatus.success &&
           executedActions == totalActions;
  }

  factory AutopilotHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AutopilotHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      type: AutopilotType.values.firstWhere(
        (t) => t.toString() == 'AutopilotType.${json['type']}',
        orElse: () => AutopilotType.planMyDay,
      ),
      summary: json['summary'] as String,
      totalActions: json['totalActions'] as int,
      executedActions: json['executedActions'] as int,
      status: AutopilotHistoryStatus.values.firstWhere(
        (s) => s.toString() == 'AutopilotHistoryStatus.${json['status']}',
        orElse: () => AutopilotHistoryStatus.success,
      ),
      errorMessage: json['errorMessage'] as String?,
      createdItemIds: (json['createdItemIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'summary': summary,
      'totalActions': totalActions,
      'executedActions': executedActions,
      'status': status.toString().split('.').last,
      'errorMessage': errorMessage,
      'createdItemIds': createdItemIds,
      'metadata': metadata,
    };
  }

  AutopilotHistoryEntry copyWith({
    String? id,
    DateTime? timestamp,
    AutopilotType? type,
    String? summary,
    int? totalActions,
    int? executedActions,
    AutopilotHistoryStatus? status,
    String? errorMessage,
    List<String>? createdItemIds,
    Map<String, dynamic>? metadata,
  }) {
    return AutopilotHistoryEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      totalActions: totalActions ?? this.totalActions,
      executedActions: executedActions ?? this.executedActions,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdItemIds: createdItemIds ?? this.createdItemIds,
      metadata: metadata ?? this.metadata,
    );
  }
}
