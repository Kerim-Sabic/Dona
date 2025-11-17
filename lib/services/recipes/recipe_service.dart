import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Meal/Recipe model
class Meal {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? instructions;
  final String? thumbnail;
  final String? tags;
  final String? youtubeLink;
  final Map<String, String> ingredients;
  final Map<String, String> measures;

  Meal({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.instructions,
    this.thumbnail,
    this.tags,
    this.youtubeLink,
    required this.ingredients,
    required this.measures,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    // Extract ingredients and measures
    final ingredients = <String, String>{};
    final measures = <String, String>{};

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];

      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients['ingredient$i'] = ingredient.toString();
        measures['ingredient$i'] = measure?.toString() ?? '';
      }
    }

    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'],
      thumbnail: json['strMealThumb'],
      tags: json['strTags'],
      youtubeLink: json['strYoutube'],
      ingredients: ingredients,
      measures: measures,
    );
  }

  String get ingredientsList {
    final items = <String>[];
    ingredients.forEach((key, ingredient) {
      final measure = measures[key] ?? '';
      items.add('$measure $ingredient'.trim());
    });
    return items.join('\n');
  }
}

/// TheMealDB Free Recipe API Service
/// https://www.themealdb.com/api.php - Completely FREE, No API Key Required!
class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  static RecipeService get instance => _instance;

  RecipeService._internal();

  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const Duration _timeout = Duration(seconds: 15);

  Future<void> init() async {
    AppLogger.info('RecipeService initialized with TheMealDB API');
  }

  /// Get random meal recipe
  Future<Meal?> getRandomMeal() async {
    try {
      AppLogger.debug('Fetching random meal...');

      final url = Uri.parse('$_baseUrl/random.php');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        if (meals != null && meals.isNotEmpty) {
          return Meal.fromJson(meals.first);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random meal', e, stackTrace);
      return null;
    }
  }

  /// Search meals by name
  Future<List<Meal>> searchMealsByName(String name) async {
    try {
      AppLogger.debug('Searching meals: $name');

      final url = Uri.parse('$_baseUrl/search.php?s=${Uri.encodeComponent(name)}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        if (meals != null) {
          return meals.map((meal) => Meal.fromJson(meal)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search meals', e, stackTrace);
      return [];
    }
  }

  /// Get meals by category
  Future<List<Meal>> getMealsByCategory(String category) async {
    try {
      AppLogger.debug('Fetching $category meals...');

      final url = Uri.parse('$_baseUrl/filter.php?c=${Uri.encodeComponent(category)}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        if (meals != null) {
          return meals.map((meal) => Meal.fromJson(meal)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch meals by category', e, stackTrace);
      return [];
    }
  }

  /// Get meals by area/cuisine
  Future<List<Meal>> getMealsByArea(String area) async {
    try {
      AppLogger.debug('Fetching $area cuisine...');

      final url = Uri.parse('$_baseUrl/filter.php?a=${Uri.encodeComponent(area)}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        if (meals != null) {
          return meals.map((meal) => Meal.fromJson(meal)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch meals by area', e, stackTrace);
      return [];
    }
  }

  /// Get meal by ID
  Future<Meal?> getMealById(String id) async {
    try {
      AppLogger.debug('Fetching meal: $id');

      final url = Uri.parse('$_baseUrl/lookup.php?i=$id');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        if (meals != null && meals.isNotEmpty) {
          return Meal.fromJson(meals.first);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch meal by ID', e, stackTrace);
      return null;
    }
  }

  /// List all meal categories
  Future<List<String>> getCategories() async {
    try {
      final url = Uri.parse('$_baseUrl/categories.php');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = data['categories'] as List<dynamic>?;
        if (categories != null) {
          return categories
              .map((cat) => cat['strCategory'] as String)
              .toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch categories', e, stackTrace);
      return [];
    }
  }

  /// List all areas/cuisines
  Future<List<String>> getAreas() async {
    try {
      final url = Uri.parse('$_baseUrl/list.php?a=list');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final areas = data['meals'] as List<dynamic>?;
        if (areas != null) {
          return areas
              .map((area) => area['strArea'] as String)
              .toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch areas', e, stackTrace);
      return [];
    }
  }

  /// Search by main ingredient
  Future<List<Meal>> searchByIngredient(String ingredient) async {
    try {
      AppLogger.debug('Searching by ingredient: $ingredient');

      final url = Uri.parse('$_baseUrl/filter.php?i=${Uri.encodeComponent(ingredient)}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        if (meals != null) {
          return meals.map((meal) => Meal.fromJson(meal)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search by ingredient', e, stackTrace);
      return [];
    }
  }
}
