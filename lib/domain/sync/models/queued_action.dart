/// Queued Action - Network-dependent operations stored for offline execution
///
/// When offline, actions are queued and executed when connection is restored
class QueuedAction {
  final String id;
  final QueuedActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final QueuedActionStatus status;
  final String? errorMessage;

  const QueuedAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.status = QueuedActionStatus.pending,
    this.errorMessage,
  });

  QueuedAction copyWith({
    String? id,
    QueuedActionType? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    int? attemptCount,
    QueuedActionStatus? status,
    String? errorMessage,
  }) {
    return QueuedAction(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Mark as processing
  QueuedAction markProcessing() {
    return copyWith(
      status: QueuedActionStatus.processing,
      lastAttemptAt: DateTime.now(),
      attemptCount: attemptCount + 1,
    );
  }

  /// Mark as succeeded
  QueuedAction markSucceeded() {
    return copyWith(
      status: QueuedActionStatus.succeeded,
    );
  }

  /// Mark as failed
  QueuedAction markFailed(String error) {
    // After 5 attempts, mark as permanently failed
    final newStatus = attemptCount >= 5
        ? QueuedActionStatus.failedPermanent
        : QueuedActionStatus.pending; // Retry

    return copyWith(
      status: newStatus,
      errorMessage: error,
      lastAttemptAt: DateTime.now(),
    );
  }

  /// Calculate backoff delay based on attempt count
  Duration get backoffDelay {
    // Exponential backoff: 2^n seconds (capped at 1 hour)
    final seconds = (1 << attemptCount).clamp(1, 3600);
    return Duration(seconds: seconds);
  }

  /// Check if action is ready to retry
  bool get isReadyToRetry {
    if (status != QueuedActionStatus.pending) return false;
    if (lastAttemptAt == null) return true;

    final timeSinceLastAttempt = DateTime.now().difference(lastAttemptAt!);
    return timeSinceLastAttempt >= backoffDelay;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'payload': payload,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastAttemptAt': lastAttemptAt?.millisecondsSinceEpoch,
      'attemptCount': attemptCount,
      'status': status.toString().split('.').last,
      'errorMessage': errorMessage,
    };
  }

  factory QueuedAction.fromJson(Map<String, dynamic> json) {
    return QueuedAction(
      id: json['id'] as String,
      type: QueuedActionType.values.firstWhere(
        (t) => t.toString() == 'QueuedActionType.${json['type']}',
        orElse: () => QueuedActionType.generic,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastAttemptAt'] as int)
          : null,
      attemptCount: json['attemptCount'] as int? ?? 0,
      status: QueuedActionStatus.values.firstWhere(
        (s) => s.toString() == 'QueuedActionStatus.${json['status']}',
        orElse: () => QueuedActionStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Action types that can be queued
enum QueuedActionType {
  createCalendarEvent,
  updateCalendarEvent,
  deleteCalendarEvent,
  createTask,
  updateTask,
  deleteTask,
  sendEmail,
  sendSMS,
  uploadFile,
  generic,
}

/// Status of queued action
enum QueuedActionStatus {
  pending, // Waiting to be processed
  processing, // Currently being executed
  succeeded, // Successfully completed
  failedPermanent, // Failed after max retries
}
