import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Joke model
class Joke {
  final String setup;
  final String punchline;
  final String type;
  final int id;

  Joke({
    required this.setup,
    required this.punchline,
    required this.type,
    this.id = 0,
  });

  factory Joke.fromJson(Map<String, dynamic> json) {
    // Handle different API response formats
    if (json.containsKey('setup') && json.containsKey('punchline')) {
      return Joke(
        setup: json['setup'] ?? '',
        punchline: json['punchline'] ?? json['delivery'] ?? '',
        type: json['type'] ?? 'general',
        id: json['id'] ?? 0,
      );
    } else if (json.containsKey('joke')) {
      // Single-part joke
      final jokeText = json['joke'] as String;
      final parts = jokeText.split('?');
      return Joke(
        setup: parts.isNotEmpty ? parts[0] + '?' : jokeText,
        punchline: parts.length > 1 ? parts[1].trim() : '',
        type: json['category'] ?? 'general',
        id: json['id'] ?? 0,
      );
    }
    return Joke(
      setup: json.toString(),
      punchline: '',
      type: 'general',
      id: 0,
    );
  }

  String get fullJoke => punchline.isEmpty ? setup : '$setup\n$punchline';
}

/// Free Jokes API Service
/// Uses Official Joke API (https://official-joke-api.appspot.com/) - No API key required!
class JokesService {
  static final JokesService _instance = JokesService._internal();
  static JokesService get instance => _instance;

  JokesService._internal();

  static const String _baseUrl = 'https://official-joke-api.appspot.com';
  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('JokesService initialized with Official Joke API');
  }

  /// Get a random joke
  Future<Joke?> getRandomJoke() async {
    try {
      AppLogger.debug('Fetching random joke...');

      final url = Uri.parse('$_baseUrl/random_joke');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Joke.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random joke', e, stackTrace);
      return _getMockJoke();
    }
  }

  /// Get multiple random jokes
  Future<List<Joke>> getRandomJokes({int count = 5}) async {
    try {
      AppLogger.debug('Fetching $count random jokes...');

      final url = Uri.parse('$_baseUrl/random_ten');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.take(count).map((json) => Joke.fromJson(json)).toList();
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random jokes', e, stackTrace);
      return [];
    }
  }

  /// Get joke by type
  Future<List<Joke>> getJokesByType(String type) async {
    try {
      AppLogger.debug('Fetching $type jokes...');

      final url = Uri.parse('$_baseUrl/jokes/$type/random');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Joke.fromJson(json)).toList();
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch $type jokes', e, stackTrace);
      return [];
    }
  }

  /// Get programming jokes
  Future<List<Joke>> getProgrammingJokes() => getJokesByType('programming');

  /// Get general jokes
  Future<List<Joke>> getGeneralJokes() => getJokesByType('general');

  /// Get knock-knock jokes
  Future<List<Joke>> getKnockKnockJokes() => getJokesByType('knock-knock');

  Joke _getMockJoke() {
    return Joke(
      setup: 'Why don\'t scientists trust atoms?',
      punchline: 'Because they make up everything!',
      type: 'general',
      id: 0,
    );
  }
}
