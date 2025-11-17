import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Cat Fact model
class CatFact {
  final String fact;
  final int length;

  CatFact({
    required this.fact,
    required this.length,
  });

  factory CatFact.fromJson(Map<String, dynamic> json) => CatFact(
        fact: json['fact'] ?? '',
        length: json['length'] ?? 0,
      );
}

/// Cat Facts Service
/// Provides fun and interesting facts about cats
/// FREE API - No API key required!
/// API: https://catfact.ninja/
class CatFactsService {
  static final CatFactsService _instance = CatFactsService._internal();
  static CatFactsService get instance => _instance;

  CatFactsService._internal();

  static const String _baseUrl = 'https://catfact.ninja';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Cache
  final List<CatFact> _cachedFacts = [];
  DateTime? _lastFetch;

  Future<void> init() async {
    try {
      AppLogger.info('Initializing Cat Facts Service...');

      // Pre-fetch some facts
      await _fetchFacts();

      _isInitialized = true;
      AppLogger.info('Cat Facts Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Cat Facts Service', e, stackTrace);
    }
  }

  /// Get a random cat fact
  Future<CatFact?> getRandomFact() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fact'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fact = CatFact.fromJson(data);

        // Add to cache
        if (!_cachedFacts.any((f) => f.fact == fact.fact)) {
          _cachedFacts.add(fact);
          if (_cachedFacts.length > 50) {
            _cachedFacts.removeAt(0);
          }
        }

        return fact;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch cat fact', e, stackTrace);

      // Return cached fact if available
      if (_cachedFacts.isNotEmpty) {
        _cachedFacts.shuffle();
        return _cachedFacts.first;
      }
    }
    return null;
  }

  /// Get multiple random cat facts
  Future<List<CatFact>> getMultipleFacts({int count = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/facts?limit=$count'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final factsData = data['data'] as List;
        return factsData.map((json) => CatFact.fromJson(json)).toList();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch cat facts', e, stackTrace);
    }

    return [];
  }

  /// Fetch and cache facts
  Future<void> _fetchFacts() async {
    final facts = await getMultipleFacts(count: 10);
    _cachedFacts.addAll(facts);
    _lastFetch = DateTime.now();
  }

  /// Get a formatted cat fact for display
  Future<String> getCatFactSummary() async {
    final fact = await getRandomFact();

    if (fact != null) {
      return '🐱 Cat Fact:\n\n${fact.fact}';
    }

    return '🐱 Unable to fetch cat fact at the moment. Meow later!';
  }

  /// Get help message
  String getHelp() {
    return '''
🐱 Cat Facts Help:

Get random cat facts and learn about our feline friends!

Commands:
• "Tell me a cat fact"
• "Random cat fact"
• "Cat trivia"

Examples:
• "Give me a cat fact"
• "Tell me something about cats"
''';
  }
}
