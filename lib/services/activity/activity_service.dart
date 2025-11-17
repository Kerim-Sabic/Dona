import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Activity suggestion model
class ActivitySuggestion {
  final String activity;
  final String type;
  final int participants;
  final double price; // 0.0 to 1.0
  final String accessibility; // How accessible (0.0 easy to 1.0 hard)
  final String? link;
  final String key;

  ActivitySuggestion({
    required this.activity,
    required this.type,
    required this.participants,
    required this.price,
    required this.accessibility,
    this.link,
    required this.key,
  });

  factory ActivitySuggestion.fromJson(Map<String, dynamic> json) {
    return ActivitySuggestion(
      activity: json['activity'] ?? '',
      type: json['type'] ?? 'general',
      participants: json['participants'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      accessibility: (json['accessibility'] ?? 0.5).toString(),
      link: json['link'],
      key: json['key']?.toString() ?? '',
    );
  }

  String get priceDescription {
    if (price == 0.0) return 'Free';
    if (price < 0.3) return 'Low cost';
    if (price < 0.7) return 'Moderate cost';
    return 'High cost';
  }

  String get accessibilityDescription {
    final accessNum = double.tryParse(accessibility) ?? 0.5;
    if (accessNum < 0.3) return 'Very accessible';
    if (accessNum < 0.7) return 'Moderately accessible';
    return 'Challenging';
  }
}

/// Free Activity Suggestions API Service
/// Uses Bored API (https://www.boredapi.com/) - No API key required!
class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  static ActivityService get instance => _instance;

  ActivityService._internal();

  static const String _baseUrl = 'https://www.boredapi.com/api';
  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('ActivityService initialized with Bored API');
  }

  /// Get a random activity suggestion
  Future<ActivitySuggestion?> getRandomActivity() async {
    try {
      AppLogger.debug('Fetching random activity...');

      final url = Uri.parse('$_baseUrl/activity');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivitySuggestion.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random activity', e, stackTrace);
      return _getMockActivity();
    }
  }

  /// Get activity by type
  Future<ActivitySuggestion?> getActivityByType(String type) async {
    try {
      AppLogger.debug('Fetching $type activity...');

      final url = Uri.parse('$_baseUrl/activity?type=$type');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivitySuggestion.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch $type activity', e, stackTrace);
      return null;
    }
  }

  /// Get activity by number of participants
  Future<ActivitySuggestion?> getActivityByParticipants(int participants) async {
    try {
      AppLogger.debug('Fetching activity for $participants participants...');

      final url = Uri.parse('$_baseUrl/activity?participants=$participants');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivitySuggestion.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch activity for $participants participants', e, stackTrace);
      return null;
    }
  }

  /// Get free or low-cost activity
  Future<ActivitySuggestion?> getFreeActivity() async {
    try {
      AppLogger.debug('Fetching free activity...');

      final url = Uri.parse('$_baseUrl/activity?price=0');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivitySuggestion.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch free activity', e, stackTrace);
      return null;
    }
  }

  /// Get educational activity
  Future<ActivitySuggestion?> getEducationalActivity() => getActivityByType('education');

  /// Get recreational activity
  Future<ActivitySuggestion?> getRecreationalActivity() => getActivityByType('recreational');

  /// Get social activity
  Future<ActivitySuggestion?> getSocialActivity() => getActivityByType('social');

  /// Get relaxation activity
  Future<ActivitySuggestion?> getRelaxationActivity() => getActivityByType('relaxation');

  /// Get charity activity
  Future<ActivitySuggestion?> getCharityActivity() => getActivityByType('charity');

  /// Get cooking activity
  Future<ActivitySuggestion?> getCookingActivity() => getActivityByType('cooking');

  ActivitySuggestion _getMockActivity() {
    return ActivitySuggestion(
      activity: 'Take a walk in the park and observe nature',
      type: 'relaxation',
      participants: 1,
      price: 0.0,
      accessibility: '0.1',
      key: 'mock123',
    );
  }
}
