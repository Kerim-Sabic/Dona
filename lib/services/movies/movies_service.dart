import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys.dart';

/// Movie model
class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? releaseDate;
  final double? rating;
  final int? voteCount;
  final String? posterPath;
  final String? backdropPath;
  final List<int> genreIds;
  final String? originalLanguage;

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.releaseDate,
    this.rating,
    this.voteCount,
    this.posterPath,
    this.backdropPath,
    required this.genreIds,
    this.originalLanguage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'],
      releaseDate: json['release_date'],
      rating: json['vote_average']?.toDouble(),
      voteCount: json['vote_count'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      originalLanguage: json['original_language'],
    );
  }

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
      : null;
}

/// TV Show model
class TVShow {
  final int id;
  final String name;
  final String? overview;
  final String? firstAirDate;
  final double? rating;
  final int? voteCount;
  final String? posterPath;
  final String? backdropPath;
  final List<int> genreIds;
  final String? originalLanguage;

  TVShow({
    required this.id,
    required this.name,
    this.overview,
    this.firstAirDate,
    this.rating,
    this.voteCount,
    this.posterPath,
    this.backdropPath,
    required this.genreIds,
    this.originalLanguage,
  });

  factory TVShow.fromJson(Map<String, dynamic> json) {
    return TVShow(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'],
      firstAirDate: json['first_air_date'],
      rating: json['vote_average']?.toDouble(),
      voteCount: json['vote_count'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      originalLanguage: json['original_language'],
    );
  }

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
      : null;
}

/// TMDb (The Movie Database) API Service
/// https://www.themoviedb.org/settings/api - FREE for non-commercial use!
/// 1,000,000+ movies and TV shows with detailed metadata
class MoviesService {
  static final MoviesService _instance = MoviesService._internal();
  static MoviesService get instance => _instance;

  MoviesService._internal();

  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const Duration _timeout = Duration(seconds: 15);

  String get _apiKey => ApiKeys.tmdbApiKey;

  Future<void> init() async {
    AppLogger.info('MoviesService initialized with TMDb API');
  }

  /// Search movies
  Future<List<Movie>> searchMovies(String query) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('TMDb API key not configured');
        return [];
      }

      AppLogger.debug('Searching movies: $query');

      final params = {
        'api_key': _apiKey,
        'query': query,
        'language': 'en-US',
        'page': '1',
      };

      final uri = Uri.parse('$_baseUrl/search/movie').replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((m) => Movie.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search movies', e, stackTrace);
      return [];
    }
  }

  /// Search TV shows
  Future<List<TVShow>> searchTVShows(String query) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('TMDb API key not configured');
        return [];
      }

      AppLogger.debug('Searching TV shows: $query');

      final params = {
        'api_key': _apiKey,
        'query': query,
        'language': 'en-US',
        'page': '1',
      };

      final uri = Uri.parse('$_baseUrl/search/tv').replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((tv) => TVShow.fromJson(tv)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search TV shows', e, stackTrace);
      return [];
    }
  }

  /// Get trending movies (today or this week)
  Future<List<Movie>> getTrendingMovies({String timeWindow = 'week'}) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('TMDb API key not configured');
        return [];
      }

      AppLogger.debug('Fetching trending movies...');

      final params = {'api_key': _apiKey};

      final uri = Uri.parse('$_baseUrl/trending/movie/$timeWindow')
          .replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((m) => Movie.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch trending movies', e, stackTrace);
      return [];
    }
  }

  /// Get trending TV shows
  Future<List<TVShow>> getTrendingTVShows({String timeWindow = 'week'}) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('TMDb API key not configured');
        return [];
      }

      AppLogger.debug('Fetching trending TV shows...');

      final params = {'api_key': _apiKey};

      final uri = Uri.parse('$_baseUrl/trending/tv/$timeWindow')
          .replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((tv) => TVShow.fromJson(tv)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch trending TV shows', e, stackTrace);
      return [];
    }
  }

  /// Get popular movies
  Future<List<Movie>> getPopularMovies() async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('TMDb API key not configured');
        return [];
      }

      AppLogger.debug('Fetching popular movies...');

      final params = {
        'api_key': _apiKey,
        'language': 'en-US',
        'page': '1',
      };

      final uri = Uri.parse('$_baseUrl/movie/popular').replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((m) => Movie.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch popular movies', e, stackTrace);
      return [];
    }
  }

  /// Get now playing movies
  Future<List<Movie>> getNowPlayingMovies() async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('TMDb API key not configured');
        return [];
      }

      AppLogger.debug('Fetching now playing movies...');

      final params = {
        'api_key': _apiKey,
        'language': 'en-US',
        'page': '1',
      };

      final uri = Uri.parse('$_baseUrl/movie/now_playing').replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((m) => Movie.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch now playing movies', e, stackTrace);
      return [];
    }
  }

  /// Get upcoming movies
  Future<List<Movie>> getUpcomingMovies() async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('TMDb API key not configured');
        return [];
      }

      AppLogger.debug('Fetching upcoming movies...');

      final params = {
        'api_key': _apiKey,
        'language': 'en-US',
        'page': '1',
      };

      final uri = Uri.parse('$_baseUrl/movie/upcoming').replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((m) => Movie.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch upcoming movies', e, stackTrace);
      return [];
    }
  }

  /// Format movie for display
  String formatMovie(Movie movie) {
    final buffer = StringBuffer();
    buffer.writeln('🎬 ${movie.title}');

    if (movie.releaseDate != null) {
      buffer.writeln('📅 ${movie.releaseDate}');
    }

    if (movie.rating != null) {
      buffer.writeln('⭐ ${movie.rating!.toStringAsFixed(1)}/10 (${movie.voteCount} votes)');
    }

    if (movie.overview != null && movie.overview!.isNotEmpty) {
      final desc = movie.overview!.length > 200
          ? '${movie.overview!.substring(0, 200)}...'
          : movie.overview!;
      buffer.writeln('\n📝 $desc');
    }

    return buffer.toString();
  }

  /// Format TV show for display
  String formatTVShow(TVShow show) {
    final buffer = StringBuffer();
    buffer.writeln('📺 ${show.name}');

    if (show.firstAirDate != null) {
      buffer.writeln('📅 First aired: ${show.firstAirDate}');
    }

    if (show.rating != null) {
      buffer.writeln('⭐ ${show.rating!.toStringAsFixed(1)}/10 (${show.voteCount} votes)');
    }

    if (show.overview != null && show.overview!.isNotEmpty) {
      final desc = show.overview!.length > 200
          ? '${show.overview!.substring(0, 200)}...'
          : show.overview!;
      buffer.writeln('\n📝 $desc');
    }

    return buffer.toString();
  }

  /// Get movie recommendations
  Future<String> getMovieRecommendations({bool trending = true}) async {
    try {
      if (_apiKey.isEmpty) {
        return '🎬 TMDb API key not configured. Add your API key to use movies feature!';
      }

      final movies = trending
          ? await getTrendingMovies()
          : await getPopularMovies();

      if (movies.isEmpty) {
        return 'No movie recommendations available.';
      }

      final buffer = StringBuffer('🎬 ${trending ? 'Trending' : 'Popular'} Movies:\n\n');

      for (var i = 0; i < movies.length && i < 5; i++) {
        final movie = movies[i];
        buffer.writeln('${i + 1}. ${movie.title}');
        if (movie.rating != null) {
          buffer.writeln('   ⭐ ${movie.rating!.toStringAsFixed(1)}/10');
        }
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get movie recommendations', e, stackTrace);
      return 'Unable to fetch movie recommendations.';
    }
  }

  /// Get TV show recommendations
  Future<String> getTVShowRecommendations() async {
    try {
      if (_apiKey.isEmpty) {
        return '📺 TMDb API key not configured. Add your API key to use TV shows feature!';
      }

      final shows = await getTrendingTVShows();

      if (shows.isEmpty) {
        return 'No TV show recommendations available.';
      }

      final buffer = StringBuffer('📺 Trending TV Shows:\n\n');

      for (var i = 0; i < shows.length && i < 5; i++) {
        final show = shows[i];
        buffer.writeln('${i + 1}. ${show.name}');
        if (show.rating != null) {
          buffer.writeln('   ⭐ ${show.rating!.toStringAsFixed(1)}/10');
        }
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get TV show recommendations', e, stackTrace);
      return 'Unable to fetch TV show recommendations.';
    }
  }

  /// Search and display movie info
  Future<String> getMovieInfo(String query) async {
    try {
      if (_apiKey.isEmpty) {
        return '🎬 TMDb API key not configured. Add your API key to use movies feature!';
      }

      final movies = await searchMovies(query);

      if (movies.isEmpty) {
        return 'No movies found for "$query"';
      }

      final buffer = StringBuffer('🎬 Movie Search Results:\n\n');

      for (var i = 0; i < movies.length && i < 3; i++) {
        buffer.writeln('${i + 1}. ${formatMovie(movies[i])}\n');
      }

      if (movies.length > 3) {
        buffer.writeln('...and ${movies.length - 3} more results');
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get movie info', e, stackTrace);
      return 'Unable to search movies.';
    }
  }
}
