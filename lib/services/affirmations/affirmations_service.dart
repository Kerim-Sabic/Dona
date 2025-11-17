import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Affirmation model
class Affirmation {
  final String text;

  Affirmation({required this.text});

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(
      text: json['affirmation'] ?? json['text'] ?? '',
    );
  }
}

/// Free Affirmations API Service
/// Uses Affirmations API (https://www.affirmations.dev/) - No API key required!
class AffirmationsService {
  static final AffirmationsService _instance = AffirmationsService._internal();
  static AffirmationsService get instance => _instance;

  AffirmationsService._internal();

  static const String _baseUrl = 'https://www.affirmations.dev';
  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('AffirmationsService initialized');
  }

  /// Get random affirmation
  Future<Affirmation?> getRandomAffirmation() async {
    try {
      AppLogger.debug('Fetching random affirmation...');

      final url = Uri.parse(_baseUrl);
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Affirmation.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random affirmation', e, stackTrace);
      return _getMockAffirmation();
    }
  }

  Affirmation _getMockAffirmation() {
    return Affirmation(
      text: 'I am capable of achieving great things. I am worthy of success and happiness.',
    );
  }
}
