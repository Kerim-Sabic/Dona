import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys_secure.dart';
import '../../data/models/news_article.dart';

/// Service for fetching news from WorldNewsAPI
class NewsService {
  static final NewsService _instance = NewsService._internal();
  static NewsService get instance => _instance;

  NewsService._internal();

  Future<void> init() async {
    try {
      AppLogger.info('NewsService initialized with WorldNewsAPI');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize NewsService', e, stackTrace);
      rethrow;
    }
  }

  /// Get top news headlines for Bosnia
  Future<List<NewsArticle>> getTopNews({
    String? country,
    String? language,
    int limit = 10,
  }) async {
    try {
      final countryCode = country ?? ApiConfig.defaultCountryCode;
      final lang = language ?? ApiConfig.defaultLanguage;

      AppLogger.debug('Fetching top news for country: $countryCode');

      final url = Uri.parse(
        '${ApiKeys.worldNewsBaseUrl}/top-news?source-country=$countryCode&language=$lang&number=$limit',
      );

      final response = await http.get(
        url,
        headers: {
          'X-Api-Key': ApiKeys.worldNewsApiKey,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> newsData = data['top_news'] ?? [];

        final articles = <NewsArticle>[];
        for (var item in newsData) {
          if (item is List && item.isNotEmpty) {
            for (var article in item) {
              articles.add(NewsArticle.fromJson(article));
            }
          }
        }

        AppLogger.info('Fetched ${articles.length} news articles');
        return articles.take(limit).toList();
      } else {
        AppLogger.error('News API error: ${response.statusCode}', response.body, StackTrace.current);
        throw Exception('News API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch top news', e, stackTrace);
      return _getMockNews(); // Return mock data on error
    }
  }

  /// Search for specific news
  Future<List<NewsArticle>> searchNews(String query, {int limit = 10}) async {
    try {
      AppLogger.debug('Searching news for: $query');

      final url = Uri.parse(
        '${ApiKeys.worldNewsBaseUrl}/search-news?text=$query&language=${ApiConfig.defaultLanguage}&number=$limit',
      );

      final response = await http.get(
        url,
        headers: {
          'X-Api-Key': ApiKeys.worldNewsApiKey,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> newsData = data['news'] ?? [];

        final articles = newsData
            .map((article) => NewsArticle.fromJson(article))
            .toList();

        AppLogger.info('Found ${articles.length} news articles');
        return articles;
      } else {
        throw Exception('News search error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search news', e, stackTrace);
      return [];
    }
  }

  /// Get news by category
  Future<List<NewsArticle>> getNewsByCategory(String category, {int limit = 10}) async {
    try {
      AppLogger.debug('Fetching news for category: $category');

      // For category-based search, we'll use search with category keyword
      return await searchNews(category, limit: limit);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch category news', e, stackTrace);
      return [];
    }
  }

  /// Get mock news for testing/offline mode
  List<NewsArticle> _getMockNews() {
    return [
      NewsArticle(
        id: '1',
        title: 'Bosnia and Herzegovina Economy Shows Growth',
        description: 'Recent economic indicators show positive growth in Bosnia and Herzegovina...',
        url: 'https://example.com/news1',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        source: 'Local News',
        author: 'News Reporter',
      ),
      NewsArticle(
        id: '2',
        title: 'Technology Sector Expands in Sarajevo',
        description: 'New tech companies are opening offices in Sarajevo, creating jobs...',
        url: 'https://example.com/news2',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        source: 'Tech News',
        author: 'Tech Reporter',
      ),
      NewsArticle(
        id: '3',
        title: 'Cultural Festival Announced for Next Month',
        description: 'A major cultural festival celebrating Bosnian heritage will take place...',
        url: 'https://example.com/news3',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
        source: 'Culture News',
        author: 'Culture Reporter',
      ),
    ];
  }
}
