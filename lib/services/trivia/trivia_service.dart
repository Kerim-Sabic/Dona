import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Trivia question model
class TriviaQuestion {
  final String category;
  final String type;
  final String difficulty;
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  final List<String> allAnswers;

  TriviaQuestion({
    required this.category,
    required this.type,
    required this.difficulty,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    required this.allAnswers,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    final incorrect = List<String>.from(json['incorrect_answers'] ?? []);
    final correct = json['correct_answer'] ?? '';

    // Shuffle all answers together
    final all = [...incorrect, correct]..shuffle();

    return TriviaQuestion(
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      difficulty: json['difficulty'] ?? '',
      question: _decodeHtml(json['question'] ?? ''),
      correctAnswer: _decodeHtml(correct),
      incorrectAnswers: incorrect.map((a) => _decodeHtml(a)).toList(),
      allAnswers: all.map((a) => _decodeHtml(a)).toList(),
    );
  }

  static String _decodeHtml(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'");
  }

  bool isCorrect(String answer) {
    return answer.toLowerCase() == correctAnswer.toLowerCase();
  }
}

/// Category model
class TriviaCategory {
  final int id;
  final String name;

  TriviaCategory({required this.id, required this.name});

  factory TriviaCategory.fromJson(Map<String, dynamic> json) {
    return TriviaCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

/// Open Trivia Database Service
/// https://opentdb.com/ - Completely FREE, No API Key Required!
/// 4,000+ verified trivia questions across 24 categories
class TriviaService {
  static final TriviaService _instance = TriviaService._internal();
  static TriviaService get instance => _instance;

  TriviaService._internal();

  static const String _baseUrl = 'https://opentdb.com/api.php';
  static const String _categoriesUrl = 'https://opentdb.com/api_category.php';
  static const Duration _timeout = Duration(seconds: 15);

  // Category IDs for easy reference
  static const Map<String, int> categories = {
    'General Knowledge': 9,
    'Books': 10,
    'Film': 11,
    'Music': 12,
    'Musicals & Theatres': 13,
    'Television': 14,
    'Video Games': 15,
    'Board Games': 16,
    'Science & Nature': 17,
    'Computers': 18,
    'Mathematics': 19,
    'Mythology': 20,
    'Sports': 21,
    'Geography': 22,
    'History': 23,
    'Politics': 24,
    'Art': 25,
    'Celebrities': 26,
    'Animals': 27,
    'Vehicles': 28,
    'Comics': 29,
    'Gadgets': 30,
    'Anime & Manga': 31,
    'Cartoons & Animations': 32,
  };

  Future<void> init() async {
    AppLogger.info('TriviaService initialized with Open Trivia Database');
  }

  /// Get trivia questions
  Future<List<TriviaQuestion>> getQuestions({
    int amount = 10,
    int? categoryId,
    String? difficulty, // easy, medium, hard
    String? type, // multiple, boolean
  }) async {
    try {
      AppLogger.debug('Fetching $amount trivia questions...');

      final params = <String, String>{
        'amount': amount.toString(),
      };

      if (categoryId != null) {
        params['category'] = categoryId.toString();
      }
      if (difficulty != null) {
        params['difficulty'] = difficulty;
      }
      if (type != null) {
        params['type'] = type;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseCode = data['response_code'];

        if (responseCode == 0) {
          final results = data['results'] as List<dynamic>?;
          if (results != null) {
            return results
                .map((q) => TriviaQuestion.fromJson(q))
                .toList();
          }
        } else if (responseCode == 1) {
          AppLogger.warning('Not enough questions for specified criteria');
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch trivia questions', e, stackTrace);
      return [];
    }
  }

  /// Get all available categories
  Future<List<TriviaCategory>> getCategories() async {
    try {
      AppLogger.debug('Fetching trivia categories...');

      final url = Uri.parse(_categoriesUrl);
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categoryList = data['trivia_categories'] as List<dynamic>?;
        if (categoryList != null) {
          return categoryList
              .map((cat) => TriviaCategory.fromJson(cat))
              .toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch categories', e, stackTrace);
      return [];
    }
  }

  /// Get quick trivia quiz (10 random questions)
  Future<List<TriviaQuestion>> getQuickQuiz() async {
    return getQuestions(amount: 10);
  }

  /// Get category-specific quiz
  Future<List<TriviaQuestion>> getCategoryQuiz(String categoryName) async {
    final categoryId = categories[categoryName];
    if (categoryId == null) {
      AppLogger.warning('Unknown category: $categoryName');
      return [];
    }
    return getQuestions(amount: 10, categoryId: categoryId);
  }

  /// Get true/false quiz
  Future<List<TriviaQuestion>> getTrueFalseQuiz({int amount = 10}) async {
    return getQuestions(amount: amount, type: 'boolean');
  }

  /// Get multiple choice quiz
  Future<List<TriviaQuestion>> getMultipleChoiceQuiz({int amount = 10}) async {
    return getQuestions(amount: amount, type: 'multiple');
  }

  /// Get quiz by difficulty
  Future<List<TriviaQuestion>> getQuizByDifficulty(
    String difficulty, {
    int amount = 10,
  }) async {
    return getQuestions(amount: amount, difficulty: difficulty);
  }

  /// Format question for display
  String formatQuestion(TriviaQuestion question, int number) {
    final buffer = StringBuffer();
    buffer.writeln('🎯 Question $number:');
    buffer.writeln(question.question);
    buffer.writeln('\n📚 Category: ${question.category}');
    buffer.writeln('⚡ Difficulty: ${question.difficulty.toUpperCase()}');
    buffer.writeln('\nAnswers:');

    for (var i = 0; i < question.allAnswers.length; i++) {
      final letter = String.fromCharCode(65 + i); // A, B, C, D
      buffer.writeln('$letter) ${question.allAnswers[i]}');
    }

    return buffer.toString();
  }

  /// Get trivia summary
  Future<String> getTriviaQuizSummary({String? category}) async {
    try {
      final questions = category != null
          ? await getCategoryQuiz(category)
          : await getQuickQuiz();

      if (questions.isEmpty) {
        return 'Unable to fetch trivia questions at this time.';
      }

      final buffer = StringBuffer('🎮 TRIVIA QUIZ TIME! 🎮\n\n');

      if (category != null) {
        buffer.writeln('Category: $category\n');
      }

      buffer.writeln('${questions.length} Questions Ready!\n');
      buffer.writeln('First question:');
      buffer.writeln(formatQuestion(questions.first, 1));
      buffer.writeln('\n💡 Say your answer to continue!');

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trivia summary', e, stackTrace);
      return 'Unable to start trivia quiz.';
    }
  }
}
