import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/logger.dart';
import '../../core/platform/platform_service.dart';
import '../calendar/calendar_service.dart';
import '../gmail/gmail_service.dart';
import '../../data/user_profile.dart';
import '../ai/ai_service.dart';

/// Smart Notification Service
/// Intelligently manages notifications based on:
/// - User's schedule and availability
/// - Notification priority and urgency
/// - Do Not Disturb modes
/// - Contextual relevance
class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  static SmartNotificationService get instance => _instance;

  SmartNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _doNotDisturb = false;
  List<NotificationRule> _rules = [];
  final List<QueuedNotification> _queue = [];

  /// Initialize notification service
  Future<void> init() async {
    try {
      if (!PlatformService.instance.features.hasNotifications) {
        AppLogger.warning('Notifications not supported on this platform');
        return;
      }

      AppLogger.info('Initializing Smart Notification Service...');

      // Initialize for each platform
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iOSSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Windows/Linux settings
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
        macOS: iOSSettings,
        linux: linuxSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Request permissions
      await _requestPermissions();

      // Load notification rules
      await _loadNotificationRules();

      _isInitialized = true;
      AppLogger.info('Smart Notification Service initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing notifications', e, stackTrace);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      if (PlatformService.instance.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission();
      } else if (PlatformService.instance.isIOS || PlatformService.instance.isMacOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      AppLogger.info('Notification permissions requested');
    } catch (e) {
      AppLogger.error('Error requesting notification permissions', e);
    }
  }

  /// Show smart notification
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.general,
    Map<String, dynamic>? payload,
    DateTime? scheduledTime,
  }) async {
    try {
      if (!_isInitialized) {
        AppLogger.warning('Notifications not initialized');
        return;
      }

      final notification = QueuedNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        priority: priority,
        category: category,
        payload: payload,
        scheduledTime: scheduledTime,
        createdAt: DateTime.now(),
      );

      // Check if should show immediately or queue
      if (await _shouldShowNow(notification)) {
        await _displayNotification(notification);
      } else {
        _queueNotification(notification);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error showing notification', e, stackTrace);
    }
  }

  /// Check if notification should be shown now
  Future<bool> _shouldShowNow(QueuedNotification notification) async {
    // Always show critical notifications
    if (notification.priority == NotificationPriority.critical) {
      return true;
    }

    // Don't show if Do Not Disturb is enabled (except critical)
    if (_doNotDisturb) {
      AppLogger.info('DND enabled, queuing notification: ${notification.title}');
      return false;
    }

    // Check if user is in a meeting
    final isInMeeting = await _isUserInMeeting();
    if (isInMeeting && notification.priority != NotificationPriority.high) {
      AppLogger.info('User in meeting, queuing notification: ${notification.title}');
      return false;
    }

    // Check work hours
    if (!UserProfile.instance.isWorkHours && notification.category == NotificationCategory.work) {
      AppLogger.info('Outside work hours, queuing work notification: ${notification.title}');
      return false;
    }

    // Check notification rules
    for (final rule in _rules) {
      if (!rule.shouldAllow(notification)) {
        AppLogger.info('Blocked by rule: ${rule.name}');
        return false;
      }
    }

    return true;
  }

  /// Display notification immediately
  Future<void> _displayNotification(QueuedNotification notification) async {
    try {
      final platformChannelSpecifics = await _getPlatformSpecifics(notification);

      if (notification.scheduledTime != null) {
        // Schedule for later
        await _notifications.zonedSchedule(
          notification.id,
          notification.title,
          notification.body,
          notification.scheduledTime!,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        AppLogger.info('Scheduled notification: ${notification.title}');
      } else {
        // Show immediately
        await _notifications.show(
          notification.id,
          notification.title,
          notification.body,
          platformChannelSpecifics,
        );

        AppLogger.info('Showed notification: ${notification.title}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error displaying notification', e, stackTrace);
    }
  }

  /// Get platform-specific notification settings
  Future<NotificationDetails> _getPlatformSpecifics(QueuedNotification notification) async {
    // Android settings
    final androidDetails = AndroidNotificationDetails(
      'dona_${notification.category.name}',
      notification.category.displayName,
      channelDescription: 'Dona AI ${notification.category.displayName} notifications',
      importance: _getAndroidImportance(notification.priority),
      priority: _getAndroidPriority(notification.priority),
      playSound: true,
      enableVibration: notification.priority != NotificationPriority.low,
    );

    // iOS/macOS settings
    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: notification.priority == NotificationPriority.critical
          ? 'critical_sound.aiff'
          : null,
    );

    // Linux settings
    final linuxDetails = LinuxNotificationDetails(
      urgency: _getLinuxUrgency(notification.priority),
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
      macOS: iOSDetails,
      linux: linuxDetails,
    );
  }

  /// Queue notification for later
  void _queueNotification(QueuedNotification notification) {
    _queue.add(notification);
    AppLogger.info('Queued notification: ${notification.title}');
  }

  /// Process queued notifications
  Future<void> processQueue() async {
    if (_queue.isEmpty) return;

    AppLogger.info('Processing ${_queue.length} queued notifications');

    final toShow = <QueuedNotification>[];

    for (final notification in _queue) {
      if (await _shouldShowNow(notification)) {
        toShow.add(notification);
      }
    }

    for (final notification in toShow) {
      await _displayNotification(notification);
      _queue.remove(notification);
    }

    AppLogger.info('Processed queue. ${toShow.length} shown, ${_queue.length} remaining');
  }

  /// Enable Do Not Disturb
  Future<void> enableDoNotDisturb({Duration? duration}) async {
    _doNotDisturb = true;
    AppLogger.info('Do Not Disturb enabled');

    if (duration != null) {
      // Auto-disable after duration
      Future.delayed(duration, () {
        disableDoNotDisturb();
      });
    }
  }

  /// Disable Do Not Disturb
  void disableDoNotDisturb() {
    _doNotDisturb = false;
    AppLogger.info('Do Not Disturb disabled');

    // Process queued notifications
    processQueue();
  }

  /// Check if user is currently in a meeting
  Future<bool> _isUserInMeeting() async {
    try {
      if (!CalendarService.instance.isAuthenticated) return false;

      final now = DateTime.now();
      final events = await CalendarService.instance.getEventsInRange(
        now,
        now.add(const Duration(minutes: 1)),
      );

      return events.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Add notification rule
  void addRule(NotificationRule rule) {
    _rules.add(rule);
    AppLogger.info('Added notification rule: ${rule.name}');
  }

  /// Remove notification rule
  void removeRule(String ruleName) {
    _rules.removeWhere((r) => r.name == ruleName);
    AppLogger.info('Removed notification rule: $ruleName');
  }

  /// Get Android importance from priority
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  /// Get Android priority from priority
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  /// Get Linux urgency from priority
  LinuxNotificationUrgency _getLinuxUrgency(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return LinuxNotificationUrgency.critical;
      case NotificationPriority.high:
        return LinuxNotificationUrgency.normal;
      case NotificationPriority.normal:
        return LinuxNotificationUrgency.normal;
      case NotificationPriority.low:
        return LinuxNotificationUrgency.low;
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Load notification rules
  Future<void> _loadNotificationRules() async {
    // Default rules
    _rules = [
      NotificationRule(
        name: 'Work Hours Only',
        shouldAllow: (notification) {
          if (notification.category == NotificationCategory.work) {
            return UserProfile.instance.isWorkHours;
          }
          return true;
        },
      ),
      NotificationRule(
        name: 'Sleep Hours Block',
        shouldAllow: (notification) {
          final hour = DateTime.now().hour;
          // Block non-critical notifications 10 PM - 7 AM
          if (hour >= 22 || hour < 7) {
            return notification.priority == NotificationPriority.critical;
          }
          return true;
        },
      ),
    ];
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    _queue.clear();
    AppLogger.info('Cancelled all notifications');
  }

  /// Get notification statistics
  NotificationStats getStats() {
    return NotificationStats(
      queuedCount: _queue.length,
      doNotDisturb: _doNotDisturb,
      rulesCount: _rules.length,
    );
  }
}

/// Queued notification
class QueuedNotification {
  final int id;
  final String title;
  final String body;
  final NotificationPriority priority;
  final NotificationCategory category;
  final Map<String, dynamic>? payload;
  final DateTime? scheduledTime;
  final DateTime createdAt;

  QueuedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.category,
    this.payload,
    this.scheduledTime,
    required this.createdAt,
  });
}

/// Notification priority
enum NotificationPriority {
  critical, // Always show, even in DND
  high,     // Show unless in meeting
  normal,   // Show during normal times
  low,      // Low priority, can be delayed
}

/// Notification category
enum NotificationCategory {
  general('General'),
  work('Work'),
  personal('Personal'),
  health('Health'),
  social('Social'),
  reminder('Reminder');

  final String displayName;
  const NotificationCategory(this.displayName);
}

/// Notification rule
class NotificationRule {
  final String name;
  final bool Function(QueuedNotification) shouldAllow;

  NotificationRule({
    required this.name,
    required this.shouldAllow,
  });
}

/// Notification statistics
class NotificationStats {
  final int queuedCount;
  final bool doNotDisturb;
  final int rulesCount;

  NotificationStats({
    required this.queuedCount,
    required this.doNotDisturb,
    required this.rulesCount,
  });

  @override
  String toString() {
    return 'Queued: $queuedCount, DND: $doNotDisturb, Rules: $rulesCount';
  }
}
