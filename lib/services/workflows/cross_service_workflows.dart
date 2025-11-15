import '../../core/utils/logger.dart';
import '../calendar/calendar_service.dart';
import '../gmail/gmail_service.dart';
import '../google_drive/google_drive_service.dart';
import '../google_maps/google_maps_service.dart';
import '../weather/weather_service.dart';
import '../ai/ai_service.dart';
import '../../data/models/calendar_event.dart';

/// Cross-Service Workflows
///
/// Combines multiple services to complete complex tasks
class CrossServiceWorkflows {
  static final CrossServiceWorkflows _instance = CrossServiceWorkflows._internal();
  static CrossServiceWorkflows get instance => _instance;

  CrossServiceWorkflows._internal();

  /// Prepare for meeting: emails + documents + context
  Future<MeetingPreparation> prepareMeeting(CalendarEvent meeting) async {
    try {
      AppLogger.info('Preparing for meeting: ${meeting.title}');

      // 1. Search related emails
      final emails = <EmailMessage>[];
      if (meeting.attendees != null && meeting.attendees!.isNotEmpty) {
        for (final attendee in meeting.attendees!) {
          // Search Gmail for emails with this person
          // In production: implement email search
        }
      }

      // 2. Find related documents in Drive
      final documents = await GoogleDriveService.instance.searchFiles(meeting.title);

      // 3. Get last meeting notes
      final lastMeetingNotes = await _getLastMeetingNotes(meeting.attendees ?? []);

      // 4. Generate AI briefing
      final briefing = await _generateMeetingBrief(
        meeting: meeting,
        emails: emails,
        documents: documents,
        lastNotes: lastMeetingNotes,
      );

      return MeetingPreparation(
        meeting: meeting,
        briefing: briefing,
        relatedEmails: emails,
        relatedDocuments: documents,
        lastMeetingNotes: lastMeetingNotes,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error preparing meeting', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _getLastMeetingNotes(List<String> attendees) async {
    // Search Drive for meeting notes with these attendees
    // For now, return placeholder
    return 'Previous meeting notes not found';
  }

  Future<String> _generateMeetingBrief({
    required CalendarEvent meeting,
    required List<EmailMessage> emails,
    required List<DriveFile> documents,
    required String lastNotes,
  }) async {
    final prompt = '''
Generate a concise meeting briefing:

Meeting: ${meeting.title}
Attendees: ${meeting.attendees?.join(", ") ?? "None"}
Time: ${meeting.startTime}

Recent Emails: ${emails.length} messages
Related Documents: ${documents.map((d) => d.name).join(", ")}
Last Meeting: $lastNotes

Provide:
1. Key discussion points
2. Action items from last meeting
3. Suggested agenda (3-5 items)

Keep it concise and actionable.
''';

    return await AIService.instance.chat(prompt);
  }

  /// Plan trip: calendar + maps + weather
  Future<TripPlan> planTrip({
    required String destination,
    required DateTime departureTime,
    String? purpose,
  }) async {
    try {
      AppLogger.info('Planning trip to $destination');

      // 1. Get directions
      final route = await GoogleMapsService.instance.getDirections(
        origin: 'current_location',
        destination: destination,
      );

      // 2. Check calendar for conflicts
      final departTime = departureTime.subtract(route?.durationSeconds != null
          ? Duration(seconds: route!.durationSeconds)
          : const Duration(hours: 1));

      final conflicts = await _checkCalendarConflicts(departTime, departureTime);

      // 3. Get weather at destination
      final weather = await WeatherService.instance.getCurrentWeather(
        city: destination,
      );

      // 4. Find nearby places (parking, restaurants)
      final nearbyParking = <Place>[];
      final nearbyRestaurants = <Place>[];

      if (route != null) {
        // Search near destination
        // nearbyParking = await GoogleMapsService.instance.searchNearbyPlaces(...);
        // nearbyRestaurants = await GoogleMapsService.instance.searchNearbyPlaces(...);
      }

      // 5. Generate recommendations
      final recommendations = await _generateTripRecommendations(
        destination: destination,
        weather: weather,
        route: route,
      );

      return TripPlan(
        destination: destination,
        departureTime: departTime,
        arrivalTime: departureTime,
        route: route,
        travelDuration: route?.durationSeconds != null
            ? Duration(seconds: route!.durationSeconds)
            : const Duration(hours: 1),
        weather: weather,
        conflicts: conflicts,
        nearbyParking: nearbyParking,
        nearbyRestaurants: nearbyRestaurants,
        recommendations: recommendations,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error planning trip', e, stackTrace);
      rethrow;
    }
  }

  Future<List<CalendarEvent>> _checkCalendarConflicts(
    DateTime start,
    DateTime end,
  ) async {
    final events = await CalendarService.instance.getEventsInRange(start, end);
    return events;
  }

  Future<String> _generateTripRecommendations({
    required String destination,
    required WeatherData? weather,
    required DirectionRoute? route,
  }) async {
    final prompt = '''
Generate trip recommendations:

Destination: $destination
Weather: ${weather?.description ?? 'Unknown'} ${weather?.temperature.toInt() ?? 0}°C
Travel Time: ${route?.durationFormatted ?? 'Unknown'}

Provide:
1. Best time to leave (considering traffic)
2. What to bring (based on weather)
3. Parking suggestions
4. Any alerts or tips

Keep it brief and helpful.
''';

    return await AIService.instance.chat(prompt);
  }

  /// Daily summary: calendar + emails + tasks
  Future<DailySummary> generateDailySummary({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      AppLogger.info('Generating daily summary for ${targetDate.toIso8601String()}');

      // 1. Get calendar events
      final events = await CalendarService.instance.getEventsInRange(
        DateTime(targetDate.year, targetDate.month, targetDate.day, 0),
        DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59),
      );

      // 2. Get unread emails (mock for now)
      final unreadCount = 0; // await GmailService.instance.getUnreadCount();

      // 3. Get pending tasks (mock for now)
      final pendingTasks = 0;

      // 4. Get weather
      final weather = await WeatherService.instance.getCurrentWeather();

      // 5. Generate AI summary
      final aiSummary = await _generateAISummary(
        events: events,
        unreadEmails: unreadCount,
        pendingTasks: pendingTasks,
        weather: weather,
      );

      return DailySummary(
        date: targetDate,
        events: events,
        unreadEmailCount: unreadCount,
        pendingTaskCount: pendingTasks,
        weather: weather,
        aiSummary: aiSummary,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error generating daily summary', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _generateAISummary({
    required List<CalendarEvent> events,
    required int unreadEmails,
    required int pendingTasks,
    required WeatherData? weather,
  }) async {
    final prompt = '''
Generate a warm daily summary:

Calendar: ${events.length} events today
Emails: $unreadEmails unread
Tasks: $pendingTasks pending
Weather: ${weather?.description ?? 'Unknown'} ${weather?.temperature.toInt() ?? 0}°C

Generate a 2-3 sentence summary that:
- Highlights the key things for today
- Is encouraging and motivating
- Sounds like Donna Paulsen

Example: "You have a busy day with 5 meetings, but nothing you can't handle. Check those 12 emails when you have a moment, and the weather is perfect for a lunch walk. Let's make it a great day!"
''';

    return await AIService.instance.chat(prompt);
  }
}

class MeetingPreparation {
  final CalendarEvent meeting;
  final String briefing;
  final List<EmailMessage> relatedEmails;
  final List<DriveFile> relatedDocuments;
  final String lastMeetingNotes;

  MeetingPreparation({
    required this.meeting,
    required this.briefing,
    required this.relatedEmails,
    required this.relatedDocuments,
    required this.lastMeetingNotes,
  });
}

class TripPlan {
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final DirectionRoute? route;
  final Duration travelDuration;
  final WeatherData? weather;
  final List<CalendarEvent> conflicts;
  final List<Place> nearbyParking;
  final List<Place> nearbyRestaurants;
  final String recommendations;

  TripPlan({
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    this.route,
    required this.travelDuration,
    this.weather,
    required this.conflicts,
    required this.nearbyParking,
    required this.nearbyRestaurants,
    required this.recommendations,
  });
}

class DailySummary {
  final DateTime date;
  final List<CalendarEvent> events;
  final int unreadEmailCount;
  final int pendingTaskCount;
  final WeatherData? weather;
  final String aiSummary;

  DailySummary({
    required this.date,
    required this.events,
    required this.unreadEmailCount,
    required this.pendingTaskCount,
    this.weather,
    required this.aiSummary,
  });
}

// Import types from services
typedef EmailMessage = dynamic;
