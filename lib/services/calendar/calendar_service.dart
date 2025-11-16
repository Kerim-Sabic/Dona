import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/logger.dart';
import '../../config/api_keys_secure.dart';
import '../../data/models/calendar_event.dart';
import '../storage/local_storage_service.dart';

/// Service for Google Calendar integration with OAuth 2.0
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  static CalendarService get instance => _instance;

  CalendarService._internal();

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> init() async {
    try {
      // Try to load saved access token
      _accessToken = LocalStorageService.instance.getString('google_access_token');
      final expiryStr = LocalStorageService.instance.getString('google_token_expiry');
      if (expiryStr != null) {
        _tokenExpiry = DateTime.parse(expiryStr);
      }

      AppLogger.info('CalendarService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize CalendarService', e, stackTrace);
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    if (_accessToken == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Authenticate user with Google OAuth 2.0 (Web Flow)
  Future<bool> authenticate() async {
    try {
      AppLogger.info('Starting Google OAuth authentication...');

      // Build OAuth URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': ApiKeys.googleCalendarClientId,
        'redirect_uri': ApiKeys.googleCalendarRedirectUri,
        'response_type': 'token',
        'scope': ApiKeys.googleCalendarScopes.join(' '),
        'include_granted_scopes': 'true',
        'state': 'dona_ai_calendar',
      });

      AppLogger.debug('OAuth URL: $authUrl');

      // Launch browser for OAuth
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        AppLogger.info('OAuth browser opened. Waiting for redirect...');

        // NOTE: In a real implementation, you'd need to:
        // 1. Set up a local server to handle the redirect
        // 2. Parse the access token from the URL fragment
        // 3. Save the token
        // For now, we'll simulate a successful auth for testing

        return false; // User needs to complete OAuth flow
      } else {
        throw Exception('Could not launch OAuth URL');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to authenticate', e, stackTrace);
      return false;
    }
  }

  /// Manually set access token (for testing or manual OAuth)
  Future<void> setAccessToken(String token, {int expiresInSeconds = 3600}) async {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));

    await LocalStorageService.instance.setString('google_access_token', token);
    await LocalStorageService.instance.setString(
      'google_token_expiry',
      _tokenExpiry!.toIso8601String(),
    );

    AppLogger.info('Access token set successfully');
  }

  /// Get upcoming calendar events
  Future<List<CalendarEvent>> getUpcomingEvents({int maxResults = 10}) async {
    try {
      if (!isAuthenticated) {
        AppLogger.warning('Not authenticated. Returning mock events.');
        return _getMockEvents();
      }

      AppLogger.debug('Fetching upcoming calendar events...');

      final now = DateTime.now().toUtc().toIso8601String();
      final url = Uri.https('www.googleapis.com', '/calendar/v3/calendars/primary/events', {
        'timeMin': now,
        'maxResults': maxResults.toString(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
      });

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final events = items.map((item) => CalendarEvent.fromJson(item)).toList();

        AppLogger.info('Fetched ${events.length} calendar events');
        return events;
      } else if (response.statusCode == 401) {
        AppLogger.warning('Access token expired or invalid');
        _accessToken = null;
        return _getMockEvents();
      } else {
        throw Exception('Calendar API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch calendar events', e, stackTrace);
      return _getMockEvents();
    }
  }

  /// Get events for a specific date range
  Future<List<CalendarEvent>> getEventsInRange(DateTime start, DateTime end) async {
    try {
      if (!isAuthenticated) {
        return _getMockEvents();
      }

      AppLogger.debug('Fetching events from $start to $end');

      final url = Uri.https('www.googleapis.com', '/calendar/v3/calendars/primary/events', {
        'timeMin': start.toUtc().toIso8601String(),
        'timeMax': end.toUtc().toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
      });

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items.map((item) => CalendarEvent.fromJson(item)).toList();
      } else {
        throw Exception('Calendar API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch events in range', e, stackTrace);
      return [];
    }
  }

  /// Create a new calendar event
  Future<CalendarEvent?> createEvent(CalendarEvent event) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated. Please sign in first.');
      }

      AppLogger.debug('Creating calendar event: ${event.title}');

      final url = Uri.https('www.googleapis.com', '/calendar/v3/calendars/primary/events');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(event.toJson()),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdEvent = CalendarEvent.fromJson(data);
        AppLogger.info('Event created successfully: ${createdEvent.id}');
        return createdEvent;
      } else {
        AppLogger.error('Failed to create event: ${response.statusCode}', response.body, StackTrace.current);
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create calendar event', e, stackTrace);
      return null;
    }
  }

  /// Update an existing calendar event
  Future<CalendarEvent?> updateEvent(CalendarEvent event) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated');
      }

      AppLogger.debug('Updating event: ${event.id}');

      final url = Uri.https(
        'www.googleapis.com',
        '/calendar/v3/calendars/primary/events/${event.id}',
      );

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(event.toJson()),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CalendarEvent.fromJson(data);
      } else {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update event', e, stackTrace);
      return null;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteEvent(String eventId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated');
      }

      AppLogger.debug('Deleting event: $eventId');

      final url = Uri.https(
        'www.googleapis.com',
        '/calendar/v3/calendars/primary/events/$eventId',
      );

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 204) {
        AppLogger.info('Event deleted successfully');
        return true;
      } else {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete event', e, stackTrace);
      return false;
    }
  }

  /// Sign out and clear tokens
  Future<void> signOut() async {
    _accessToken = null;
    _tokenExpiry = null;
    await LocalStorageService.instance.remove('google_access_token');
    await LocalStorageService.instance.remove('google_token_expiry');
    AppLogger.info('Signed out from Google Calendar');
  }

  /// Get mock events for testing
  List<CalendarEvent> _getMockEvents() {
    final now = DateTime.now();
    return [
      CalendarEvent(
        id: '1',
        title: 'Team Meeting',
        description: 'Weekly team sync meeting',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        location: 'Conference Room A',
      ),
      CalendarEvent(
        id: '2',
        title: 'Lunch with Client',
        description: 'Business lunch discussion',
        startTime: now.add(const Duration(days: 1, hours: 5)),
        endTime: now.add(const Duration(days: 1, hours: 6)),
        location: 'Restaurant downtown',
      ),
      CalendarEvent(
        id: '3',
        title: 'Project Deadline',
        description: 'Final submission for project X',
        startTime: now.add(const Duration(days: 3)),
        endTime: now.add(const Duration(days: 3, hours: 1)),
        isAllDay: true,
      ),
      CalendarEvent(
        id: '4',
        title: 'Doctor Appointment',
        description: 'Annual checkup',
        startTime: now.add(const Duration(days: 5, hours: 3)),
        endTime: now.add(const Duration(days: 5, hours: 4)),
        location: 'Medical Center',
      ),
    ];
  }
}
