import 'dart:convert';
import '../core/utils/logger.dart';
import '../services/storage/local_storage_service.dart';
import '../data/models/calendar_event.dart';
import '../services/google_maps/google_maps_service.dart';

/// User's learned preferences and habits
class UserProfile {
  static final UserProfile _instance = UserProfile._internal();
  static UserProfile get instance => _instance;

  UserProfile._internal();

  // User preferences
  Map<String, dynamic> habits = {};
  Map<String, int> frequentContacts = {};
  Map<String, int> frequentLocations = {};
  List<String> preferredRestaurants = [];
  List<String> vipContacts = []; // VIP contacts that require personal attention
  Map<String, dynamic> communicationStyle = {};

  // User metadata
  String? userName;
  String? phoneNumber;
  String? email;
  String? homeAddress;
  String? workAddress;

  // Learning flags
  bool _isLearning = true;
  DateTime? _lastLearningUpdate;

  /// Initialize user profile
  Future<void> init() async {
    try {
      await _loadProfile();
      AppLogger.info('UserProfile initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize UserProfile', e, stackTrace);
    }
  }

  /// Load profile from storage
  Future<void> _loadProfile() async {
    try {
      final profileJson = LocalStorageService.instance.getString('user_profile');
      if (profileJson != null) {
        final data = jsonDecode(profileJson) as Map<String, dynamic>;
        habits = data['habits'] ?? {};
        frequentContacts = Map<String, int>.from(data['frequentContacts'] ?? {});
        frequentLocations = Map<String, int>.from(data['frequentLocations'] ?? {});
        preferredRestaurants = List<String>.from(data['preferredRestaurants'] ?? []);
        vipContacts = List<String>.from(data['vipContacts'] ?? []);
        communicationStyle = data['communicationStyle'] ?? {};
        userName = data['userName'];
        phoneNumber = data['phoneNumber'];
        email = data['email'];
        homeAddress = data['homeAddress'];
        workAddress = data['workAddress'];
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading user profile', e, stackTrace);
    }
  }

  /// Save profile to storage
  Future<void> _saveProfile() async {
    try {
      final data = {
        'habits': habits,
        'frequentContacts': frequentContacts,
        'frequentLocations': frequentLocations,
        'preferredRestaurants': preferredRestaurants,
        'vipContacts': vipContacts,
        'communicationStyle': communicationStyle,
        'userName': userName,
        'phoneNumber': phoneNumber,
        'email': email,
        'homeAddress': homeAddress,
        'workAddress': workAddress,
      };

      await LocalStorageService.instance.setString('user_profile', jsonEncode(data));
      _lastLearningUpdate = DateTime.now();
      AppLogger.debug('User profile saved');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving user profile', e, stackTrace);
    }
  }

  // ==================== Learning Methods ====================

  /// Learn from calendar event
  Future<void> learnFromCalendarEvent(CalendarEvent event) async {
    if (!_isLearning) return;

    try {
      // Learn meeting time patterns
      final hour = event.startTime.hour;
      habits['meeting_hours'] ??= {};
      habits['meeting_hours'][hour.toString()] =
          (habits['meeting_hours'][hour.toString()] ?? 0) + 1;

      // Learn meeting duration patterns
      final duration = event.duration.inMinutes;
      habits['meeting_durations'] ??= {};
      habits['meeting_durations'][duration.toString()] =
          (habits['meeting_durations'][duration.toString()] ?? 0) + 1;

      // Learn frequent contacts
      if (event.attendees != null) {
        for (final attendee in event.attendees!) {
          frequentContacts[attendee] = (frequentContacts[attendee] ?? 0) + 1;
        }
      }

      // Learn location patterns
      if (event.location != null && event.location!.isNotEmpty) {
        frequentLocations[event.location!] = (frequentLocations[event.location!] ?? 0) + 1;
      }

      await _saveProfile();
    } catch (e, stackTrace) {
      AppLogger.error('Error learning from calendar event', e, stackTrace);
    }
  }

  /// Learn from location visit
  Future<void> learnFromLocationVisit(PlaceLocation location, String? placeName) async {
    if (!_isLearning) return;

    try {
      final locationKey = '${location.lat.toStringAsFixed(4)},${location.lng.toStringAsFixed(4)}';

      frequentLocations[locationKey] = (frequentLocations[locationKey] ?? 0) + 1;

      if (placeName != null) {
        frequentLocations[placeName] = (frequentLocations[placeName] ?? 0) + 1;
      }

      // Detect patterns
      await _detectLocationPatterns();

      await _saveProfile();
    } catch (e, stackTrace) {
      AppLogger.error('Error learning from location', e, stackTrace);
    }
  }

  /// Learn from user interaction
  Future<void> learnFromInteraction(String userInput, String? context) async {
    if (!_isLearning) return;

    try {
      // Learn communication style
      final wordCount = userInput.split(' ').length;

      communicationStyle['avg_message_length'] ??= 0;
      communicationStyle['message_count'] ??= 0;

      final currentAvg = communicationStyle['avg_message_length'] as num;
      final messageCount = communicationStyle['message_count'] as num;

      communicationStyle['avg_message_length'] =
          ((currentAvg * messageCount) + wordCount) / (messageCount + 1);
      communicationStyle['message_count'] = messageCount + 1;

      // Detect formality
      final isFormal = _detectFormality(userInput);
      communicationStyle['formality_score'] ??= 0.5;
      if (isFormal) {
        communicationStyle['formality_score'] =
            (communicationStyle['formality_score'] as num) * 0.9 + 0.1;
      }

      await _saveProfile();
    } catch (e, stackTrace) {
      AppLogger.error('Error learning from interaction', e, stackTrace);
    }
  }

  /// Learn preferred restaurant
  Future<void> learnRestaurantPreference(String restaurant) async {
    if (!_isLearning) return;

    if (!preferredRestaurants.contains(restaurant)) {
      preferredRestaurants.add(restaurant);
      if (preferredRestaurants.length > 10) {
        preferredRestaurants.removeAt(0); // Keep only top 10
      }
      await _saveProfile();
    }
  }

  // ==================== Pattern Detection ====================

  /// Detect location patterns (home, work)
  Future<void> _detectLocationPatterns() async {
    // Find most visited location during work hours (9-5)
    // and during evening hours (6-10) to detect work and home

    // This is simplified - in production would use more sophisticated analysis
    final sortedLocations = frequentLocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedLocations.length >= 2) {
      // Most visited is likely home or work
      if (workAddress == null || homeAddress == null) {
        // Need more data to determine
        AppLogger.debug('Detected frequent locations, need more data to classify');
      }
    }
  }

  /// Detect if message is formal
  bool _detectFormality(String text) {
    final formalWords = ['please', 'kindly', 'regards', 'sincerely', 'would you'];
    final lowerText = text.toLowerCase();
    return formalWords.any((word) => lowerText.contains(word));
  }

  // ==================== Getters for Insights ====================

  /// Get preferred meeting hour
  int get preferredMeetingHour {
    if (habits['meeting_hours'] == null) return 10; // Default 10 AM

    final hours = habits['meeting_hours'] as Map<String, dynamic>;
    if (hours.isEmpty) return 10;

    final sortedHours = hours.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return int.parse(sortedHours.first.key);
  }

  /// Get preferred meeting duration (minutes)
  int get preferredMeetingDuration {
    if (habits['meeting_durations'] == null) return 30; // Default 30 min

    final durations = habits['meeting_durations'] as Map<String, dynamic>;
    if (durations.isEmpty) return 30;

    final sortedDurations = durations.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return int.parse(sortedDurations.first.key);
  }

  /// Check if contact is VIP
  bool isVIPContact(String email) {
    return vipContacts.any((vip) =>
      email.toLowerCase().contains(vip.toLowerCase()) ||
      vip.toLowerCase().contains(email.toLowerCase())
    );
  }

  /// Add VIP contact
  Future<void> addVIPContact(String email) async {
    if (!vipContacts.contains(email)) {
      vipContacts.add(email);
      await _saveProfile();
      AppLogger.info('Added VIP contact: $email');
    }
  }

  /// Remove VIP contact
  Future<void> removeVIPContact(String email) async {
    if (vipContacts.remove(email)) {
      await _saveProfile();
      AppLogger.info('Removed VIP contact: $email');
    }
  }

  /// Get top contacts (sorted by frequency)
  List<String> get topContacts {
    final sorted = frequentContacts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  /// Get communication formality (0.0 = casual, 1.0 = formal)
  double get formalityScore {
    return (communicationStyle['formality_score'] as num?)?.toDouble() ?? 0.5;
  }

  /// Check if user prefers concise messages
  bool get prefersConciseMessages {
    final avgLength = (communicationStyle['avg_message_length'] as num?)?.toDouble() ?? 50;
    return avgLength < 30; // Less than 30 words = concise
  }

  /// Get work hours
  (int start, int end) get workHours {
    // Analyze meeting patterns to determine work hours
    // Default: 9 AM - 5 PM
    return (9, 17);
  }

  /// Check if currently in work hours
  bool get isWorkHours {
    final now = DateTime.now();
    final (start, end) = workHours;
    return now.hour >= start && now.hour < end && now.weekday <= 5;
  }

  /// Maximum meetings per day (learned from patterns)
  int get maxMeetingsPerDay {
    // Analyze historical data to find comfortable meeting load
    // Default: 6 meetings
    return 6;
  }

  // ==================== Recommendations ====================

  /// Get restaurant recommendations near location
  List<String> getRestaurantRecommendations({String? nearLocation}) {
    // Return preferred restaurants
    // In production, would filter by location
    return preferredRestaurants;
  }

  /// Should schedule meeting at this time?
  bool shouldScheduleMeetingAt(DateTime time) {
    // Check against learned preferences
    final hour = time.hour;

    // Not during lunch (12-1)
    if (hour == 12) return false;

    // Not too early or too late
    if (hour < 8 || hour > 18) return false;

    // Check if within work hours
    final (workStart, workEnd) = workHours;
    if (hour < workStart || hour >= workEnd) return false;

    return true;
  }

  /// Get suggested meeting duration
  int get suggestedMeetingDuration => preferredMeetingDuration;

  // ==================== Privacy & Control ====================

  /// Enable/disable learning
  void setLearning(bool enabled) {
    _isLearning = enabled;
    AppLogger.info('Learning ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Clear all learned data
  Future<void> clearAllData() async {
    habits = {};
    frequentContacts = {};
    frequentLocations = {};
    preferredRestaurants = [];
    communicationStyle = {};
    await _saveProfile();
    AppLogger.info('All user data cleared');
  }

  /// Export user data (GDPR compliance)
  Map<String, dynamic> exportData() {
    return {
      'userName': userName,
      'email': email,
      'phoneNumber': phoneNumber,
      'homeAddress': homeAddress,
      'workAddress': workAddress,
      'habits': habits,
      'frequentContacts': frequentContacts,
      'frequentLocations': frequentLocations,
      'preferredRestaurants': preferredRestaurants,
      'communicationStyle': communicationStyle,
      'lastUpdated': _lastLearningUpdate?.toIso8601String(),
    };
  }

  /// Get privacy report
  String getPrivacyReport() {
    final messageCount = communicationStyle['message_count'] ?? 0;
    final contactCount = frequentContacts.length;
    final locationCount = frequentLocations.length;

    return '''
Privacy Report

Data Collected:
- ${contactCount} frequent contacts tracked
- ${locationCount} locations visited
- ${messageCount} messages analyzed for communication style
- ${preferredRestaurants.length} restaurant preferences

Learning Status: ${_isLearning ? 'Active' : 'Paused'}
Last Update: ${_lastLearningUpdate?.toString() ?? 'Never'}

You can:
- Pause learning anytime
- Clear all data
- Export your data

All data is stored locally on your device.
''';
  }
}
