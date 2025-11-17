import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Dad Joke model
class DadJoke {
  final String id;
  final String joke;

  DadJoke({
    required this.id,
    required this.joke,
  });

  factory DadJoke.fromJson(Map<String, dynamic> json) => DadJoke(
        id: json['id'] ?? '',
        joke: json['joke'] ?? '',
      );
}

/// Dad Jokes Service
/// Provides family-friendly dad jokes
/// FREE API - No API key required!
/// API: https://icanhazdadjoke.com/
class DadJokesService {
  static final DadJokesService _instance = DadJokesService._internal();
  static DadJokesService get instance => _instance;

  DadJokesService._internal();

  static const String _baseUrl = 'https://icanhazdadjoke.com';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Cache
  final List<DadJoke> _cachedJokes = [];

  Future<void> init() async {
    try {
      AppLogger.info('Initializing Dad Jokes Service...');

      // Pre-fetch some jokes
      await _fetchJokes();

      _isInitialized = true;
      AppLogger.info('Dad Jokes Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Dad Jokes Service', e, stackTrace);
    }
  }

  /// Get a random dad joke
  Future<DadJoke?> getRandomJoke() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Dona AI (https://github.com/Kerim-Sabic/Dona)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final joke = DadJoke.fromJson(data);

        // Add to cache
        if (!_cachedJokes.any((j) => j.id == joke.id)) {
          _cachedJokes.add(joke);
          if (_cachedJokes.length > 100) {
            _cachedJokes.removeAt(0);
          }
        }

        return joke;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch dad joke', e, stackTrace);

      // Return cached joke if available
      if (_cachedJokes.isNotEmpty) {
        _cachedJokes.shuffle();
        return _cachedJokes.first;
      }
    }
    return null;
  }

  /// Search for jokes by term
  Future<List<DadJoke>> searchJokes(String term) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?term=${Uri.encodeComponent(term)}'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Dona AI (https://github.com/Kerim-Sabic/Dona)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => DadJoke.fromJson(json)).toList();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search dad jokes', e, stackTrace);
    }

    return [];
  }

  /// Fetch and cache jokes
  Future<void> _fetchJokes() async {
    // Fetch a few random jokes
    for (int i = 0; i < 5; i++) {
      final joke = await getRandomJoke();
      if (joke != null) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// Get a formatted dad joke for display
  Future<String> getDadJokeSummary() async {
    final joke = await getRandomJoke();

    if (joke != null) {
      return '👨 Dad Joke:\n\n${joke.joke}';
    }

    return '👨 No dad jokes available right now. Try again later!';
  }

  /// Get help message
  String getHelp() {
    return '''
👨 Dad Jokes Help:

Get family-friendly dad jokes to brighten your day!

Commands:
• "Tell me a dad joke"
• "Random dad joke"
• "Dad joke"

Examples:
• "Give me a dad joke"
• "I need a dad joke"
• "Tell me something funny"
''';
  }
}
