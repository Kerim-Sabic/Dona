import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../calendar/calendar_service.dart';
import '../weather/weather_service.dart';
import '../google_maps/google_maps_service.dart';
import '../../data/models/calendar_event.dart';

/// Proactive notification model
class ProactiveNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? actionData;
  final List<NotificationAction>? actions;

  ProactiveNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.timestamp,
    this.actionData,
    this.actions,
  });
}

class NotificationAction {
  final String label;
  final VoidCallback onTap;

  NotificationAction({required this.label, required this.onTap});
}

enum NotificationType {
  calendar,
  traffic,
  weather,
  reminder,
  suggestion,
  emergency,
}

enum NotificationPriority { low, normal, high, critical }

/// Proactive Assistant Service
///
/// This service monitors various data sources and proactively
/// notifies the user about important events, suggestions, and alerts.
class ProactiveAssistant {
  static final ProactiveAssistant _instance = ProactiveAssistant._internal();
  static ProactiveAssistant get instance => _instance;

  ProactiveAssistant._internal();

  Timer? _checkTimer;
  bool _isMonitoring = false;
  final List<ProactiveNotification> _notificationQueue = [];
  final Set<String> _shownNotifications = {};

  // Callbacks
  Function(ProactiveNotification)? onNotification;

  /// Start proactive monitoring
  void startMonitoring() {
    if (_isMonitoring) {
      AppLogger.warning('Proactive monitoring already running');
      return;
    }

    _isMonitoring = true;
    AppLogger.info('Starting proactive monitoring');

    // Check every 5 minutes
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _runChecks();
    });

    // Run initial check
    _runChecks();
  }

  /// Stop proactive monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    _isMonitoring = false;
    AppLogger.info('Stopped proactive monitoring');
  }

  /// Run all proactive checks
  Future<void> _runChecks() async {
    try {
      AppLogger.debug('Running proactive checks...');

      await Future.wait([
        _checkUpcomingEvents(),
        _checkWeatherAlerts(),
        _checkMorningBriefing(),
        _checkEndOfDayWrapup(),
      ]);
    } catch (e, stackTrace) {
      AppLogger.error('Error in proactive checks', e, stackTrace);
    }
  }

  /// Check for upcoming calendar events
  Future<void> _checkUpcomingEvents() async {
    try {
      final events = await CalendarService.instance.getUpcomingEvents(maxResults: 10);
      final now = DateTime.now();

      for (final event in events) {
        final timeUntil = event.startTime.difference(now);

        // 1 hour before meeting
        if (timeUntil.inMinutes >= 55 && timeUntil.inMinutes <= 65) {
          await _checkMeetingPreparation(event, timeUntil);
        }

        // 30 minutes before - travel time check
        if (timeUntil.inMinutes >= 25 && timeUntil.inMinutes <= 35) {
          await _checkTravelTime(event, timeUntil);
        }

        // 15 minutes before - final reminder
        if (timeUntil.inMinutes >= 10 && timeUntil.inMinutes <= 20) {
          await _sendFinalReminder(event, timeUntil);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking upcoming events', e, stackTrace);
    }
  }

  /// Check if meeting preparation is needed
  Future<void> _checkMeetingPreparation(CalendarEvent event, Duration timeUntil) async {
    final notificationId = 'prep_${event.id}_${event.startTime.day}';

    if (_hasShownNotification(notificationId)) return;

    // Create preparation notification
    _sendNotification(
      ProactiveNotification(
        id: notificationId,
        title: 'Meeting in ${timeUntil.inMinutes} minutes',
        message: '${event.title}\n\nWould you like a quick briefing?',
        type: NotificationType.calendar,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now(),
        actionData: {'event': event},
        actions: [
          NotificationAction(
            label: 'Brief me',
            onTap: () => _generateMeetingBrief(event),
          ),
          NotificationAction(
            label: 'Dismiss',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// Check travel time to event location
  Future<void> _checkTravelTime(CalendarEvent event, Duration timeUntil) async {
    if (event.location == null || event.location!.isEmpty) return;

    final notificationId = 'travel_${event.id}_${event.startTime.day}';
    if (_hasShownNotification(notificationId)) return;

    try {
      // For now, use mock travel time
      // In production, use actual Google Maps directions
      final travelTimeMinutes = 25; // Mock value

      if (travelTimeMinutes > 20) {
        // Need to leave soon
        final departureTime = event.startTime.subtract(Duration(minutes: travelTimeMinutes));
        final minutesUntilDeparture = departureTime.difference(DateTime.now()).inMinutes;

        if (minutesUntilDeparture <= 5) {
          _sendNotification(
            ProactiveNotification(
              id: notificationId,
              title: '🚗 Time to leave!',
              message: 'You need to leave now to reach ${event.location} on time.\n'
                  'Travel time: $travelTimeMinutes minutes',
              type: NotificationType.traffic,
              priority: NotificationPriority.high,
              timestamp: DateTime.now(),
              actionData: {
                'event': event,
                'travelTime': travelTimeMinutes,
              },
              actions: [
                NotificationAction(
                  label: 'Navigate',
                  onTap: () => _startNavigation(event.location!),
                ),
                NotificationAction(
                  label: 'Snooze 5 min',
                  onTap: () {},
                ),
              ],
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking travel time', e, stackTrace);
    }
  }

  /// Send final reminder before meeting
  Future<void> _sendFinalReminder(CalendarEvent event, Duration timeUntil) async {
    final notificationId = 'reminder_${event.id}_${event.startTime.day}';
    if (_hasShownNotification(notificationId)) return;

    _sendNotification(
      ProactiveNotification(
        id: notificationId,
        title: 'Meeting starting in ${timeUntil.inMinutes} minutes',
        message: event.title,
        type: NotificationType.reminder,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now(),
        actionData: {'event': event},
      ),
    );
  }

  /// Check for weather alerts
  Future<void> _checkWeatherAlerts() async {
    try {
      final now = DateTime.now();
      final hour = now.hour;

      // Check weather at 7 AM (morning prep)
      if (hour == 7 && !_hasShownNotification('weather_morning_${now.day}')) {
        final weather = await WeatherService.instance.getCurrentWeather();

        if (weather != null) {
          String alert = '';

          // Rain alert
          if (weather.description.toLowerCase().contains('rain')) {
            alert = '☔ Rain expected today. Don\'t forget your umbrella!';
          }
          // Very hot
          else if (weather.temperature > 30) {
            alert = '🌡️ Hot day ahead (${weather.temperature.toInt()}°C). Stay hydrated!';
          }
          // Very cold
          else if (weather.temperature < 5) {
            alert = '🧥 Cold day ahead (${weather.temperature.toInt()}°C). Dress warm!';
          }

          if (alert.isNotEmpty) {
            _sendNotification(
              ProactiveNotification(
                id: 'weather_morning_${now.day}',
                title: 'Weather Alert',
                message: alert,
                type: NotificationType.weather,
                priority: NotificationPriority.normal,
                timestamp: now,
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking weather alerts', e, stackTrace);
    }
  }

  /// Morning briefing
  Future<void> _checkMorningBriefing() async {
    final now = DateTime.now();
    final hour = now.hour;

    // Send morning briefing at 7 AM
    if (hour == 7 && !_hasShownNotification('morning_briefing_${now.day}')) {
      _sendNotification(
        ProactiveNotification(
          id: 'morning_briefing_${now.day}',
          title: '☀️ Good morning!',
          message: 'Ready for your daily briefing?',
          type: NotificationType.suggestion,
          priority: NotificationPriority.normal,
          timestamp: now,
          actions: [
            NotificationAction(
              label: 'Let\'s go',
              onTap: () => _generateMorningBriefing(),
            ),
            NotificationAction(
              label: 'Later',
              onTap: () {},
            ),
          ],
        ),
      );
    }
  }

  /// End of day wrap-up
  Future<void> _checkEndOfDayWrapup() async {
    final now = DateTime.now();
    final hour = now.hour;

    // Send wrap-up at 6 PM
    if (hour == 18 && !_hasShownNotification('wrapup_${now.day}')) {
      _sendNotification(
        ProactiveNotification(
          id: 'wrapup_${now.day}',
          title: '🌅 End of day',
          message: 'Great work today! Want a summary of tomorrow?',
          type: NotificationType.suggestion,
          priority: NotificationPriority.low,
          timestamp: now,
          actions: [
            NotificationAction(
              label: 'Show me',
              onTap: () => _generateTomorrowPreview(),
            ),
            NotificationAction(
              label: 'Not now',
              onTap: () {},
            ),
          ],
        ),
      );
    }
  }

  /// Generate meeting brief
  Future<void> _generateMeetingBrief(CalendarEvent event) async {
    AppLogger.info('Generating meeting brief for: ${event.title}');
    // TODO: Implement with AI service
    // This would search emails, documents, and generate a comprehensive brief
  }

  /// Start navigation
  Future<void> _startNavigation(String location) async {
    AppLogger.info('Starting navigation to: $location');
    // TODO: Implement with Google Maps
  }

  /// Generate morning briefing
  Future<void> _generateMorningBriefing() async {
    AppLogger.info('Generating morning briefing');
    // TODO: Implement comprehensive morning briefing
    // - Weather
    // - Calendar events
    // - News headlines
    // - Tasks for the day
  }

  /// Generate tomorrow preview
  Future<void> _generateTomorrowPreview() async {
    AppLogger.info('Generating tomorrow preview');
    // TODO: Implement tomorrow preview
  }

  /// Send notification
  void _sendNotification(ProactiveNotification notification) {
    _shownNotifications.add(notification.id);
    _notificationQueue.add(notification);

    AppLogger.info('Proactive notification: ${notification.title}');

    // Call callback if set
    if (onNotification != null) {
      onNotification!(notification);
    }
  }

  /// Check if notification already shown
  bool _hasShownNotification(String id) {
    return _shownNotifications.contains(id);
  }

  /// Get queued notifications
  List<ProactiveNotification> get notifications => _notificationQueue;

  /// Clear notification
  void clearNotification(String id) {
    _notificationQueue.removeWhere((n) => n.id == id);
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notificationQueue.clear();
  }

  /// Reset shown notifications (for testing)
  void resetShownNotifications() {
    _shownNotifications.clear();
  }
}
