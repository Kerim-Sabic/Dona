import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Inspirational image model
class InspirationalImage {
  final String url;
  final String? author;
  final int width;
  final int height;

  InspirationalImage({
    required this.url,
    this.author,
    required this.width,
    required this.height,
  });

  factory InspirationalImage.fromJson(Map<String, dynamic> json) {
    return InspirationalImage(
      url: json['download_url'] ?? json['url'] ?? '',
      author: json['author'],
      width: json['width'] ?? 1920,
      height: json['height'] ?? 1080,
    );
  }
}

/// Kanye West Quote model (for humor)
class KanyeQuote {
  final String quote;

  KanyeQuote({required this.quote});

  factory KanyeQuote.fromJson(Map<String, dynamic> json) {
    return KanyeQuote(quote: json['quote'] ?? '');
  }
}

/// Inspirational Content Service
/// Multiple FREE APIs for motivational content
class InspirationService {
  static final InspirationService _instance = InspirationService._internal();
  static InspirationService get instance => _instance;

  InspirationService._internal();

  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('InspirationService initialized');
  }

  /// Get random inspirational image
  /// Using Picsum Photos - FREE, No API Key!
  Future<InspirationalImage?> getRandomImage({
    int width = 1920,
    int height = 1080,
  }) async {
    try {
      AppLogger.debug('Fetching random inspirational image...');

      final randomId = Random().nextInt(1000);
      final url = Uri.parse('https://picsum.photos/id/$randomId/info');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InspirationalImage.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch inspirational image', e, stackTrace);
      return null;
    }
  }

  /// Get Kanye West quote (humorous quotes)
  /// Using Kanye.rest - FREE, No API Key!
  Future<String?> getKanyeQuote() async {
    try {
      AppLogger.debug('Fetching Kanye quote...');

      final url = Uri.parse('https://api.kanye.rest');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quote = KanyeQuote.fromJson(data);
        return quote.quote;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch Kanye quote', e, stackTrace);
      return null;
    }
  }

  /// Get random breaking bad quote
  /// Using Breaking Bad Quotes API - FREE!
  Future<String?> getBreakingBadQuote() async {
    try {
      AppLogger.debug('Fetching Breaking Bad quote...');

      final url = Uri.parse('https://api.breakingbadquotes.xyz/v1/quotes');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final quote = data.first['quote'];
          final author = data.first['author'];
          return '"$quote" - $author';
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch Breaking Bad quote', e, stackTrace);
      return null;
    }
  }

  /// Get Game of Thrones quote
  Future<String?> getGameOfThronesQuote() async {
    try {
      final url = Uri.parse('https://api.gameofthronesquotes.xyz/v1/random');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sentence = data['sentence'];
        final character = data['character']['name'];
        return '"$sentence" - $character';
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch Game of Thrones quote', e, stackTrace);
      return null;
    }
  }

  /// Get random inspirational content
  Future<String> getRandomInspiration() async {
    final random = Random().nextInt(4);

    switch (random) {
      case 0:
        final quote = await getKanyeQuote();
        return quote != null ? '💭 Kanye says: "$quote"' : 'Stay inspired!';

      case 1:
        final quote = await getBreakingBadQuote();
        return quote != null ? '🎬 $quote' : 'Stay motivated!';

      case 2:
        final quote = await getGameOfThronesQuote();
        return quote != null ? '🐉 $quote' : 'Be strong!';

      default:
        return 'You are capable of amazing things! 💪';
    }
  }
}
