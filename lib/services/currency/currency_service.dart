import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Currency exchange rates model
class ExchangeRates {
  final String baseCurrency;
  final DateTime date;
  final Map<String, double> rates;

  ExchangeRates({
    required this.baseCurrency,
    required this.date,
    required this.rates,
  });

  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    final ratesMap = <String, double>{};
    final rates = json['rates'] as Map<String, dynamic>?;
    if (rates != null) {
      rates.forEach((key, value) {
        ratesMap[key] = (value as num).toDouble();
      });
    }

    return ExchangeRates(
      baseCurrency: json['base'] ?? 'USD',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      rates: ratesMap,
    );
  }

  double? convert(String fromCurrency, String toCurrency, double amount) {
    if (fromCurrency == baseCurrency) {
      final rate = rates[toCurrency];
      return rate != null ? amount * rate : null;
    } else if (toCurrency == baseCurrency) {
      final rate = rates[fromCurrency];
      return rate != null ? amount / rate : null;
    } else {
      final fromRate = rates[fromCurrency];
      final toRate = rates[toCurrency];
      if (fromRate != null && toRate != null) {
        return amount * (toRate / fromRate);
      }
    }
    return null;
  }
}

/// Currency Exchange API Service
/// https://exchangerate-api.com - FREE tier available!
class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  static CurrencyService get instance => _instance;

  CurrencyService._internal();

  // Using free tier - limited requests
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const Duration _timeout = Duration(seconds: 10);

  // Cache for exchange rates (valid for 24 hours)
  ExchangeRates? _cachedRates;
  DateTime? _cacheTime;

  Future<void> init() async {
    AppLogger.info('CurrencyService initialized');
  }

  /// Get latest exchange rates
  Future<ExchangeRates?> getExchangeRates({String baseCurrency = 'USD'}) async {
    try {
      // Return cached data if less than 1 hour old
      if (_cachedRates != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!);
        if (age.inHours < 1) {
          AppLogger.debug('Using cached exchange rates');
          return _cachedRates;
        }
      }

      AppLogger.debug('Fetching exchange rates for $baseCurrency');

      final url = Uri.parse('$_baseUrl/$baseCurrency');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedRates = ExchangeRates.fromJson(data);
        _cacheTime = DateTime.now();
        return _cachedRates;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch exchange rates', e, stackTrace);
      return _cachedRates; // Return cached data if available
    }
  }

  /// Convert currency
  Future<double?> convertCurrency({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      final rates = await getExchangeRates(baseCurrency: from);
      if (rates == null) return null;

      return rates.convert(from, to, amount);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to convert currency', e, stackTrace);
      return null;
    }
  }

  /// Get currency conversion summary
  Future<String> getConversionSummary({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      final converted = await convertCurrency(from: from, to: to, amount: amount);

      if (converted == null) {
        return 'Unable to convert currency at this time.';
      }

      return '💱 ${amount.toStringAsFixed(2)} $from = ${converted.toStringAsFixed(2)} $to';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get conversion summary', e, stackTrace);
      return 'Unable to fetch currency conversion.';
    }
  }

  /// Get popular currency rates
  Future<String> getPopularRates() async {
    try {
      final rates = await getExchangeRates(baseCurrency: 'USD');

      if (rates == null || rates.rates.isEmpty) {
        return 'Unable to fetch exchange rates.';
      }

      final popular = ['EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD'];
      final buffer = StringBuffer('💱 Exchange Rates (1 USD):\n\n');

      for (var currency in popular) {
        final rate = rates.rates[currency];
        if (rate != null) {
          buffer.writeln('$currency: ${rate.toStringAsFixed(4)}');
        }
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get popular rates', e, stackTrace);
      return 'Unable to fetch exchange rates.';
    }
  }
}
