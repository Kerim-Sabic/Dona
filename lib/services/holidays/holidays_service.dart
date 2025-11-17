import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Holiday model
class Holiday {
  final String name;
  final String date;
  final String country;
  final bool isPublic;
  final List<String> types;

  Holiday({
    required this.name,
    required this.date,
    required this.country,
    required this.isPublic,
    required this.types,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      country: json['country'] ?? '',
      isPublic: json['public'] ?? false,
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

/// Public Holidays API Service
/// https://date.nager.at/Api - Completely FREE, No API Key Required!
class HolidaysService {
  static final HolidaysService _instance = HolidaysService._internal();
  static HolidaysService get instance => _instance;

  HolidaysService._internal();

  static const String _baseUrl = 'https://date.nager.at/api/v3';
  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('HolidaysService initialized with Public Holidays API');
  }

  /// Get public holidays for a country and year
  Future<List<Holiday>> getHolidays({
    required String countryCode,
    int? year,
  }) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      AppLogger.debug('Fetching holidays for $countryCode in $targetYear');

      final url = Uri.parse('$_baseUrl/PublicHolidays/$targetYear/$countryCode');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return Holiday(
            name: item['localName'] ?? item['name'] ?? '',
            date: item['date'] ?? '',
            country: countryCode,
            isPublic: item['global'] ?? false,
            types: List<String>.from(item['types'] ?? []),
          );
        }).toList();
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch holidays', e, stackTrace);
      return [];
    }
  }

  /// Get next public holidays for a country
  Future<List<Holiday>> getNextHolidays(String countryCode) async {
    try {
      AppLogger.debug('Fetching next holidays for $countryCode');

      final url = Uri.parse('$_baseUrl/NextPublicHolidays/$countryCode');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return Holiday(
            name: item['localName'] ?? item['name'] ?? '',
            date: item['date'] ?? '',
            country: countryCode,
            isPublic: item['global'] ?? false,
            types: List<String>.from(item['types'] ?? []),
          );
        }).toList();
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch next holidays', e, stackTrace);
      return [];
    }
  }

  /// Check if today is a public holiday
  Future<bool> isTodayPublicHoliday(String countryCode) async {
    try {
      final now = DateTime.now();
      final url = Uri.parse(
        '$_baseUrl/IsTodayPublicHoliday/$countryCode',
      );
      final response = await http.get(url).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check if today is holiday', e, stackTrace);
      return false;
    }
  }

  /// Get available countries
  Future<List<Map<String, String>>> getAvailableCountries() async {
    try {
      final url = Uri.parse('$_baseUrl/AvailableCountries');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return {
            'code': item['countryCode'] as String,
            'name': item['name'] as String,
          };
        }).toList();
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch available countries', e, stackTrace);
      return [];
    }
  }

  /// Get holidays summary for display
  Future<String> getHolidaysSummary(String countryCode) async {
    try {
      final holidays = await getNextHolidays(countryCode);

      if (holidays.isEmpty) {
        return 'No upcoming public holidays found.';
      }

      final buffer = StringBuffer('🎉 Upcoming Public Holidays:\n\n');
      for (var holiday in holidays.take(5)) {
        final date = DateTime.parse(holiday.date);
        final formatted = '${date.day}/${date.month}/${date.year}';
        buffer.writeln('📅 $formatted - ${holiday.name}');
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get holidays summary', e, stackTrace);
      return 'Unable to fetch holidays information.';
    }
  }
}
