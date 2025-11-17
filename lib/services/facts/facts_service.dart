import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Fact model
class Fact {
  final String text;
  final String category;
  final int? id;

  Fact({
    required this.text,
    this.category = 'general',
    this.id,
  });

  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      text: json['fact'] ?? json['text'] ?? json['data'] ?? '',
      category: json['category'] ?? 'general',
      id: json['id'],
    );
  }
}

/// Free Facts API Service
/// Uses multiple free APIs for various types of facts
class FactsService {
  static final FactsService _instance = FactsService._internal();
  static FactsService get instance => _instance;

  FactsService._internal();

  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('FactsService initialized');
  }

  /// Get random interesting fact (using uselessfacts.jsph.pl)
  Future<Fact?> getRandomFact() async {
    try {
      AppLogger.debug('Fetching random fact...');

      final url = Uri.parse('https://uselessfacts.jsph.pl/random.json?language=en');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Fact(
          text: data['text'] ?? '',
          category: 'general',
          id: data['id'] != null ? int.tryParse(data['id'].toString()) : null,
        );
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random fact', e, stackTrace);
      return _getMockFact();
    }
  }

  /// Get fact of the day
  Future<Fact?> getFactOfTheDay() async {
    try {
      AppLogger.debug('Fetching fact of the day...');

      final url = Uri.parse('https://uselessfacts.jsph.pl/today.json?language=en');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Fact(
          text: data['text'] ?? '',
          category: 'daily',
        );
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch fact of the day', e, stackTrace);
      return getRandomFact();
    }
  }

  /// Get random cat fact
  Future<Fact?> getCatFact() async {
    try {
      AppLogger.debug('Fetching cat fact...');

      final url = Uri.parse('https://catfact.ninja/fact');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Fact(
          text: data['fact'] ?? '',
          category: 'cats',
        );
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch cat fact', e, stackTrace);
      return null;
    }
  }

  /// Get random dog fact
  Future<Fact?> getDogFact() async {
    try {
      AppLogger.debug('Fetching dog fact...');

      final url = Uri.parse('https://dogapi.dog/api/v2/facts');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final facts = data['data'] as List<dynamic>;
        if (facts.isNotEmpty) {
          return Fact(
            text: facts.first['attributes']['body'] ?? '',
            category: 'dogs',
          );
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch dog fact', e, stackTrace);
      return null;
    }
  }

  /// Get number trivia
  Future<Fact?> getNumberTrivia(int number) async {
    try {
      AppLogger.debug('Fetching trivia for number: $number');

      final url = Uri.parse('http://numbersapi.com/$number');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        return Fact(
          text: response.body,
          category: 'numbers',
        );
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch number trivia', e, stackTrace);
      return null;
    }
  }

  /// Get random number trivia
  Future<Fact?> getRandomNumberTrivia() async {
    try {
      final url = Uri.parse('http://numbersapi.com/random');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        return Fact(
          text: response.body,
          category: 'numbers',
        );
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random number trivia', e, stackTrace);
      return null;
    }
  }

  /// Get date trivia
  Future<Fact?> getDateTrivia(int month, int day) async {
    try {
      AppLogger.debug('Fetching trivia for date: $month/$day');

      final url = Uri.parse('http://numbersapi.com/$month/$day/date');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        return Fact(
          text: response.body,
          category: 'history',
        );
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch date trivia', e, stackTrace);
      return null;
    }
  }

  Fact _getMockFact() {
    return Fact(
      text: 'Honey never spoils. Archaeologists have found 3000-year-old honey in Egyptian tombs that was still edible!',
      category: 'general',
    );
  }
}
