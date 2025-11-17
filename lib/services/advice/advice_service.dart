import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Advice model
class Advice {
  final int id;
  final String text;

  Advice({
    required this.id,
    required this.text,
  });

  factory Advice.fromJson(Map<String, dynamic> json) {
    return Advice(
      id: json['id'] ?? json['slip_id'] ?? 0,
      text: json['advice'] ?? json['text'] ?? '',
    );
  }
}

/// Free Advice API Service
/// Uses Advice Slip API (https://api.adviceslip.com/) - No API key required!
class AdviceService {
  static final AdviceService _instance = AdviceService._internal();
  static AdviceService get instance => _instance;

  AdviceService._internal();

  static const String _baseUrl = 'https://api.adviceslip.com/advice';
  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('AdviceService initialized with Advice Slip API');
  }

  /// Get random advice
  Future<Advice?> getRandomAdvice() async {
    try {
      AppLogger.debug('Fetching random advice...');

      final url = Uri.parse(_baseUrl);
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slip = data['slip'];
        return Advice.fromJson(slip);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random advice', e, stackTrace);
      return _getMockAdvice();
    }
  }

  /// Search for advice by keyword
  Future<List<Advice>> searchAdvice(String query) async {
    try {
      AppLogger.debug('Searching advice for: $query');

      final url = Uri.parse('$_baseUrl/search/${Uri.encodeComponent(query)}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['total_results'] != null && data['total_results'] > 0) {
          final List<dynamic> slips = data['slips'];
          return slips.map((slip) => Advice.fromJson(slip)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search advice', e, stackTrace);
      return [];
    }
  }

  Advice _getMockAdvice() {
    return Advice(
      id: 1,
      text: 'Remember that failure is an event, not a person. Keep going!',
    );
  }
}
