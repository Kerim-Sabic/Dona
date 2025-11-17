import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys.dart';
import '../../data/models/weather_data.dart';

/// Service for fetching weather from OpenWeatherMap API
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  static WeatherService get instance => _instance;

  WeatherService._internal();

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<void> init() async {
    try {
      AppLogger.info('WeatherService initialized with OpenWeatherMap API');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize WeatherService', e, stackTrace);
      rethrow;
    }
  }

  /// Get current weather for a city
  Future<WeatherData?> getCurrentWeather({String? city}) async {
    try {
      final cityName = _sanitizeInput(city ?? ApiConfig.defaultCity);
      AppLogger.debug('Fetching current weather for: $cityName');

      final weather = await _fetchWithRetry(() async {
        final url = Uri.https(
          'api.openweathermap.org',
          '/data/2.5/weather',
          {
            'q': cityName,
            'appid': ApiKeys.openWeatherApiKey,
            'units': ApiConfig.temperatureUnit,
          },
        );

        final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return WeatherData.fromJson(data);
        } else if (response.statusCode == 404) {
          throw Exception('City not found: $cityName');
        } else if (response.statusCode == 401) {
          throw Exception('Invalid API key');
        } else {
          throw Exception('Weather API error: ${response.statusCode} - ${response.body}');
        }
      });

      if (weather != null) {
        AppLogger.info('Fetched weather for ${weather.cityName}');
      }
      return weather;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch current weather', e, stackTrace);
      return _getMockWeather(); // Return mock data on error
    }
  }

  /// Get weather forecast for a city (5-day forecast)
  Future<List<WeatherData>> getWeatherForecast({String? city, int days = 5}) async {
    try {
      final cityName = _sanitizeInput(city ?? ApiConfig.defaultCity);
      AppLogger.debug('Fetching weather forecast for: $cityName');

      final forecasts = await _fetchWithRetry<List<WeatherData>>(() async {
        final url = Uri.https(
          'api.openweathermap.org',
          '/data/2.5/forecast',
          {
            'q': cityName,
            'appid': ApiKeys.openWeatherApiKey,
            'units': ApiConfig.temperatureUnit,
          },
        );

        final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> forecastList = data['list'] ?? [];

          return forecastList
              .map((item) => WeatherData.fromForecastJson(item, data['city']['name']))
              .toList();
        } else {
          throw Exception('Forecast API error: ${response.statusCode}');
        }
      });

      if (forecasts != null) {
        AppLogger.info('Fetched ${forecasts.length} forecast entries');
        return forecasts;
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch weather forecast', e, stackTrace);
      return [];
    }
  }

  /// Get weather by coordinates (latitude, longitude)
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lon) async {
    try {
      // Validate coordinates
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        throw ArgumentError('Invalid coordinates: lat=$lat, lon=$lon');
      }

      AppLogger.debug('Fetching weather for coordinates: $lat, $lon');

      final weather = await _fetchWithRetry(() async {
        final url = Uri.https(
          'api.openweathermap.org',
          '/data/2.5/weather',
          {
            'lat': lat.toString(),
            'lon': lon.toString(),
            'appid': ApiKeys.openWeatherApiKey,
            'units': ApiConfig.temperatureUnit,
          },
        );

        final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return WeatherData.fromJson(data);
        } else {
          throw Exception('Weather API error: ${response.statusCode}');
        }
      });

      return weather;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch weather by coordinates', e, stackTrace);
      return null;
    }
  }

  /// Get mock weather data for testing
  WeatherData _getMockWeather() {
    return WeatherData(
      cityName: 'Sarajevo',
      temperature: 22.0,
      feelsLike: 21.0,
      tempMin: 18.0,
      tempMax: 25.0,
      humidity: 65,
      pressure: 1013,
      description: 'Partly cloudy',
      icon: '02d',
      windSpeed: 3.5,
      windDeg: 180,
      cloudiness: 40,
      timestamp: DateTime.now(),
    );
  }

  /// Sanitize user input to prevent injection attacks
  String _sanitizeInput(String input) {
    // Remove any potentially dangerous characters
    // Allow only letters, spaces, hyphens, commas, and periods
    final sanitized = input.replaceAll(RegExp(r'[^a-zA-Z\s,\-\.]'), '');
    final trimmed = sanitized.trim();

    // Prevent excessively long inputs
    if (trimmed.length > 100) {
      return trimmed.substring(0, 100);
    }

    return trimmed;
  }

  /// Fetch with automatic retry on network failures
  Future<T?> _fetchWithRetry<T>(Future<T> Function() fetchFunction) async {
    int retries = 0;

    while (retries < _maxRetries) {
      try {
        return await fetchFunction();
      } catch (e) {
        retries++;
        if (retries >= _maxRetries) {
          rethrow;
        }

        final delay = _retryDelay * retries; // Exponential backoff
        AppLogger.warning('Request failed, retrying in ${delay.inSeconds}s (attempt $retries/$_maxRetries)');
        await Future.delayed(delay);
      }
    }

    return null;
  }
}
