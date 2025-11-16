import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'models/queued_action.dart';
import '../../core/utils/logger.dart';
import '../../services/storage/local_storage_service.dart';
import '../../services/calendar/calendar_service.dart';
import '../../services/google_tasks/google_tasks_service.dart';
import '../../data/models/calendar_event.dart';

/// Action Queue - Manages offline/online action synchronization
///
/// Queues network-dependent actions when offline and executes them when online
class ActionQueue {
  static final ActionQueue _instance = ActionQueue._internal();
  static ActionQueue get instance => _instance;

  ActionQueue._internal();

  final _uuid = const Uuid();
  static const String _queueKey = 'action_queue';

  final List<QueuedAction> _queue = [];
  bool _isProcessing = false;

  // Callbacks for UI updates
  void Function()? onQueueChanged;
  void Function(QueuedAction action, bool success)? onActionProcessed;

  Future<void> init() async {
    try {
      await _loadQueue();
      AppLogger.info('ActionQueue initialized with ${_queue.length} pending actions');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ActionQueue', e, stackTrace);
    }
  }

  /// Enqueue a new action
  Future<void> enqueue(QueuedAction action) async {
    try {
      _queue.add(action);
      await _persistQueue();

      onQueueChanged?.call();

      AppLogger.info('Enqueued action: ${action.type} (ID: ${action.id})');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enqueue action', e, stackTrace);
      rethrow;
    }
  }

  /// Enqueue calendar event creation
  Future<void> enqueueCreateEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    final action = QueuedAction(
      id: _uuid.v4(),
      type: QueuedActionType.createCalendarEvent,
      payload: {
        'title': title,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'description': description,
        'location': location,
      },
      createdAt: DateTime.now(),
    );

    await enqueue(action);
  }

  /// Enqueue task creation
  Future<void> enqueueCreateTask({
    required String taskListId,
    required String title,
    String? notes,
    DateTime? due,
  }) async {
    final action = QueuedAction(
      id: _uuid.v4(),
      type: QueuedActionType.createTask,
      payload: {
        'taskListId': taskListId,
        'title': title,
        'notes': notes,
        'due': due?.millisecondsSinceEpoch,
      },
      createdAt: DateTime.now(),
    );

    await enqueue(action);
  }

  /// Process all pending actions
  Future<void> processAll() async {
    if (_isProcessing) {
      AppLogger.debug('Already processing queue, skipping');
      return;
    }

    try {
      _isProcessing = true;

      AppLogger.info('Processing action queue (${_queue.length} total)');

      // Get actions ready to retry
      final readyActions = _queue
          .where((a) => a.isReadyToRetry || a.status == QueuedActionStatus.pending)
          .toList();

      if (readyActions.isEmpty) {
        AppLogger.debug('No actions ready to process');
        return;
      }

      for (final action in readyActions) {
        await _processAction(action);
      }

      // Remove succeeded actions
      _queue.removeWhere((a) => a.status == QueuedActionStatus.succeeded);

      await _persistQueue();
      onQueueChanged?.call();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to process action queue', e, stackTrace);
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single action
  Future<void> _processAction(QueuedAction action) async {
    try {
      AppLogger.debug('Processing action: ${action.type} (attempt ${action.attemptCount + 1})');

      // Mark as processing
      final index = _queue.indexOf(action);
      if (index == -1) return;

      _queue[index] = action.markProcessing();

      // Execute based on type
      bool success = false;
      String? error;

      try {
        success = await _executeAction(action);
      } catch (e) {
        error = e.toString();
        AppLogger.warning('Action execution failed: $error');
      }

      // Update status
      if (success) {
        _queue[index] = action.markSucceeded();
        AppLogger.info('Action succeeded: ${action.type}');
        onActionProcessed?.call(action, true);
      } else {
        _queue[index] = action.markFailed(error ?? 'Unknown error');
        AppLogger.warning('Action failed: ${action.type} (attempt ${action.attemptCount})');
        onActionProcessed?.call(action, false);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to process action', e, stackTrace);
    }
  }

  /// Execute the action based on its type
  Future<bool> _executeAction(QueuedAction action) async {
    switch (action.type) {
      case QueuedActionType.createCalendarEvent:
        return await _executeCreateEvent(action.payload);

      case QueuedActionType.createTask:
        return await _executeCreateTask(action.payload);

      case QueuedActionType.sendEmail:
        // TODO: Implement email execution
        AppLogger.warning('Email execution not yet implemented');
        return false;

      case QueuedActionType.sendSMS:
        // TODO: Implement SMS execution
        AppLogger.warning('SMS execution not yet implemented');
        return false;

      default:
        AppLogger.warning('Unknown action type: ${action.type}');
        return false;
    }
  }

  /// Execute calendar event creation
  Future<bool> _executeCreateEvent(Map<String, dynamic> payload) async {
    try {
      final event = CalendarEvent(
        id: null, // Will be assigned by service
        title: payload['title'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(payload['startTime'] as int),
        endTime: DateTime.fromMillisecondsSinceEpoch(payload['endTime'] as int),
        description: payload['description'] as String?,
        location: payload['location'] as String?,
      );

      await CalendarService.instance.createEvent(event);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create calendar event', e, stackTrace);
      return false;
    }
  }

  /// Execute task creation
  Future<bool> _executeCreateTask(Map<String, dynamic> payload) async {
    try {
      final taskListId = payload['taskListId'] as String;
      final task = GoogleTask(
        id: '', // Will be assigned by service
        title: payload['title'] as String,
        notes: payload['notes'] as String?,
        due: payload['due'] != null
            ? DateTime.fromMillisecondsSinceEpoch(payload['due'] as int)
            : null,
        status: 'needsAction',
        updated: DateTime.now(),
      );

      await GoogleTasksService.instance.createTask(taskListId, task);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create task', e, stackTrace);
      return false;
    }
  }

  /// Get pending actions count
  int get pendingCount {
    return _queue.where((a) => a.status == QueuedActionStatus.pending).length;
  }

  /// Get all actions (for UI display)
  List<QueuedAction> getActions() {
    return List.unmodifiable(_queue);
  }

  /// Clear all succeeded actions
  Future<void> clearSucceeded() async {
    _queue.removeWhere((a) => a.status == QueuedActionStatus.succeeded);
    await _persistQueue();
    onQueueChanged?.call();
  }

  /// Clear all actions (dangerous!)
  Future<void> clearAll() async {
    _queue.clear();
    await _persistQueue();
    onQueueChanged?.call();
  }

  /// Load queue from storage
  Future<void> _loadQueue() async {
    try {
      final json = LocalStorageService.instance.getString(_queueKey);
      if (json == null || json.isEmpty) return;

      final List<dynamic> list = jsonDecode(json) as List;
      _queue.clear();
      _queue.addAll(list.map((e) => QueuedAction.fromJson(e as Map<String, dynamic>)));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load action queue', e, stackTrace);
    }
  }

  /// Persist queue to storage
  Future<void> _persistQueue() async {
    try {
      final json = jsonEncode(_queue.map((a) => a.toJson()).toList());
      await LocalStorageService.instance.setString(_queueKey, json);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to persist action queue', e, stackTrace);
    }
  }
}
