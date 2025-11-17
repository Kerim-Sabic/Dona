import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys.dart';

/// Food item model
class FoodItem {
  final String name;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;

  FoodItem({
    required this.name,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? '',
      servingSize: (json['serving_size'] ?? 100).toDouble(),
      servingUnit: json['serving_unit'] ?? 'g',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein_g'] ?? 0).toDouble(),
      carbs: (json['carbohydrates_total_g'] ?? 0).toDouble(),
      fat: (json['fat_total_g'] ?? 0).toDouble(),
      fiber: (json['fiber_g'] ?? 0).toDouble(),
      sugar: (json['sugar_g'] ?? 0).toDouble(),
    );
  }
}

/// Meal plan model
class MealPlan {
  final String name;
  final int targetCalories;
  final List<String> meals;
  final Map<String, double> macros;

  MealPlan({
    required this.name,
    required this.targetCalories,
    required this.meals,
    required this.macros,
  });
}

/// Nutrition & Food Tracking Service
/// Uses API-Ninjas Nutrition API (FREE with API key)
/// https://api-ninjas.com/api/nutrition
class NutritionService {
  static final NutritionService _instance = NutritionService._internal();
  static NutritionService get instance => _instance;

  NutritionService._internal();

  static const String _baseUrl = 'https://api.api-ninjas.com/v1/nutrition';
  static const Duration _timeout = Duration(seconds: 15);

  String get _apiKey => ApiKeys.apiNinjasKey;

  // Built-in nutrition database for common foods
  static const List<Map<String, dynamic>> _builtInFoods = [
    {
      'name': 'Apple',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 52,
      'protein_g': 0.3,
      'carbohydrates_total_g': 14,
      'fat_total_g': 0.2,
      'fiber_g': 2.4,
      'sugar_g': 10,
    },
    {
      'name': 'Banana',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 89,
      'protein_g': 1.1,
      'carbohydrates_total_g': 23,
      'fat_total_g': 0.3,
      'fiber_g': 2.6,
      'sugar_g': 12,
    },
    {
      'name': 'Chicken Breast',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 165,
      'protein_g': 31,
      'carbohydrates_total_g': 0,
      'fat_total_g': 3.6,
      'fiber_g': 0,
      'sugar_g': 0,
    },
    {
      'name': 'Rice (cooked)',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 130,
      'protein_g': 2.7,
      'carbohydrates_total_g': 28,
      'fat_total_g': 0.3,
      'fiber_g': 0.4,
      'sugar_g': 0.1,
    },
    {
      'name': 'Broccoli',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 34,
      'protein_g': 2.8,
      'carbohydrates_total_g': 7,
      'fat_total_g': 0.4,
      'fiber_g': 2.6,
      'sugar_g': 1.7,
    },
    {
      'name': 'Salmon',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 208,
      'protein_g': 20,
      'carbohydrates_total_g': 0,
      'fat_total_g': 13,
      'fiber_g': 0,
      'sugar_g': 0,
    },
    {
      'name': 'Egg',
      'serving_size': 50,
      'serving_unit': 'g',
      'calories': 78,
      'protein_g': 6.3,
      'carbohydrates_total_g': 0.6,
      'fat_total_g': 5.3,
      'fiber_g': 0,
      'sugar_g': 0.6,
    },
    {
      'name': 'Oatmeal (cooked)',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 71,
      'protein_g': 2.5,
      'carbohydrates_total_g': 12,
      'fat_total_g': 1.5,
      'fiber_g': 1.7,
      'sugar_g': 0.3,
    },
    {
      'name': 'Greek Yogurt',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 59,
      'protein_g': 10,
      'carbohydrates_total_g': 3.6,
      'fat_total_g': 0.4,
      'fiber_g': 0,
      'sugar_g': 3.6,
    },
    {
      'name': 'Almonds',
      'serving_size': 28,
      'serving_unit': 'g',
      'calories': 164,
      'protein_g': 6,
      'carbohydrates_total_g': 6,
      'fat_total_g': 14,
      'fiber_g': 3.5,
      'sugar_g': 1.2,
    },
    {
      'name': 'Sweet Potato',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 86,
      'protein_g': 1.6,
      'carbohydrates_total_g': 20,
      'fat_total_g': 0.1,
      'fiber_g': 3,
      'sugar_g': 4.2,
    },
    {
      'name': 'Spinach',
      'serving_size': 100,
      'serving_unit': 'g',
      'calories': 23,
      'protein_g': 2.9,
      'carbohydrates_total_g': 3.6,
      'fat_total_g': 0.4,
      'fiber_g': 2.2,
      'sugar_g': 0.4,
    },
  ];

  Future<void> init() async {
    AppLogger.info('NutritionService initialized');
  }

  /// Get nutrition info for a food query
  Future<List<FoodItem>> getNutritionInfo(String query) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('API Ninjas key not configured, searching built-in database');
        return _searchBuiltInFoods(query);
      }

      AppLogger.debug('Fetching nutrition info for: $query');

      final params = {'query': query};
      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {'X-Api-Key': _apiKey},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((f) => FoodItem.fromJson(f)).toList();
        }
      }

      // Fallback to built-in database
      return _searchBuiltInFoods(query);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch nutrition info', e, stackTrace);
      return _searchBuiltInFoods(query);
    }
  }

  /// Search built-in food database
  List<FoodItem> _searchBuiltInFoods(String query) {
    final lowerQuery = query.toLowerCase();
    final matches = _builtInFoods
        .where((food) =>
            food['name'].toString().toLowerCase().contains(lowerQuery))
        .map((food) => FoodItem.fromJson(food))
        .toList();

    return matches;
  }

  /// Calculate daily calorie needs
  int calculateDailyCalories({
    required int age,
    required String gender,
    required double weightKg,
    required double heightCm,
    required String activityLevel,
  }) {
    // Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    // Activity multipliers
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };

    final multiplier = multipliers[activityLevel.toLowerCase()] ?? 1.2;
    return (bmr * multiplier).round();
  }

  /// Generate meal plan
  MealPlan generateMealPlan({
    required int targetCalories,
    required String goal, // weight_loss, maintenance, muscle_gain
  }) {
    // Adjust calories based on goal
    int adjustedCalories = targetCalories;
    if (goal.toLowerCase().contains('loss')) {
      adjustedCalories = (targetCalories * 0.8).round(); // 20% deficit
    } else if (goal.toLowerCase().contains('gain')) {
      adjustedCalories = (targetCalories * 1.15).round(); // 15% surplus
    }

    // Calculate macros (40% carbs, 30% protein, 30% fat for balanced diet)
    final proteinG = (adjustedCalories * 0.3 / 4).round(); // 4 cal per g
    final carbsG = (adjustedCalories * 0.4 / 4).round();
    final fatG = (adjustedCalories * 0.3 / 9).round(); // 9 cal per g

    final meals = <String>[];

    // Breakfast (25% of calories)
    meals.add('Breakfast: Oatmeal with banana and almonds');

    // Lunch (35% of calories)
    meals.add('Lunch: Grilled chicken breast with rice and broccoli');

    // Dinner (30% of calories)
    meals.add('Dinner: Baked salmon with sweet potato and spinach');

    // Snack (10% of calories)
    meals.add('Snack: Greek yogurt with apple slices');

    return MealPlan(
      name: '${goal.toUpperCase()} Plan',
      targetCalories: adjustedCalories,
      meals: meals,
      macros: {
        'protein_g': proteinG.toDouble(),
        'carbs_g': carbsG.toDouble(),
        'fat_g': fatG.toDouble(),
      },
    );
  }

  /// Format food item for display
  String formatFoodItem(FoodItem food) {
    final buffer = StringBuffer();
    buffer.writeln('🍎 ${food.name}');
    buffer.writeln('📊 Per ${food.servingSize}${food.servingUnit}:');
    buffer.writeln('   Calories: ${food.calories.round()} kcal');
    buffer.writeln('   Protein: ${food.protein.toStringAsFixed(1)}g');
    buffer.writeln('   Carbs: ${food.carbs.toStringAsFixed(1)}g');
    buffer.writeln('   Fat: ${food.fat.toStringAsFixed(1)}g');
    if (food.fiber > 0) {
      buffer.writeln('   Fiber: ${food.fiber.toStringAsFixed(1)}g');
    }
    if (food.sugar > 0) {
      buffer.writeln('   Sugar: ${food.sugar.toStringAsFixed(1)}g');
    }
    return buffer.toString();
  }

  /// Get nutrition summary for a food
  Future<String> getFoodNutrition(String foodName) async {
    try {
      final foods = await getNutritionInfo(foodName);

      if (foods.isEmpty) {
        return 'No nutrition information found for "$foodName"';
      }

      final buffer = StringBuffer('🍽️ Nutrition Information:\n\n');

      for (var i = 0; i < foods.length && i < 3; i++) {
        buffer.writeln(formatFoodItem(foods[i]));
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get food nutrition', e, stackTrace);
      return 'Unable to fetch nutrition information.';
    }
  }

  /// Get calorie recommendation
  String getCalorieRecommendation({
    required int age,
    required String gender,
    required double weightKg,
    required double heightCm,
    required String activityLevel,
    String goal = 'maintenance',
  }) {
    final dailyCalories = calculateDailyCalories(
      age: age,
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      activityLevel: activityLevel,
    );

    final plan = generateMealPlan(targetCalories: dailyCalories, goal: goal);

    final buffer = StringBuffer('🎯 Your Nutrition Plan:\n\n');
    buffer.writeln('Goal: ${goal.toUpperCase()}');
    buffer.writeln('Daily Calories: ${plan.targetCalories} kcal\n');

    buffer.writeln('📊 Recommended Macros:');
    buffer.writeln('   Protein: ${plan.macros['protein_g']!.round()}g');
    buffer.writeln('   Carbs: ${plan.macros['carbs_g']!.round()}g');
    buffer.writeln('   Fat: ${plan.macros['fat_g']!.round()}g\n');

    buffer.writeln('🍽️ Sample Meal Plan:');
    for (var i = 0; i < plan.meals.length; i++) {
      buffer.writeln('${i + 1}. ${plan.meals[i]}');
    }

    return buffer.toString();
  }

  /// Get healthy eating tips
  String getHealthyEatingTips() {
    return '''
🥗 Healthy Eating Tips:

1. 💧 Drink plenty of water (8-10 glasses/day)
2. 🥦 Eat 5 servings of fruits & vegetables daily
3. 🍗 Choose lean protein sources
4. 🌾 Include whole grains in your diet
5. 🚫 Limit processed foods and added sugars
6. ⏰ Eat regular meals, don't skip breakfast
7. 🥜 Include healthy fats (nuts, avocado, fish)
8. 🍽️ Control portion sizes
9. 🏃 Combine healthy eating with regular exercise
10. 😴 Get adequate sleep for metabolism

💡 Remember: Consistency is key for long-term health!
''';
  }
}
