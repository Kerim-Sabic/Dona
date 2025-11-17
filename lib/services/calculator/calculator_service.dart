import 'dart:math' as math;
import '../../core/utils/logger.dart';

/// Calculator result model
class CalculationResult {
  final String expression;
  final double result;
  final String formattedResult;

  CalculationResult({
    required this.expression,
    required this.result,
    required this.formattedResult,
  });
}

/// Unit conversion model
class ConversionResult {
  final double value;
  final String fromUnit;
  final String toUnit;
  final double result;
  final String formattedResult;

  ConversionResult({
    required this.value,
    required this.fromUnit,
    required this.toUnit,
    required this.result,
    required this.formattedResult,
  });

  @override
  String toString() {
    return '$value $fromUnit = $formattedResult $toUnit';
  }
}

/// Calculator & Unit Converter Service
/// Provides mathematical calculations and unit conversions
/// NO API KEY REQUIRED - All calculations done locally!
class CalculatorService {
  static final CalculatorService _instance = CalculatorService._internal();
  static CalculatorService get instance => _instance;

  CalculatorService._internal();

  // Conversion factors to base units
  static const Map<String, Map<String, double>> _conversionFactors = {
    // Length (base: meter)
    'length': {
      'meter': 1.0,
      'm': 1.0,
      'kilometer': 1000.0,
      'km': 1000.0,
      'centimeter': 0.01,
      'cm': 0.01,
      'millimeter': 0.001,
      'mm': 0.001,
      'mile': 1609.344,
      'mi': 1609.344,
      'yard': 0.9144,
      'yd': 0.9144,
      'foot': 0.3048,
      'ft': 0.3048,
      'inch': 0.0254,
      'in': 0.0254,
    },

    // Weight (base: kilogram)
    'weight': {
      'kilogram': 1.0,
      'kg': 1.0,
      'gram': 0.001,
      'g': 0.001,
      'milligram': 0.000001,
      'mg': 0.000001,
      'ton': 1000.0,
      't': 1000.0,
      'pound': 0.453592,
      'lb': 0.453592,
      'ounce': 0.0283495,
      'oz': 0.0283495,
    },

    // Temperature (special handling required)
    'temperature': {
      'celsius': 1.0,
      'c': 1.0,
      'fahrenheit': 1.0,
      'f': 1.0,
      'kelvin': 1.0,
      'k': 1.0,
    },

    // Volume (base: liter)
    'volume': {
      'liter': 1.0,
      'l': 1.0,
      'milliliter': 0.001,
      'ml': 0.001,
      'gallon': 3.78541,
      'gal': 3.78541,
      'quart': 0.946353,
      'qt': 0.946353,
      'pint': 0.473176,
      'pt': 0.473176,
      'cup': 0.236588,
      'fluid_ounce': 0.0295735,
      'fl_oz': 0.0295735,
    },

    // Area (base: square meter)
    'area': {
      'square_meter': 1.0,
      'm2': 1.0,
      'square_kilometer': 1000000.0,
      'km2': 1000000.0,
      'square_centimeter': 0.0001,
      'cm2': 0.0001,
      'square_mile': 2589988.11,
      'square_yard': 0.836127,
      'square_foot': 0.092903,
      'square_inch': 0.00064516,
      'hectare': 10000.0,
      'acre': 4046.86,
    },

    // Speed (base: meters per second)
    'speed': {
      'meters_per_second': 1.0,
      'mps': 1.0,
      'kilometers_per_hour': 0.277778,
      'kmh': 0.277778,
      'kph': 0.277778,
      'miles_per_hour': 0.44704,
      'mph': 0.44704,
      'knot': 0.514444,
      'kt': 0.514444,
    },

    // Time (base: second)
    'time': {
      'second': 1.0,
      's': 1.0,
      'minute': 60.0,
      'min': 60.0,
      'hour': 3600.0,
      'h': 3600.0,
      'hr': 3600.0,
      'day': 86400.0,
      'd': 86400.0,
      'week': 604800.0,
      'wk': 604800.0,
      'month': 2592000.0, // 30 days
      'year': 31536000.0, // 365 days
      'yr': 31536000.0,
    },

    // Data (base: byte)
    'data': {
      'byte': 1.0,
      'b': 1.0,
      'kilobyte': 1024.0,
      'kb': 1024.0,
      'megabyte': 1048576.0,
      'mb': 1048576.0,
      'gigabyte': 1073741824.0,
      'gb': 1073741824.0,
      'terabyte': 1099511627776.0,
      'tb': 1099511627776.0,
    },
  };

  Future<void> init() async {
    AppLogger.info('CalculatorService initialized');
  }

  /// Calculate mathematical expression
  CalculationResult? calculate(String expression) {
    try {
      // Clean the expression
      final cleanExpr = expression
          .trim()
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll(' ', '');

      // Evaluate the expression
      final result = _evaluateExpression(cleanExpr);

      // Format result
      final formatted = _formatNumber(result);

      return CalculationResult(
        expression: expression,
        result: result,
        formattedResult: formatted,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to calculate expression', e, stackTrace);
      return null;
    }
  }

  /// Evaluate mathematical expression (supports +, -, *, /, ^, sqrt, sin, cos, tan, etc.)
  double _evaluateExpression(String expr) {
    // Handle scientific functions
    expr = _handleScientificFunctions(expr);

    // Simple expression parser using operator precedence
    return _parseExpression(expr);
  }

  /// Handle scientific functions like sqrt, sin, cos, tan, log
  String _handleScientificFunctions(String expr) {
    // Square root
    expr = expr.replaceAllMapped(
      RegExp(r'sqrt\(([^)]+)\)'),
      (match) {
        final value = _parseExpression(match.group(1)!);
        return math.sqrt(value).toString();
      },
    );

    // Sine (in degrees)
    expr = expr.replaceAllMapped(
      RegExp(r'sin\(([^)]+)\)'),
      (match) {
        final value = _parseExpression(match.group(1)!);
        return math.sin(value * math.pi / 180).toString();
      },
    );

    // Cosine (in degrees)
    expr = expr.replaceAllMapped(
      RegExp(r'cos\(([^)]+)\)'),
      (match) {
        final value = _parseExpression(match.group(1)!);
        return math.cos(value * math.pi / 180).toString();
      },
    );

    // Tangent (in degrees)
    expr = expr.replaceAllMapped(
      RegExp(r'tan\(([^)]+)\)'),
      (match) {
        final value = _parseExpression(match.group(1)!);
        return math.tan(value * math.pi / 180).toString();
      },
    );

    // Natural logarithm
    expr = expr.replaceAllMapped(
      RegExp(r'ln\(([^)]+)\)'),
      (match) {
        final value = _parseExpression(match.group(1)!);
        return math.log(value).toString();
      },
    );

    // Base-10 logarithm
    expr = expr.replaceAllMapped(
      RegExp(r'log\(([^)]+)\)'),
      (match) {
        final value = _parseExpression(match.group(1)!);
        return (math.log(value) / math.ln10).toString();
      },
    );

    return expr;
  }

  /// Parse and evaluate expression with operator precedence
  double _parseExpression(String expr) {
    // Remove whitespace
    expr = expr.replaceAll(' ', '');

    // Handle parentheses first
    while (expr.contains('(')) {
      final start = expr.lastIndexOf('(');
      final end = expr.indexOf(')', start);
      if (end == -1) throw FormatException('Unmatched parentheses');

      final subExpr = expr.substring(start + 1, end);
      final result = _parseExpression(subExpr);
      expr = expr.substring(0, start) + result.toString() + expr.substring(end + 1);
    }

    // Handle addition and subtraction (lowest precedence)
    for (int i = expr.length - 1; i >= 0; i--) {
      if (i > 0 && (expr[i] == '+' || expr[i] == '-')) {
        final left = _parseExpression(expr.substring(0, i));
        final right = _parseExpression(expr.substring(i + 1));
        return expr[i] == '+' ? left + right : left - right;
      }
    }

    // Handle multiplication and division (medium precedence)
    for (int i = expr.length - 1; i >= 0; i--) {
      if (i > 0 && (expr[i] == '*' || expr[i] == '/')) {
        final left = _parseExpression(expr.substring(0, i));
        final right = _parseExpression(expr.substring(i + 1));
        if (expr[i] == '*') {
          return left * right;
        } else {
          // Check for division by zero
          if (right == 0 || right.abs() < 0.0000001) {
            throw FormatException('Division by zero');
          }
          return left / right;
        }
      }
    }

    // Handle exponentiation (highest precedence)
    for (int i = expr.length - 1; i >= 0; i--) {
      if (i > 0 && expr[i] == '^') {
        final left = _parseExpression(expr.substring(0, i));
        final right = _parseExpression(expr.substring(i + 1));
        return math.pow(left, right).toDouble();
      }
    }

    // Parse number
    return double.parse(expr);
  }

  /// Convert units
  ConversionResult? convertUnits({
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    try {
      fromUnit = fromUnit.toLowerCase().replaceAll(' ', '_');
      toUnit = toUnit.toLowerCase().replaceAll(' ', '_');

      // Find the category
      String? category;
      for (var entry in _conversionFactors.entries) {
        if (entry.value.containsKey(fromUnit) && entry.value.containsKey(toUnit)) {
          category = entry.key;
          break;
        }
      }

      if (category == null) {
        AppLogger.warning('Could not find conversion category for $fromUnit to $toUnit');
        return null;
      }

      double result;

      // Special handling for temperature
      if (category == 'temperature') {
        result = _convertTemperature(value, fromUnit, toUnit);
      } else {
        // Convert to base unit, then to target unit
        final fromFactor = _conversionFactors[category]![fromUnit]!;
        final toFactor = _conversionFactors[category]![toUnit]!;
        result = value * fromFactor / toFactor;
      }

      return ConversionResult(
        value: value,
        fromUnit: fromUnit,
        toUnit: toUnit,
        result: result,
        formattedResult: _formatNumber(result),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to convert units', e, stackTrace);
      return null;
    }
  }

  /// Convert temperature between Celsius, Fahrenheit, and Kelvin
  double _convertTemperature(double value, String from, String to) {
    // Normalize unit names
    from = from.toLowerCase();
    to = to.toLowerCase();

    if (from == 'c' || from == 'celsius') from = 'celsius';
    if (from == 'f' || from == 'fahrenheit') from = 'fahrenheit';
    if (from == 'k' || from == 'kelvin') from = 'kelvin';

    if (to == 'c' || to == 'celsius') to = 'celsius';
    if (to == 'f' || to == 'fahrenheit') to = 'fahrenheit';
    if (to == 'k' || to == 'kelvin') to = 'kelvin';

    // Convert to Celsius first
    double celsius;
    switch (from) {
      case 'celsius':
        celsius = value;
        break;
      case 'fahrenheit':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'kelvin':
        celsius = value - 273.15;
        break;
      default:
        throw FormatException('Unknown temperature unit: $from');
    }

    // Convert from Celsius to target
    switch (to) {
      case 'celsius':
        return celsius;
      case 'fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'kelvin':
        return celsius + 273.15;
      default:
        throw FormatException('Unknown temperature unit: $to');
    }
  }

  /// Format number for display
  String _formatNumber(double number) {
    if (number.abs() >= 1000000) {
      return number.toStringAsExponential(2);
    } else if (number.abs() < 0.001 && number != 0) {
      return number.toStringAsExponential(2);
    } else {
      // Remove trailing zeros
      final str = number.toStringAsFixed(6);
      final trimmed = str.replaceAll(RegExp(r'\.?0+$'), '');
      return trimmed;
    }
  }

  /// Get calculator help
  String getCalculatorHelp() {
    return '''
🔢 Calculator Help:

Basic Operations:
• Addition: 5 + 3
• Subtraction: 10 - 4
• Multiplication: 7 * 6
• Division: 20 / 4
• Exponentiation: 2 ^ 8

Scientific Functions:
• Square root: sqrt(16)
• Sine: sin(30)
• Cosine: cos(45)
• Tangent: tan(60)
• Natural log: ln(10)
• Base-10 log: log(100)

Examples:
• "Calculate 5 + 3 * 2"
• "What is sqrt(144)?"
• "sin(30) + cos(60)"
''';
  }

  /// Get unit converter help
  String getUnitConverterHelp() {
    return '''
📐 Unit Converter Help:

Supported Categories:
📏 Length: meter, km, cm, mm, mile, yard, foot, inch
⚖️ Weight: kg, gram, mg, ton, pound, ounce
🌡️ Temperature: celsius, fahrenheit, kelvin
💧 Volume: liter, ml, gallon, quart, pint, cup
📦 Area: m2, km2, cm2, square mile, hectare, acre
🏃 Speed: m/s, km/h, mph, knot
⏱️ Time: second, minute, hour, day, week, year
💾 Data: byte, KB, MB, GB, TB

Examples:
• "Convert 5 km to miles"
• "100 fahrenheit to celsius"
• "1 GB to MB"
• "10 pounds to kg"
''';
  }

  /// List available unit categories
  List<String> getUnitCategories() {
    return _conversionFactors.keys.toList();
  }

  /// Get units for a specific category
  List<String> getUnitsForCategory(String category) {
    return _conversionFactors[category.toLowerCase()]?.keys.toList() ?? [];
  }
}
