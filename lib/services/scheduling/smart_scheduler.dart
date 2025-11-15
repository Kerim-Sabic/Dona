import '../../core/utils/logger.dart';
import '../calendar/calendar_service.dart';
import '../../data/models/calendar_event.dart';
import '../../data/user_profile.dart';
import '../ai/ai_service.dart';

/// Smart Scheduling Assistant with auto-suggestions
class SmartScheduler {
  static final SmartScheduler _instance = SmartScheduler._internal();
  static SmartScheduler get instance => _instance;

  SmartScheduler._internal();

  /// Find optimal meeting time based on user preferences
  Future<List<TimeSlot>> suggestMeetingTimes({
    required Duration duration,
    DateTime? preferredDate,
    List<String>? participants,
    int suggestions = 3,
  }) async {
    try {
      AppLogger.info('Finding optimal meeting times');

      final targetDate = preferredDate ?? DateTime.now().add(const Duration(days: 1));
      final userPreferredHour = UserProfile.instance.preferredMeetingHour;
      final (workStart, workEnd) = UserProfile.instance.workHours;

      // Get existing events for the day
      final existingEvents = await CalendarService.instance.getEventsInRange(
        DateTime(targetDate.year, targetDate.month, targetDate.day, 0),
        DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59),
      );

      // Find free slots
      final freeSlots = _findFreeSlots(
        existingEvents,
        targetDate,
        duration,
        workStart,
        workEnd,
      );

      // Rank slots by user preference
      final rankedSlots = _rankSlots(freeSlots, userPreferredHour);

      return rankedSlots.take(suggestions).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error suggesting meeting times', e, stackTrace);
      return [];
    }
  }

  /// Find free time slots
  List<TimeSlot> _findFreeSlots(
    List<CalendarEvent> existingEvents,
    DateTime date,
    Duration duration,
    int workStart,
    int workEnd,
  ) {
    final slots = <TimeSlot>[];

    // Sort events by start time
    final sorted = existingEvents..sort((a, b) => a.startTime.compareTo(b.startTime));

    var currentTime = DateTime(date.year, date.month, date.day, workStart);
    final endOfDay = DateTime(date.year, date.month, date.day, workEnd);

    for (final event in sorted) {
      // Check gap before this event
      if (event.startTime.difference(currentTime) >= duration) {
        slots.add(TimeSlot(
          start: currentTime,
          end: event.startTime,
          duration: event.startTime.difference(currentTime),
        ));
      }
      currentTime = event.endTime;
    }

    // Check gap after last event
    if (endOfDay.difference(currentTime) >= duration) {
      slots.add(TimeSlot(
        start: currentTime,
        end: endOfDay,
        duration: endOfDay.difference(currentTime),
      ));
    }

    return slots;
  }

  /// Rank slots by user preference
  List<TimeSlot> _rankSlots(List<TimeSlot> slots, int preferredHour) {
    return slots..sort((a, b) {
      // Prefer slots closer to user's preferred hour
      final aDistanceToPreferred = (a.start.hour - preferredHour).abs();
      final bDistanceToPreferred = (b.start.hour - preferredHour).abs();

      if (aDistanceToPreferred != bDistanceToPreferred) {
        return aDistanceToPreferred.compareTo(bDistanceToPreferred);
      }

      // Prefer earlier in the day if equal distance
      return a.start.compareTo(b.start);
    });
  }

  /// Auto-schedule meeting with best time
  Future<CalendarEvent?> autoScheduleMeeting({
    required String title,
    required Duration duration,
    DateTime? preferredDate,
    String? description,
    String? location,
    List<String>? attendees,
  }) async {
    try {
      // Find best time
      final suggestions = await suggestMeetingTimes(
        duration: duration,
        preferredDate: preferredDate,
        participants: attendees,
        suggestions: 1,
      );

      if (suggestions.isEmpty) {
        AppLogger.warning('No available time slots found');
        return null;
      }

      final bestSlot = suggestions.first;

      // Create event
      final event = CalendarEvent(
        title: title,
        description: description,
        startTime: bestSlot.start,
        endTime: bestSlot.start.add(duration),
        location: location,
        attendees: attendees,
      );

      return await CalendarService.instance.createEvent(event);
    } catch (e, stackTrace) {
      AppLogger.error('Error auto-scheduling meeting', e, stackTrace);
      return null;
    }
  }

  /// Suggest rescheduling for conflicting events
  Future<String> suggestReschedule(CalendarEvent event) async {
    final suggestions = await suggestMeetingTimes(
      duration: event.duration,
      preferredDate: event.startTime,
    );

    if (suggestions.isEmpty) {
      return 'No alternative times available. Consider a different day?';
    }

    final alternatives = suggestions.map((slot) {
      return '• ${_formatTime(slot.start)} - ${_formatTime(slot.start.add(event.duration))}';
    }).join('\n');

    return 'Here are some alternative times:\n$alternatives';
  }

  /// Check if meeting should be scheduled
  Future<SchedulingRecommendation> getSchedulingRecommendation({
    required DateTime proposedTime,
    required Duration duration,
  }) async {
    final profile = UserProfile.instance;

    // Check if user is overbooked
    final meetingsToday = await _getMeetingsForDay(proposedTime);
    if (meetingsToday.length >= profile.maxMeetingsPerDay) {
      return SchedulingRecommendation(
        shouldSchedule: false,
        reason: 'You have ${meetingsToday.length} meetings today. Consider tomorrow?',
        confidence: 0.9,
      );
    }

    // Check for breaks
    final lastBreak = await _getLastBreakTime();
    if (lastBreak != null) {
      final timeSinceBreak = proposedTime.difference(lastBreak);
      if (timeSinceBreak < const Duration(hours: 3)) {
        return SchedulingRecommendation(
          shouldSchedule: true,
          reason: 'Good time! You had a break ${_formatDuration(timeSinceBreak)} ago.',
          confidence: 0.8,
          suggestion: null,
        );
      } else {
        return SchedulingRecommendation(
          shouldSchedule: true,
          reason: 'You haven\'t had a break in ${_formatDuration(timeSinceBreak)}.',
          confidence: 0.6,
          suggestion: 'Consider a 15-min break before this meeting?',
        );
      }
    }

    // Check if personal time
    if (!profile.shouldScheduleMeetingAt(proposedTime)) {
      return SchedulingRecommendation(
        shouldSchedule: false,
        reason: 'This is outside your preferred meeting hours.',
        confidence: 0.7,
      );
    }

    return SchedulingRecommendation(
      shouldSchedule: true,
      reason: 'Looks good!',
      confidence: 0.9,
    );
  }

  Future<List<CalendarEvent>> _getMeetingsForDay(DateTime day) async {
    final events = await CalendarService.instance.getEventsInRange(
      DateTime(day.year, day.month, day.day, 0),
      DateTime(day.year, day.month, day.day, 23, 59),
    );
    return events;
  }

  Future<DateTime?> _getLastBreakTime() async {
    // In production, track actual break times
    // For now, return null
    return null;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

class TimeSlot {
  final DateTime start;
  final DateTime end;
  final Duration duration;

  TimeSlot({
    required this.start,
    required this.end,
    required this.duration,
  });

  @override
  String toString() => '${start.hour}:${start.minute.toString().padLeft(2, '0')} - ${end.hour}:${end.minute.toString().padLeft(2, '0')}';
}

class SchedulingRecommendation {
  final bool shouldSchedule;
  final String reason;
  final double confidence;
  final String? suggestion;

  SchedulingRecommendation({
    required this.shouldSchedule,
    required this.reason,
    required this.confidence,
    this.suggestion,
  });
}
