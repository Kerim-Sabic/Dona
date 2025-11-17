import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// IP Location data model
class IPLocation {
  final String ip;
  final String city;
  final String region;
  final String country;
  final String countryCode;
  final String continent;
  final double? latitude;
  final double? longitude;
  final String timezone;
  final String isp;

  IPLocation({
    required this.ip,
    required this.city,
    required this.region,
    required this.country,
    required this.countryCode,
    required this.continent,
    this.latitude,
    this.longitude,
    required this.timezone,
    required this.isp,
  });

  factory IPLocation.fromJson(Map<String, dynamic> json) {
    return IPLocation(
      ip: json['query'] ?? json['ip'] ?? '',
      city: json['city'] ?? '',
      region: json['regionName'] ?? json['region'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['countryCode'] ?? '',
      continent: json['continent'] ?? '',
      latitude: json['lat']?.toDouble(),
      longitude: json['lon']?.toDouble(),
      timezone: json['timezone'] ?? '',
      isp: json['isp'] ?? '',
    );
  }
}

/// IP Geolocation Service
/// http://ip-api.com - FREE, No API Key Required!
class IPLocationService {
  static final IPLocationService _instance = IPLocationService._internal();
  static IPLocationService get instance => _instance;

  IPLocationService._internal();

  static const String _baseUrl = 'http://ip-api.com/json';
  static const Duration _timeout = Duration(seconds: 10);

  IPLocation? _cachedLocation;
  DateTime? _cacheTime;

  Future<void> init() async {
    AppLogger.info('IPLocationService initialized with IP-API');
  }

  /// Get current IP location
  Future<IPLocation?> getCurrentLocation() async {
    try {
      // Return cached data if less than 1 hour old
      if (_cachedLocation != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!);
        if (age.inHours < 1) {
          AppLogger.debug('Using cached IP location');
          return _cachedLocation;
        }
      }

      AppLogger.debug('Fetching current IP location...');

      final url = Uri.parse(_baseUrl);
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _cachedLocation = IPLocation.fromJson(data);
          _cacheTime = DateTime.now();
          return _cachedLocation;
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch IP location', e, stackTrace);
      return _cachedLocation; // Return cached if available
    }
  }

  /// Get location for specific IP
  Future<IPLocation?> getLocationForIP(String ip) async {
    try {
      AppLogger.debug('Fetching location for IP: $ip');

      final url = Uri.parse('$_baseUrl/$ip');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return IPLocation.fromJson(data);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch location for IP', e, stackTrace);
      return null;
    }
  }

  /// Get location summary
  Future<String> getLocationSummary() async {
    try {
      final location = await getCurrentLocation();

      if (location == null) {
        return 'Unable to determine your location.';
      }

      return '📍 Your Location:\n'
          '🌍 ${location.city}, ${location.region}\n'
          '🗺️ ${location.country} (${location.countryCode})\n'
          '🌐 IP: ${location.ip}\n'
          '⏰ Timezone: ${location.timezone}\n'
          '📡 ISP: ${location.isp}';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get location summary', e, stackTrace);
      return 'Unable to fetch location information.';
    }
  }
}
