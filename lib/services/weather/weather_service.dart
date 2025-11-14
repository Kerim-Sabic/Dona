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
      final cityName = city ?? ApiConfig.defaultCity;
      AppLogger.debug('Fetching current weather for: $cityName');

      final url = Uri.parse(
        '${ApiKeys.openWeatherBaseUrl}/weather?q=$cityName&appid=${ApiKeys.openWeatherApiKey}&units=${ApiConfig.temperatureUnit}',
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final weather = WeatherData.fromJson(data);
        AppLogger.info('Fetched weather for ${weather.cityName}');
        return weather;
      } else {
        throw Exception('Weather API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch current weather', e, stackTrace);
      return _getMockWeather(); // Return mock data on error
    }
  }

  /// Get weather forecast for a city (5-day forecast)
  Future<List<WeatherData>> getWeatherForecast({String? city, int days = 5}) async {
    try {
      final cityName = city ?? ApiConfig.defaultCity;
      AppLogger.debug('Fetching weather forecast for: $cityName');

      final url = Uri.parse(
        '${ApiKeys.openWeatherBaseUrl}/forecast?q=$cityName&appid=${ApiKeys.openWeatherApiKey}&units=${ApiConfig.temperatureUnit}',
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecastList = data['list'] ?? [];

        final forecasts = forecastList
            .map((item) => WeatherData.fromForecastJson(item, data['city']['name']))
            .toList();

        AppLogger.info('Fetched ${forecasts.length} forecast entries');
        return forecasts;
      } else {
        throw Exception('Forecast API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch weather forecast', e, stackTrace);
      return [];
    }
  }

  /// Get weather by coordinates (latitude, longitude)
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lon) async {
    try {
      AppLogger.debug('Fetching weather for coordinates: $lat, $lon');

      final url = Uri.parse(
        '${ApiKeys.openWeatherBaseUrl}/weather?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherApiKey}&units=${ApiConfig.temperatureUnit}',
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
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
}
