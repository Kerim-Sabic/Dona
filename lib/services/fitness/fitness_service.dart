import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys.dart';

/// Exercise model
class Exercise {
  final String name;
  final String type;
  final String muscle;
  final String equipment;
  final String difficulty;
  final String instructions;

  Exercise({
    required this.name,
    required this.type,
    required this.muscle,
    required this.equipment,
    required this.difficulty,
    required this.instructions,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      muscle: json['muscle'] ?? '',
      equipment: json['equipment'] ?? '',
      difficulty: json['difficulty'] ?? '',
      instructions: json['instructions'] ?? '',
    );
  }
}

/// Workout plan model
class WorkoutPlan {
  final String name;
  final String goal;
  final String level;
  final int durationMinutes;
  final List<String> exercises;

  WorkoutPlan({
    required this.name,
    required this.goal,
    required this.level,
    required this.durationMinutes,
    required this.exercises,
  });
}

/// Fitness & Workout Service
/// Uses API-Ninjas Exercises API (FREE with API key)
/// https://api-ninjas.com/api/exercises
class FitnessService {
  static final FitnessService _instance = FitnessService._internal();
  static FitnessService get instance => _instance;

  FitnessService._internal();

  static const String _baseUrl = 'https://api.api-ninjas.com/v1/exercises';
  static const Duration _timeout = Duration(seconds: 15);

  String get _apiKey => ApiKeys.apiNinjasKey;

  // Built-in exercise database for offline/fallback mode
  static const List<Map<String, String>> _builtInExercises = [
    {
      'name': 'Push-ups',
      'type': 'strength',
      'muscle': 'chest',
      'equipment': 'body_only',
      'difficulty': 'beginner',
      'instructions': 'Start in a plank position, lower your body until chest nearly touches floor, push back up.',
    },
    {
      'name': 'Squats',
      'type': 'strength',
      'muscle': 'quadriceps',
      'equipment': 'body_only',
      'difficulty': 'beginner',
      'instructions': 'Stand with feet shoulder-width apart, lower body as if sitting, return to standing.',
    },
    {
      'name': 'Plank',
      'type': 'strength',
      'muscle': 'abdominals',
      'equipment': 'body_only',
      'difficulty': 'beginner',
      'instructions': 'Hold your body in a straight line on your forearms and toes for 30-60 seconds.',
    },
    {
      'name': 'Lunges',
      'type': 'strength',
      'muscle': 'quadriceps',
      'equipment': 'body_only',
      'difficulty': 'beginner',
      'instructions': 'Step forward with one leg, lower hips until both knees are bent at 90 degrees, return to start.',
    },
    {
      'name': 'Jumping Jacks',
      'type': 'cardio',
      'muscle': 'full_body',
      'equipment': 'body_only',
      'difficulty': 'beginner',
      'instructions': 'Jump while spreading legs and raising arms overhead, return to starting position.',
    },
    {
      'name': 'Burpees',
      'type': 'cardio',
      'muscle': 'full_body',
      'equipment': 'body_only',
      'difficulty': 'intermediate',
      'instructions': 'Start standing, drop to plank, do push-up, jump feet forward, jump up with arms raised.',
    },
    {
      'name': 'Mountain Climbers',
      'type': 'cardio',
      'muscle': 'abdominals',
      'equipment': 'body_only',
      'difficulty': 'intermediate',
      'instructions': 'Start in plank, alternate bringing knees toward chest in running motion.',
    },
    {
      'name': 'Pull-ups',
      'type': 'strength',
      'muscle': 'lats',
      'equipment': 'pull_up_bar',
      'difficulty': 'intermediate',
      'instructions': 'Hang from bar with overhand grip, pull body up until chin is above bar, lower back down.',
    },
    {
      'name': 'Deadlifts',
      'type': 'strength',
      'muscle': 'lower_back',
      'equipment': 'barbell',
      'difficulty': 'intermediate',
      'instructions': 'Stand with barbell at shins, grip bar, keep back straight, lift by extending hips and knees.',
    },
    {
      'name': 'Bench Press',
      'type': 'strength',
      'muscle': 'chest',
      'equipment': 'barbell',
      'difficulty': 'intermediate',
      'instructions': 'Lie on bench, lower barbell to chest, press back up to starting position.',
    },
  ];

  Future<void> init() async {
    AppLogger.info('FitnessService initialized');
  }

  /// Get exercises by muscle group
  Future<List<Exercise>> getExercisesByMuscle(String muscle) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('API Ninjas key not configured, using built-in exercises');
        return _getBuiltInExercises(muscle: muscle);
      }

      AppLogger.debug('Fetching exercises for muscle: $muscle');

      final params = {'muscle': muscle.toLowerCase()};
      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {'X-Api-Key': _apiKey},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Exercise.fromJson(e)).toList();
      }

      // Fallback to built-in
      return _getBuiltInExercises(muscle: muscle);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch exercises', e, stackTrace);
      return _getBuiltInExercises(muscle: muscle);
    }
  }

  /// Get exercises by type (cardio, strength, etc.)
  Future<List<Exercise>> getExercisesByType(String type) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('API Ninjas key not configured, using built-in exercises');
        return _getBuiltInExercises(type: type);
      }

      AppLogger.debug('Fetching $type exercises...');

      final params = {'type': type.toLowerCase()};
      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {'X-Api-Key': _apiKey},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Exercise.fromJson(e)).toList();
      }

      // Fallback to built-in
      return _getBuiltInExercises(type: type);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch exercises', e, stackTrace);
      return _getBuiltInExercises(type: type);
    }
  }

  /// Get exercises by difficulty
  Future<List<Exercise>> getExercisesByDifficulty(String difficulty) async {
    try {
      if (_apiKey.isEmpty) {
        AppLogger.warning('API Ninjas key not configured, using built-in exercises');
        return _getBuiltInExercises(difficulty: difficulty);
      }

      AppLogger.debug('Fetching $difficulty exercises...');

      final params = {'difficulty': difficulty.toLowerCase()};
      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {'X-Api-Key': _apiKey},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Exercise.fromJson(e)).toList();
      }

      // Fallback to built-in
      return _getBuiltInExercises(difficulty: difficulty);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch exercises', e, stackTrace);
      return _getBuiltInExercises(difficulty: difficulty);
    }
  }

  /// Get built-in exercises with filters
  List<Exercise> _getBuiltInExercises({
    String? muscle,
    String? type,
    String? difficulty,
  }) {
    var exercises = _builtInExercises.map((e) => Exercise.fromJson(e)).toList();

    if (muscle != null) {
      exercises = exercises
          .where((e) => e.muscle.toLowerCase().contains(muscle.toLowerCase()))
          .toList();
    }

    if (type != null) {
      exercises = exercises
          .where((e) => e.type.toLowerCase() == type.toLowerCase())
          .toList();
    }

    if (difficulty != null) {
      exercises = exercises
          .where((e) => e.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();
    }

    return exercises;
  }

  /// Generate workout plan
  WorkoutPlan generateWorkoutPlan({
    required String goal,
    required String level,
    required int durationMinutes,
  }) {
    final exerciseList = <String>[];

    if (goal.toLowerCase().contains('strength') || goal.toLowerCase().contains('muscle')) {
      exerciseList.addAll(['Push-ups', 'Squats', 'Plank', 'Lunges']);
      if (level != 'beginner') {
        exerciseList.addAll(['Pull-ups', 'Deadlifts', 'Bench Press']);
      }
    } else if (goal.toLowerCase().contains('cardio') || goal.toLowerCase().contains('weight loss')) {
      exerciseList.addAll(['Jumping Jacks', 'Mountain Climbers', 'Burpees', 'Lunges']);
    } else {
      // General fitness
      exerciseList.addAll(['Push-ups', 'Squats', 'Jumping Jacks', 'Plank', 'Lunges']);
    }

    return WorkoutPlan(
      name: 'Custom $goal Workout',
      goal: goal,
      level: level,
      durationMinutes: durationMinutes,
      exercises: exerciseList,
    );
  }

  /// Format exercise for display
  String formatExercise(Exercise exercise) {
    final buffer = StringBuffer();
    buffer.writeln('💪 ${exercise.name}');
    buffer.writeln('🎯 Muscle: ${exercise.muscle}');
    buffer.writeln('⚙️ Equipment: ${exercise.equipment}');
    buffer.writeln('📊 Difficulty: ${exercise.difficulty}');
    buffer.writeln('\n📝 Instructions:');
    buffer.writeln(exercise.instructions);
    return buffer.toString();
  }

  /// Get workout recommendations
  Future<String> getWorkoutRecommendations({String? goal, String? level}) async {
    try {
      final targetLevel = level ?? 'beginner';
      final exercises = await getExercisesByDifficulty(targetLevel);

      if (exercises.isEmpty) {
        return 'No exercises found for your level.';
      }

      final buffer = StringBuffer('💪 Workout Recommendations:\n\n');

      if (goal != null) {
        buffer.writeln('Goal: $goal');
        buffer.writeln('Level: $targetLevel\n');
      }

      for (var i = 0; i < exercises.length && i < 5; i++) {
        buffer.writeln('${i + 1}. ${exercises[i].name}');
        buffer.writeln('   Target: ${exercises[i].muscle}');
        buffer.writeln('   Equipment: ${exercises[i].equipment}\n');
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get workout recommendations', e, stackTrace);
      return 'Unable to fetch workout recommendations.';
    }
  }

  /// Get quick workout routine
  Future<String> getQuickWorkout({int durationMinutes = 15}) async {
    try {
      final plan = generateWorkoutPlan(
        goal: 'General Fitness',
        level: 'beginner',
        durationMinutes: durationMinutes,
      );

      final buffer = StringBuffer('🏋️ Quick ${durationMinutes}-Minute Workout:\n\n');

      for (var i = 0; i < plan.exercises.length; i++) {
        final exerciseName = plan.exercises[i];
        buffer.writeln('${i + 1}. $exerciseName');

        // Get details for this exercise
        final details = _builtInExercises.firstWhere(
          (e) => e['name'] == exerciseName,
          orElse: () => {'name': exerciseName, 'instructions': 'Perform exercise'},
        );

        buffer.writeln('   ${details['instructions']}\n');
      }

      buffer.writeln('💡 Tip: Perform each exercise for 45 seconds with 15 seconds rest.');

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get quick workout', e, stackTrace);
      return 'Unable to generate workout routine.';
    }
  }
}
