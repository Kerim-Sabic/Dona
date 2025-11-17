import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Astronomy Picture model
class AstronomyPicture {
  final String title;
  final String explanation;
  final String url;
  final String? hdurl;
  final String mediaType;
  final DateTime date;
  final String? copyright;

  AstronomyPicture({
    required this.title,
    required this.explanation,
    required this.url,
    this.hdurl,
    required this.mediaType,
    required this.date,
    this.copyright,
  });

  factory AstronomyPicture.fromJson(Map<String, dynamic> json) =>
      AstronomyPicture(
        title: json['title'] ?? '',
        explanation: json['explanation'] ?? '',
        url: json['url'] ?? '',
        hdurl: json['hdurl'],
        mediaType: json['media_type'] ?? 'image',
        date: DateTime.parse(json['date']),
        copyright: json['copyright'],
      );
}

/// Astronomy Service
/// Provides NASA's Astronomy Picture of the Day
/// FREE API - No API key required for demo usage!
/// API: https://api.nasa.gov/
class AstronomyService {
  static final AstronomyService _instance = AstronomyService._internal();
  static AstronomyService get instance => _instance;

  AstronomyService._internal();

  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';
  // Using DEMO_KEY for demo purposes (limited to 30 requests/hour, 50/day)
  // For production, get a free API key at https://api.nasa.gov/
  static const String _apiKey = 'DEMO_KEY';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Cache
  AstronomyPicture? _cachedPicture;
  DateTime? _lastFetch;

  Future<void> init() async {
    try {
      AppLogger.info('Initializing Astronomy Service...');

      // Pre-fetch today's picture
      await getPictureOfTheDay();

      _isInitialized = true;
      AppLogger.info('Astronomy Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Astronomy Service', e, stackTrace);
    }
  }

  /// Get Astronomy Picture of the Day
  Future<AstronomyPicture?> getPictureOfTheDay() async {
    try {
      // Check cache (refresh daily)
      if (_cachedPicture != null && _lastFetch != null) {
        final now = DateTime.now();
        if (_lastFetch!.year == now.year &&
            _lastFetch!.month == now.month &&
            _lastFetch!.day == now.day) {
          return _cachedPicture;
        }
      }

      final response = await http.get(
        Uri.parse('$_baseUrl?api_key=$_apiKey'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final picture = AstronomyPicture.fromJson(data);

        _cachedPicture = picture;
        _lastFetch = DateTime.now();

        return picture;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch astronomy picture', e, stackTrace);

      // Return cached picture if available
      if (_cachedPicture != null) {
        return _cachedPicture;
      }
    }
    return null;
  }

  /// Get picture from specific date
  Future<AstronomyPicture?> getPictureByDate(DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('$_baseUrl?api_key=$_apiKey&date=$dateStr'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AstronomyPicture.fromJson(data);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch astronomy picture by date', e,
          stackTrace);
    }
    return null;
  }

  /// Get random picture from the past
  Future<AstronomyPicture?> getRandomPicture() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?api_key=$_apiKey&count=1'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          return AstronomyPicture.fromJson(data[0]);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random astronomy picture', e,
          stackTrace);
    }
    return null;
  }

  /// Get formatted astronomy picture summary
  Future<String> getAstronomySummary() async {
    final picture = await getPictureOfTheDay();

    if (picture != null) {
      final buffer = StringBuffer('🌌 Astronomy Picture of the Day\n\n');
      buffer.writeln('📅 ${_formatDate(picture.date)}');
      buffer.writeln('');
      buffer.writeln('📸 ${picture.title}');
      buffer.writeln('');

      // Truncate explanation if too long
      var explanation = picture.explanation;
      if (explanation.length > 300) {
        explanation = '${explanation.substring(0, 300)}...';
      }
      buffer.writeln(explanation);
      buffer.writeln('');

      if (picture.copyright != null) {
        buffer.writeln('©️ ${picture.copyright}');
      }

      buffer.writeln('');
      buffer.writeln('🔗 View image: ${picture.url}');

      return buffer.toString();
    }

    return '🌌 Unable to fetch astronomy picture at the moment.';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Get help message
  String getHelp() {
    return '''
🌌 Astronomy Service Help:

Explore space with NASA's Astronomy Picture of the Day!

Commands:
• "Astronomy picture of the day"
• "Space picture"
• "NASA picture"
• "Show me space"

Examples:
• "What's today's astronomy picture?"
• "Show me a picture from space"
• "NASA photo of the day"

Note: Images are updated daily by NASA
''';
  }
}
