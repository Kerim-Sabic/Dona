import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../gmail/gmail_service.dart';
import '../calendar/calendar_service.dart';
import '../google_drive/google_drive_service.dart';

/// Offline Manager
/// Handles offline functionality, caching, and sync
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  static OfflineManager get instance => _instance;

  OfflineManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isOnline = true;
  DateTime? _lastSyncTime;
  final List<PendingAction> _pendingActions = [];

  // Callbacks
  Function(bool)? onConnectivityChanged;
  Function()? onSyncComplete;

  /// Initialize offline manager
  Future<void> init() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      // Load pending actions
      await _loadPendingActions();

      AppLogger.info('OfflineManager initialized. Online: $_isOnline');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing OfflineManager', e, stackTrace);
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    AppLogger.info('Connectivity changed: ${result.name}. Online: $_isOnline');

    if (onConnectivityChanged != null) {
      onConnectivityChanged!(_isOnline);
    }

    // If we just came online, sync pending actions
    if (_isOnline && !wasOnline) {
      _syncPendingActions();
    }
  }

  /// Check if online
  bool get isOnline => _isOnline;

  /// Check if offline
  bool get isOffline => !_isOnline;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Cache emails for offline access
  Future<void> cacheEmails({int maxEmails = 50}) async {
    try {
      if (!GmailService.instance.isAuthenticated) {
        AppLogger.warning('Cannot cache emails: not authenticated');
        return;
      }

      AppLogger.info('Caching emails for offline access...');

      final emails = await GmailService.instance.getInboxMessages(
        maxResults: maxEmails,
      );

      // Store in local cache
      final emailsJson = jsonEncode(emails.map((e) => {
        'id': e.id,
        'from': e.from,
        'to': e.to,
        'subject': e.subject,
        'body': e.body,
        'date': e.date?.toIso8601String(),
        'isRead': e.isRead,
      }).toList());

      await LocalStorageService.instance.setString('cached_emails', emailsJson);
      await LocalStorageService.instance.setString(
        'cached_emails_time',
        DateTime.now().toIso8601String(),
      );

      AppLogger.info('Cached ${emails.length} emails');
    } catch (e, stackTrace) {
      AppLogger.error('Error caching emails', e, stackTrace);
    }
  }

  /// Get cached emails
  List<dynamic> getCachedEmails() {
    try {
      final emailsJson = LocalStorageService.instance.getString('cached_emails');
      if (emailsJson != null) {
        return jsonDecode(emailsJson) as List<dynamic>;
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting cached emails', e);
      return [];
    }
  }

  /// Cache calendar events for offline access
  Future<void> cacheCalendarEvents({int days = 30}) async {
    try {
      if (!CalendarService.instance.isAuthenticated) {
        AppLogger.warning('Cannot cache calendar: not authenticated');
        return;
      }

      AppLogger.info('Caching calendar events for offline access...');

      final now = DateTime.now();
      final future = now.add(Duration(days: days));

      final events = await CalendarService.instance.getEventsInRange(now, future);

      // Store in local cache
      final eventsJson = jsonEncode(events.map((e) => {
        'id': e.id,
        'title': e.title,
        'description': e.description,
        'startTime': e.startTime.toIso8601String(),
        'endTime': e.endTime.toIso8601String(),
        'location': e.location,
        'attendees': e.attendees,
      }).toList());

      await LocalStorageService.instance.setString('cached_events', eventsJson);
      await LocalStorageService.instance.setString(
        'cached_events_time',
        DateTime.now().toIso8601String(),
      );

      AppLogger.info('Cached ${events.length} calendar events');
    } catch (e, stackTrace) {
      AppLogger.error('Error caching calendar events', e, stackTrace);
    }
  }

  /// Get cached calendar events
  List<dynamic> getCachedCalendarEvents() {
    try {
      final eventsJson = LocalStorageService.instance.getString('cached_events');
      if (eventsJson != null) {
        return jsonDecode(eventsJson) as List<dynamic>;
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting cached events', e);
      return [];
    }
  }

  /// Add pending action (to be synced when online)
  Future<void> addPendingAction(PendingAction action) async {
    _pendingActions.add(action);
    await _savePendingActions();
    AppLogger.info('Added pending action: ${action.type}');

    // Try to sync immediately if online
    if (_isOnline) {
      await _syncPendingActions();
    }
  }

  /// Sync all pending actions
  Future<void> _syncPendingActions() async {
    if (_pendingActions.isEmpty) return;

    AppLogger.info('Syncing ${_pendingActions.length} pending actions...');

    final completedActions = <PendingAction>[];

    for (final action in _pendingActions) {
      try {
        final success = await _executePendingAction(action);
        if (success) {
          completedActions.add(action);
          AppLogger.info('Completed pending action: ${action.type}');
        }
      } catch (e) {
        AppLogger.error('Error executing pending action', e);
      }
    }

    // Remove completed actions
    for (final action in completedActions) {
      _pendingActions.remove(action);
    }

    await _savePendingActions();

    if (completedActions.isNotEmpty) {
      _lastSyncTime = DateTime.now();
      if (onSyncComplete != null) {
        onSyncComplete!();
      }
      AppLogger.info('Sync complete. ${completedActions.length} actions synced');
    }
  }

  /// Execute a pending action
  Future<bool> _executePendingAction(PendingAction action) async {
    try {
      switch (action.type) {
        case ActionType.sendEmail:
          // Execute send email action
          final emailData = action.data;
          // Implement email sending
          return true;

        case ActionType.createEvent:
          // Execute create event action
          final eventData = action.data;
          // Implement event creation
          return true;

        case ActionType.uploadFile:
          // Execute file upload action
          final fileData = action.data;
          // Implement file upload
          return true;

        default:
          AppLogger.warning('Unknown action type: ${action.type}');
          return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error executing action ${action.type}', e, stackTrace);
      return false;
    }
  }

  /// Perform full sync
  Future<void> performFullSync() async {
    try {
      if (!_isOnline) {
        AppLogger.warning('Cannot sync: offline');
        return;
      }

      AppLogger.info('Performing full sync...');

      // Cache emails
      await cacheEmails();

      // Cache calendar events
      await cacheCalendarEvents();

      // Sync pending actions
      await _syncPendingActions();

      _lastSyncTime = DateTime.now();

      if (onSyncComplete != null) {
        onSyncComplete!();
      }

      AppLogger.info('Full sync complete');
    } catch (e, stackTrace) {
      AppLogger.error('Error during full sync', e, stackTrace);
    }
  }

  /// Save pending actions to storage
  Future<void> _savePendingActions() async {
    try {
      final json = jsonEncode(_pendingActions.map((a) => a.toJson()).toList());
      await LocalStorageService.instance.setString('pending_actions', json);
    } catch (e) {
      AppLogger.error('Error saving pending actions', e);
    }
  }

  /// Load pending actions from storage
  Future<void> _loadPendingActions() async {
    try {
      final json = LocalStorageService.instance.getString('pending_actions');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _pendingActions.clear();
        _pendingActions.addAll(
          data.map((item) => PendingAction.fromJson(item)),
        );
        AppLogger.info('Loaded ${_pendingActions.length} pending actions');
      }
    } catch (e) {
      AppLogger.error('Error loading pending actions', e);
    }
  }

  /// Get cache status
  CacheStatus getCacheStatus() {
    final cachedEmailsTime = LocalStorageService.instance.getString('cached_emails_time');
    final cachedEventsTime = LocalStorageService.instance.getString('cached_events_time');

    return CacheStatus(
      hasEmails: cachedEmailsTime != null,
      emailsCachedAt: cachedEmailsTime != null ? DateTime.parse(cachedEmailsTime) : null,
      hasEvents: cachedEventsTime != null,
      eventsCachedAt: cachedEventsTime != null ? DateTime.parse(cachedEventsTime) : null,
      pendingActionsCount: _pendingActions.length,
    );
  }

  /// Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Pending action to be synced when online
class PendingAction {
  final String id;
  final ActionType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  PendingAction({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'] as String,
      type: ActionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ActionType.other,
      ),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Action type enum
enum ActionType {
  sendEmail,
  createEvent,
  uploadFile,
  updateTask,
  other,
}

/// Cache status
class CacheStatus {
  final bool hasEmails;
  final DateTime? emailsCachedAt;
  final bool hasEvents;
  final DateTime? eventsCachedAt;
  final int pendingActionsCount;

  CacheStatus({
    required this.hasEmails,
    this.emailsCachedAt,
    required this.hasEvents,
    this.eventsCachedAt,
    required this.pendingActionsCount,
  });

  @override
  String toString() {
    return '''
Cache Status:
  Emails cached: $hasEmails ${emailsCachedAt != null ? '(at $emailsCachedAt)' : ''}
  Events cached: $hasEvents ${eventsCachedAt != null ? '(at $eventsCachedAt)' : ''}
  Pending actions: $pendingActionsCount
''';
  }
}
