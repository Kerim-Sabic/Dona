import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Quote model
class Quote {
  final String text;
  final String author;
  final String category;

  Quote({
    required this.text,
    required this.author,
    this.category = 'general',
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['quote'] ?? json['q'] ?? json['content'] ?? '',
      author: json['author'] ?? json['a'] ?? 'Unknown',
      category: json['category'] ?? json['tags']?.first ?? 'general',
    );
  }
}

/// Free Quotes API Service
/// Uses ZenQuotes API (https://zenquotes.io) - No API key required!
class QuotesService {
  static final QuotesService _instance = QuotesService._internal();
  static QuotesService get instance => _instance;

  QuotesService._internal();

  static const String _baseUrl = 'https://zenquotes.io/api';
  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('QuotesService initialized with ZenQuotes API');
  }

  /// Get quote of the day
  Future<Quote?> getQuoteOfTheDay() async {
    try {
      AppLogger.debug('Fetching quote of the day...');

      final url = Uri.parse('$_baseUrl/today');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final quote = Quote.fromJson(data.first);
          AppLogger.info('Fetched quote of the day');
          return quote;
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch quote of the day', e, stackTrace);
      return _getMockQuote();
    }
  }

  /// Get random quote
  Future<Quote?> getRandomQuote() async {
    try {
      AppLogger.debug('Fetching random quote...');

      final url = Uri.parse('$_baseUrl/random');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return Quote.fromJson(data.first);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random quote', e, stackTrace);
      return _getMockQuote();
    }
  }

  /// Get multiple random quotes
  Future<List<Quote>> getRandomQuotes({int count = 5}) async {
    try {
      AppLogger.debug('Fetching $count random quotes...');

      final url = Uri.parse('$_baseUrl/quotes');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.take(count).map((json) => Quote.fromJson(json)).toList();
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random quotes', e, stackTrace);
      return [];
    }
  }

  Quote _getMockQuote() {
    return Quote(
      text: 'The only way to do great work is to love what you do.',
      author: 'Steve Jobs',
      category: 'inspirational',
    );
  }
}
