import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../core/utils/input_sanitizer.dart';

/// Cocktail model
class Cocktail {
  final String id;
  final String name;
  final String? category;
  final String? alcoholic;
  final String? glass;
  final String instructions;
  final String? imageUrl;
  final List<String> ingredients;
  final List<String> measures;

  Cocktail({
    required this.id,
    required this.name,
    this.category,
    this.alcoholic,
    this.glass,
    required this.instructions,
    this.imageUrl,
    this.ingredients = const [],
    this.measures = const [],
  });

  factory Cocktail.fromJson(Map<String, dynamic> json) {
    // Extract ingredients and measures
    final ingredients = <String>[];
    final measures = <String>[];

    for (int i = 1; i <= 15; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];

      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(ingredient.toString());
        if (measure != null && measure.toString().trim().isNotEmpty) {
          measures.add(measure.toString());
        } else {
          measures.add('');
        }
      }
    }

    return Cocktail(
      id: json['idDrink'] ?? '',
      name: json['strDrink'] ?? '',
      category: json['strCategory'],
      alcoholic: json['strAlcoholic'],
      glass: json['strGlass'],
      instructions: json['strInstructions'] ?? '',
      imageUrl: json['strDrinkThumb'],
      ingredients: ingredients,
      measures: measures,
    );
  }

  String get ingredientsList {
    final buffer = StringBuffer();
    for (int i = 0; i < ingredients.length; i++) {
      final measure = i < measures.length ? measures[i] : '';
      if (measure.isNotEmpty) {
        buffer.writeln('• $measure ${ingredients[i]}');
      } else {
        buffer.writeln('• ${ingredients[i]}');
      }
    }
    return buffer.toString().trim();
  }
}

/// Cocktails Service
/// Provides cocktail and drink recipes
/// FREE API - No API key required!
/// API: https://www.thecocktaildb.com/
class CocktailsService {
  static final CocktailsService _instance = CocktailsService._internal();
  static CocktailsService get instance => _instance;

  CocktailsService._internal();

  static const String _baseUrl = 'https://www.thecocktaildb.com/api/json/v1/1';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Cache
  final List<Cocktail> _cachedCocktails = [];

  Future<void> init() async {
    try {
      AppLogger.info('Initializing Cocktails Service...');

      // Pre-fetch some popular cocktails
      await _fetchPopularCocktails();

      _isInitialized = true;
      AppLogger.info('Cocktails Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Cocktails Service', e, stackTrace);
    }
  }

  /// Get a random cocktail
  Future<Cocktail?> getRandomCocktail() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/random.php'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drinks = data['drinks'] as List?;

        if (drinks != null && drinks.isNotEmpty) {
          final cocktail = Cocktail.fromJson(drinks[0]);
          _cacheCocktail(cocktail);
          return cocktail;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random cocktail', e, stackTrace);

      // Return cached cocktail if available
      if (_cachedCocktails.isNotEmpty) {
        _cachedCocktails.shuffle();
        return _cachedCocktails.first;
      }
    }
    return null;
  }

  /// Search cocktails by name
  Future<List<Cocktail>> searchByName(String name) async {
    try {
      final sanitizedName = InputSanitizer.sanitizeSearchQuery(name);

      final response = await http.get(
        Uri.parse('$_baseUrl/search.php?s=${Uri.encodeComponent(sanitizedName)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drinks = data['drinks'] as List?;

        if (drinks != null) {
          final cocktails = drinks.map((json) => Cocktail.fromJson(json)).toList();
          cocktails.forEach(_cacheCocktail);
          return cocktails;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search cocktails', e, stackTrace);
    }
    return [];
  }

  /// Search cocktails by ingredient
  Future<List<Cocktail>> searchByIngredient(String ingredient) async {
    try {
      final sanitizedIngredient = InputSanitizer.sanitizeSearchQuery(ingredient);

      final response = await http.get(
        Uri.parse('$_baseUrl/filter.php?i=${Uri.encodeComponent(sanitizedIngredient)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drinks = data['drinks'] as List?;

        if (drinks != null) {
          return drinks.map((json) => Cocktail.fromJson(json)).toList();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search cocktails by ingredient', e, stackTrace);
    }
    return [];
  }

  /// Get cocktails by category (Ordinary Drink, Cocktail, Shot, etc.)
  Future<List<Cocktail>> getByCategory(String category) async {
    try {
      final sanitizedCategory = InputSanitizer.sanitizeText(category);

      final response = await http.get(
        Uri.parse('$_baseUrl/filter.php?c=${Uri.encodeComponent(sanitizedCategory)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drinks = data['drinks'] as List?;

        if (drinks != null) {
          return drinks.map((json) => Cocktail.fromJson(json)).toList();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch cocktails by category', e, stackTrace);
    }
    return [];
  }

  /// Get non-alcoholic drinks
  Future<List<Cocktail>> getNonAlcoholicDrinks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/filter.php?a=Non_Alcoholic'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drinks = data['drinks'] as List?;

        if (drinks != null) {
          return drinks.map((json) => Cocktail.fromJson(json)).toList();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch non-alcoholic drinks', e, stackTrace);
    }
    return [];
  }

  /// Fetch popular cocktails
  Future<void> _fetchPopularCocktails() async {
    final popularNames = ['Margarita', 'Mojito', 'Martini', 'Cosmopolitan', 'Old Fashioned'];

    for (final name in popularNames) {
      final cocktails = await searchByName(name);
      if (cocktails.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// Cache cocktail
  void _cacheCocktail(Cocktail cocktail) {
    if (!_cachedCocktails.any((c) => c.id == cocktail.id)) {
      _cachedCocktails.add(cocktail);
      if (_cachedCocktails.length > 100) {
        _cachedCocktails.removeAt(0);
      }
    }
  }

  /// Get formatted cocktail summary
  Future<String> getCocktailSummary(String? searchTerm) async {
    Cocktail? cocktail;

    if (searchTerm != null && searchTerm.isNotEmpty) {
      final results = await searchByName(searchTerm);
      if (results.isNotEmpty) {
        cocktail = results.first;
      }
    }

    cocktail ??= await getRandomCocktail();

    if (cocktail != null) {
      final buffer = StringBuffer('🍹 Cocktail Recipe\n\n');
      buffer.writeln('📝 ${cocktail.name}');

      if (cocktail.category != null) {
        buffer.writeln('📂 Category: ${cocktail.category}');
      }

      if (cocktail.alcoholic != null) {
        buffer.writeln('🍺 ${cocktail.alcoholic}');
      }

      if (cocktail.glass != null) {
        buffer.writeln('🥃 Glass: ${cocktail.glass}');
      }

      buffer.writeln('');
      buffer.writeln('🧪 Ingredients:');
      buffer.writeln(cocktail.ingredientsList);
      buffer.writeln('');

      // Truncate instructions if too long
      var instructions = cocktail.instructions;
      if (instructions.length > 200) {
        instructions = '${instructions.substring(0, 200)}...';
      }
      buffer.writeln('👨‍🍳 Instructions:');
      buffer.writeln(instructions);

      return buffer.toString();
    }

    return '🍹 Unable to fetch cocktail recipe at the moment.';
  }

  /// Get help message
  String getHelp() {
    return '''
🍹 Cocktails Service Help:

Discover delicious cocktail and drink recipes!

Commands:
• "Random cocktail"
• "How to make a Margarita"
• "Cocktail with vodka"
• "Non-alcoholic drinks"

Examples:
• "Give me a cocktail recipe"
• "How to make a Mojito"
• "Show me a drink with rum"
• "Mocktail recipes"
''';
  }
}
