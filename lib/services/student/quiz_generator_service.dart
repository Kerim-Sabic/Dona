import 'dart:convert';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../ai/ai_service.dart';
import 'flashcard_generator_service.dart';

/// Quiz Generator Service
/// AI-powered quiz generation with auto-grading
class QuizGeneratorService {
  static final QuizGeneratorService _instance = QuizGeneratorService._internal();
  static QuizGeneratorService get instance => _instance;

  QuizGeneratorService._internal();

  List<Quiz> _quizzes = [];
  List<QuizAttempt> _attempts = [];

  /// Initialize quiz service
  Future<void> init() async {
    try {
      await _loadQuizzes();
      await _loadAttempts();
      AppLogger.info('QuizGeneratorService initialized with ${_quizzes.length} quizzes');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize QuizGeneratorService', e, stackTrace);
    }
  }

  /// Generate quiz from text using AI
  Future<Quiz> generateFromText({
    required String text,
    required String title,
    String? courseId,
    String? examId,
    int questionCount = 10,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    List<QuestionType>? questionTypes,
  }) async {
    try {
      AppLogger.info('Generating quiz from text: $title');

      final types = questionTypes ?? [
        QuestionType.multipleChoice,
        QuestionType.trueFalse,
        QuestionType.shortAnswer,
      ];

      final typesStr = types.map((t) => t.toString().split('.').last).join(', ');

      final prompt = '''
Create a $questionCount-question quiz from this text:

$text

Requirements:
- Return ONLY a JSON array of questions
- Include question types: $typesStr
- Difficulty level: ${difficulty.toString().split('.').last}
- Each question should have:
  * "type" (string: "multipleChoice", "trueFalse", "shortAnswer", or "essay")
  * "question" (string)
  * "correctAnswer" (string or boolean for true/false)
  * "options" (array of strings, for multiple choice only)
  * "explanation" (string - why this is the correct answer)
  * "points" (number 1-10)

Example format:
[
  {
    "type": "multipleChoice",
    "question": "What is photosynthesis?",
    "options": ["Process of making food", "Process of breathing", "Process of reproduction", "Process of growth"],
    "correctAnswer": "Process of making food",
    "explanation": "Photosynthesis is the process by which plants convert light energy into chemical energy",
    "points": 5
  },
  {
    "type": "trueFalse",
    "question": "Plants release oxygen during photosynthesis",
    "correctAnswer": true,
    "explanation": "During photosynthesis, plants release oxygen as a byproduct",
    "points": 3
  },
  {
    "type": "shortAnswer",
    "question": "What is the chemical formula for glucose produced in photosynthesis?",
    "correctAnswer": "C6H12O6",
    "explanation": "Glucose has the molecular formula C6H12O6",
    "points": 5
  }
]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        // Extract JSON from response
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          final questions = data.map((item) {
            final typeStr = item['type'] as String;
            QuestionType type;
            if (typeStr == 'multipleChoice') {
              type = QuestionType.multipleChoice;
            } else if (typeStr == 'trueFalse') {
              type = QuestionType.trueFalse;
            } else if (typeStr == 'shortAnswer') {
              type = QuestionType.shortAnswer;
            } else {
              type = QuestionType.essay;
            }

            dynamic correctAnswer = item['correctAnswer'];
            if (type == QuestionType.trueFalse && correctAnswer is String) {
              correctAnswer = correctAnswer.toLowerCase() == 'true';
            }

            return QuizQuestion(
              id: DateTime.now().millisecondsSinceEpoch.toString() + data.indexOf(item).toString(),
              type: type,
              question: item['question'] as String,
              options: type == QuestionType.multipleChoice
                ? (item['options'] as List<dynamic>).map((o) => o as String).toList()
                : null,
              correctAnswer: correctAnswer,
              explanation: item['explanation'] as String?,
              points: (item['points'] as num?)?.toInt() ?? 5,
            );
          }).toList();

          final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);

          final quiz = Quiz(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: 'AI-generated quiz',
            questions: questions,
            totalPoints: totalPoints,
            courseId: courseId,
            examId: examId,
            difficulty: difficulty,
            created: DateTime.now(),
          );

          _quizzes.add(quiz);
          await _saveQuizzes();

          AppLogger.info('Generated quiz with ${questions.length} questions');
          return quiz;
        }
      } catch (e) {
        AppLogger.warning('Could not parse AI quiz: $e');
      }

      // Fallback: create empty quiz
      return _createFallbackQuiz(title, courseId, examId, difficulty);
    } catch (e, stackTrace) {
      AppLogger.error('Error generating quiz from text', e, stackTrace);
      rethrow;
    }
  }

  /// Generate quiz from topics
  Future<Quiz> generateFromTopics({
    required List<String> topics,
    required String title,
    String? courseId,
    String? examId,
    int questionsPerTopic = 2,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    List<QuestionType>? questionTypes,
  }) async {
    try {
      AppLogger.info('Generating quiz from topics: $title');

      final types = questionTypes ?? [QuestionType.multipleChoice, QuestionType.trueFalse];
      final typesStr = types.map((t) => t.toString().split('.').last).join(', ');

      final prompt = '''
Create a comprehensive quiz covering these topics:

${topics.map((t) => '- $t').join('\n')}

Requirements:
- Create $questionsPerTopic questions per topic
- Question types: $typesStr
- Difficulty: ${difficulty.toString().split('.').last}
- Return ONLY a JSON array of questions
- Each question must have: "type", "question", "correctAnswer", "explanation", "points", "topic"
- For multiple choice, include "options" array

Format example:
[
  {
    "type": "multipleChoice",
    "question": "What is mitosis?",
    "options": ["Cell division", "Cell death", "Cell growth", "Cell mutation"],
    "correctAnswer": "Cell division",
    "explanation": "Mitosis is the process of cell division",
    "points": 5,
    "topic": "Cell Biology"
  }
]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          final questions = data.map((item) {
            final typeStr = item['type'] as String;
            QuestionType type;
            if (typeStr == 'multipleChoice') {
              type = QuestionType.multipleChoice;
            } else if (typeStr == 'trueFalse') {
              type = QuestionType.trueFalse;
            } else if (typeStr == 'shortAnswer') {
              type = QuestionType.shortAnswer;
            } else {
              type = QuestionType.essay;
            }

            dynamic correctAnswer = item['correctAnswer'];
            if (type == QuestionType.trueFalse && correctAnswer is String) {
              correctAnswer = correctAnswer.toLowerCase() == 'true';
            }

            return QuizQuestion(
              id: DateTime.now().millisecondsSinceEpoch.toString() + data.indexOf(item).toString(),
              type: type,
              question: item['question'] as String,
              options: type == QuestionType.multipleChoice
                ? (item['options'] as List<dynamic>).map((o) => o as String).toList()
                : null,
              correctAnswer: correctAnswer,
              explanation: item['explanation'] as String?,
              points: (item['points'] as num?)?.toInt() ?? 5,
              tags: [item['topic'] as String? ?? ''],
            );
          }).toList();

          final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);

          final quiz = Quiz(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: 'AI-generated from topics: ${topics.join(", ")}',
            questions: questions,
            totalPoints: totalPoints,
            courseId: courseId,
            examId: examId,
            difficulty: difficulty,
            created: DateTime.now(),
          );

          _quizzes.add(quiz);
          await _saveQuizzes();

          AppLogger.info('Generated quiz with ${questions.length} questions from ${topics.length} topics');
          return quiz;
        }
      } catch (e) {
        AppLogger.warning('Could not parse AI quiz: $e');
      }

      return _createFallbackQuiz(title, courseId, examId, difficulty);
    } catch (e, stackTrace) {
      AppLogger.error('Error generating quiz from topics', e, stackTrace);
      rethrow;
    }
  }

  /// Generate quiz from flashcard deck
  Future<Quiz> generateFromFlashcards({
    required String deckId,
    required String title,
    int? questionCount,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
  }) async {
    try {
      final deck = FlashcardGeneratorService.instance.getDeck(deckId);
      if (deck == null) {
        throw Exception('Flashcard deck not found: $deckId');
      }

      AppLogger.info('Generating quiz from flashcard deck: ${deck.title}');

      final count = questionCount ?? deck.flashcards.length.clamp(5, 20);
      final selectedCards = deck.flashcards.take(count).toList();

      final questions = selectedCards.map((card) {
        // Convert flashcard to quiz question
        return QuizQuestion(
          id: DateTime.now().millisecondsSinceEpoch.toString() + selectedCards.indexOf(card).toString(),
          type: QuestionType.shortAnswer,
          question: card.question,
          correctAnswer: card.answer,
          explanation: card.hint ?? card.answer,
          points: 5,
        );
      }).toList();

      final quiz = Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: 'Generated from flashcard deck: ${deck.title}',
        questions: questions,
        totalPoints: questions.length * 5,
        courseId: deck.courseId,
        examId: deck.examId,
        difficulty: difficulty,
        created: DateTime.now(),
      );

      _quizzes.add(quiz);
      await _saveQuizzes();

      AppLogger.info('Generated quiz with ${questions.length} questions from flashcards');
      return quiz;
    } catch (e, stackTrace) {
      AppLogger.error('Error generating quiz from flashcards', e, stackTrace);
      rethrow;
    }
  }

  /// Create a manual quiz
  Future<Quiz> createQuiz({
    required String title,
    String? description,
    required List<QuizQuestion> questions,
    String? courseId,
    String? examId,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    int? timeLimit,
  }) async {
    try {
      final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);

      final quiz = Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        questions: questions,
        totalPoints: totalPoints,
        courseId: courseId,
        examId: examId,
        difficulty: difficulty,
        timeLimit: timeLimit != null ? Duration(minutes: timeLimit) : null,
        created: DateTime.now(),
      );

      _quizzes.add(quiz);
      await _saveQuizzes();

      AppLogger.info('Created quiz: $title');
      return quiz;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating quiz', e, stackTrace);
      rethrow;
    }
  }

  /// Start a quiz attempt
  Future<QuizAttempt> startQuizAttempt(String quizId) async {
    try {
      final quiz = getQuiz(quizId);
      if (quiz == null) {
        throw Exception('Quiz not found: $quizId');
      }

      final attempt = QuizAttempt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: quizId,
        startedAt: DateTime.now(),
        answers: {},
      );

      _attempts.add(attempt);
      await _saveAttempts();

      AppLogger.info('Started quiz attempt: $quizId');
      return attempt;
    } catch (e, stackTrace) {
      AppLogger.error('Error starting quiz attempt', e, stackTrace);
      rethrow;
    }
  }

  /// Submit answer for a question
  Future<void> submitAnswer(String attemptId, String questionId, dynamic answer) async {
    try {
      final index = _attempts.indexWhere((a) => a.id == attemptId);
      if (index != -1) {
        final attempt = _attempts[index];
        final updatedAnswers = Map<String, dynamic>.from(attempt.answers);
        updatedAnswers[questionId] = answer;

        _attempts[index] = QuizAttempt(
          id: attempt.id,
          quizId: attempt.quizId,
          startedAt: attempt.startedAt,
          completedAt: attempt.completedAt,
          answers: updatedAnswers,
          score: attempt.score,
          feedback: attempt.feedback,
        );

        await _saveAttempts();
        AppLogger.debug('Submitted answer for question: $questionId');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error submitting answer', e, stackTrace);
    }
  }

  /// Complete quiz attempt and grade it
  Future<QuizResult> completeQuizAttempt(String attemptId) async {
    try {
      final index = _attempts.indexWhere((a) => a.id == attemptId);
      if (index == -1) {
        throw Exception('Quiz attempt not found: $attemptId');
      }

      final attempt = _attempts[index];
      final quiz = getQuiz(attempt.quizId);
      if (quiz == null) {
        throw Exception('Quiz not found: ${attempt.quizId}');
      }

      // Grade the quiz
      int earnedPoints = 0;
      final questionResults = <QuestionResult>[];

      for (final question in quiz.questions) {
        final userAnswer = attempt.answers[question.id];
        final isCorrect = _gradeQuestion(question, userAnswer);

        questionResults.add(QuestionResult(
          questionId: question.id,
          userAnswer: userAnswer,
          correctAnswer: question.correctAnswer,
          isCorrect: isCorrect,
          pointsEarned: isCorrect ? question.points : 0,
          explanation: question.explanation,
        ));

        if (isCorrect) {
          earnedPoints += question.points;
        }
      }

      final percentage = (earnedPoints / quiz.totalPoints) * 100;
      final passed = percentage >= 60;

      final result = QuizResult(
        attemptId: attemptId,
        quizId: quiz.id,
        earnedPoints: earnedPoints,
        totalPoints: quiz.totalPoints,
        percentage: percentage,
        passed: passed,
        questionResults: questionResults,
        completedAt: DateTime.now(),
      );

      // Update attempt
      _attempts[index] = QuizAttempt(
        id: attempt.id,
        quizId: attempt.quizId,
        startedAt: attempt.startedAt,
        completedAt: DateTime.now(),
        answers: attempt.answers,
        score: earnedPoints,
      );

      await _saveAttempts();

      AppLogger.info('Completed quiz: ${quiz.title} - Score: $earnedPoints/${ quiz.totalPoints} (${percentage.toStringAsFixed(1)}%)');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Error completing quiz attempt', e, stackTrace);
      rethrow;
    }
  }

  /// Grade a single question
  bool _gradeQuestion(QuizQuestion question, dynamic userAnswer) {
    if (userAnswer == null) return false;

    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        // Exact match
        return userAnswer.toString().toLowerCase() ==
               question.correctAnswer.toString().toLowerCase();

      case QuestionType.shortAnswer:
        // Flexible matching for short answers
        final userStr = userAnswer.toString().toLowerCase().trim();
        final correctStr = question.correctAnswer.toString().toLowerCase().trim();

        // Exact match
        if (userStr == correctStr) return true;

        // Allow for minor variations (remove punctuation, extra spaces)
        final cleanUser = userStr.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');
        final cleanCorrect = correctStr.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');

        return cleanUser == cleanCorrect;

      case QuestionType.essay:
        // Manual grading required
        return false;
    }
  }

  /// Delete quiz
  Future<bool> deleteQuiz(String quizId) async {
    try {
      final removedCount = _quizzes.removeWhere((q) => q.id == quizId);
      if (removedCount > 0) {
        // Also delete related attempts
        _attempts.removeWhere((a) => a.quizId == quizId);

        await _saveQuizzes();
        await _saveAttempts();

        AppLogger.info('Deleted quiz: $quizId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting quiz', e, stackTrace);
      return false;
    }
  }

  /// Get quiz by ID
  Quiz? getQuiz(String quizId) {
    try {
      return _quizzes.firstWhere((q) => q.id == quizId);
    } catch (e) {
      return null;
    }
  }

  /// Get all quizzes
  List<Quiz> get allQuizzes => List.unmodifiable(_quizzes);

  /// Get quizzes for course
  List<Quiz> getQuizzesForCourse(String courseId) =>
      _quizzes.where((q) => q.courseId == courseId).toList();

  /// Get quizzes for exam
  List<Quiz> getQuizzesForExam(String examId) =>
      _quizzes.where((q) => q.examId == examId).toList();

  /// Get attempts for quiz
  List<QuizAttempt> getAttemptsForQuiz(String quizId) =>
      _attempts.where((a) => a.quizId == quizId).toList();

  /// Get quiz statistics
  QuizStatistics getQuizStatistics(String quizId) {
    final attempts = getAttemptsForQuiz(quizId);
    final completedAttempts = attempts.where((a) => a.completedAt != null).toList();

    if (completedAttempts.isEmpty) {
      return QuizStatistics(
        quizId: quizId,
        totalAttempts: attempts.length,
        completedAttempts: 0,
        averageScore: 0.0,
        highestScore: 0,
        lowestScore: 0,
      );
    }

    final scores = completedAttempts.map((a) => a.score ?? 0).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final highest = scores.reduce((a, b) => a > b ? a : b);
    final lowest = scores.reduce((a, b) => a < b ? a : b);

    return QuizStatistics(
      quizId: quizId,
      totalAttempts: attempts.length,
      completedAttempts: completedAttempts.length,
      averageScore: avgScore.toDouble(),
      highestScore: highest,
      lowestScore: lowest,
    );
  }

  /// Get overall statistics
  QuizOverallStatistics getOverallStatistics() {
    final totalQuizzes = _quizzes.length;
    final totalAttempts = _attempts.length;
    final completedAttempts = _attempts.where((a) => a.completedAt != null).length;

    final allStats = _quizzes.map((q) => getQuizStatistics(q.id)).toList();
    final avgPerformance = allStats.isEmpty ? 0.0 :
      allStats.fold<double>(0.0, (sum, s) => sum + s.averageScore) / allStats.length;

    return QuizOverallStatistics(
      totalQuizzes: totalQuizzes,
      totalAttempts: totalAttempts,
      completedAttempts: completedAttempts,
      averagePerformance: avgPerformance,
    );
  }

  /// Create fallback quiz when AI fails
  Quiz _createFallbackQuiz(String title, String? courseId, String? examId, QuestionDifficulty difficulty) {
    final quiz = Quiz(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: 'Quiz created',
      questions: [],
      totalPoints: 0,
      courseId: courseId,
      examId: examId,
      difficulty: difficulty,
      created: DateTime.now(),
    );

    _quizzes.add(quiz);
    return quiz;
  }

  /// Save quizzes
  Future<void> _saveQuizzes() async {
    try {
      final json = jsonEncode(_quizzes.map((q) => q.toJson()).toList());
      await LocalStorageService.instance.setString('quizzes', json);
      AppLogger.debug('Saved ${_quizzes.length} quizzes');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving quizzes', e, stackTrace);
    }
  }

  /// Load quizzes
  Future<void> _loadQuizzes() async {
    try {
      final json = LocalStorageService.instance.getString('quizzes');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _quizzes = data.map((item) => Quiz.fromJson(item)).toList();
        AppLogger.info('Loaded ${_quizzes.length} quizzes');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading quizzes', e, stackTrace);
    }
  }

  /// Save attempts
  Future<void> _saveAttempts() async {
    try {
      final json = jsonEncode(_attempts.map((a) => a.toJson()).toList());
      await LocalStorageService.instance.setString('quiz_attempts', json);
      AppLogger.debug('Saved ${_attempts.length} quiz attempts');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving attempts', e, stackTrace);
    }
  }

  /// Load attempts
  Future<void> _loadAttempts() async {
    try {
      final json = LocalStorageService.instance.getString('quiz_attempts');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _attempts = data.map((item) => QuizAttempt.fromJson(item)).toList();
        AppLogger.info('Loaded ${_attempts.length} quiz attempts');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading attempts', e, stackTrace);
    }
  }
}

/// Quiz question model
class QuizQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final List<String>? options; // For multiple choice
  final dynamic correctAnswer;
  final String? explanation;
  final int points;
  final List<String> tags;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.points = 5,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'question': question,
    if (options != null) 'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'points': points,
    'tags': tags,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      type: QuestionType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => QuestionType.shortAnswer,
      ),
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>?)?.map((o) => o as String).toList(),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'] as String?,
      points: json['points'] as int? ?? 5,
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ?? [],
    );
  }
}

/// Quiz model
class Quiz {
  final String id;
  final String title;
  final String? description;
  final List<QuizQuestion> questions;
  final int totalPoints;
  final String? courseId;
  final String? examId;
  final QuestionDifficulty difficulty;
  final Duration? timeLimit;
  final DateTime created;

  Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
    required this.totalPoints,
    this.courseId,
    this.examId,
    this.difficulty = QuestionDifficulty.medium,
    this.timeLimit,
    required this.created,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'questions': questions.map((q) => q.toJson()).toList(),
    'totalPoints': totalPoints,
    'courseId': courseId,
    'examId': examId,
    'difficulty': difficulty.toString(),
    'timeLimit': timeLimit?.inMinutes,
    'created': created.toIso8601String(),
  };

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      questions: (json['questions'] as List<dynamic>)
        .map((q) => QuizQuestion.fromJson(q))
        .toList(),
      totalPoints: json['totalPoints'] as int,
      courseId: json['courseId'] as String?,
      examId: json['examId'] as String?,
      difficulty: QuestionDifficulty.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      timeLimit: json['timeLimit'] != null
        ? Duration(minutes: json['timeLimit'] as int)
        : null,
      created: DateTime.parse(json['created'] as String),
    );
  }
}

/// Question types
enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  essay,
}

/// Question difficulty
enum QuestionDifficulty {
  easy,
  medium,
  hard,
  expert,
}

/// Quiz attempt model
class QuizAttempt {
  final String id;
  final String quizId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> answers;
  final int? score;
  final String? feedback;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.startedAt,
    this.completedAt,
    required this.answers,
    this.score,
    this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'quizId': quizId,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'answers': answers,
    'score': score,
    'feedback': feedback,
  };

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
      answers: Map<String, dynamic>.from(json['answers']),
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
    );
  }
}

/// Question result
class QuestionResult {
  final String questionId;
  final dynamic userAnswer;
  final dynamic correctAnswer;
  final bool isCorrect;
  final int pointsEarned;
  final String? explanation;

  QuestionResult({
    required this.questionId,
    this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.pointsEarned,
    this.explanation,
  });
}

/// Quiz result
class QuizResult {
  final String attemptId;
  final String quizId;
  final int earnedPoints;
  final int totalPoints;
  final double percentage;
  final bool passed;
  final List<QuestionResult> questionResults;
  final DateTime completedAt;

  QuizResult({
    required this.attemptId,
    required this.quizId,
    required this.earnedPoints,
    required this.totalPoints,
    required this.percentage,
    required this.passed,
    required this.questionResults,
    required this.completedAt,
  });

  @override
  String toString() {
    return '''
Quiz Result:
  Score: $earnedPoints/$totalPoints (${percentage.toStringAsFixed(1)}%)
  Status: ${passed ? 'PASSED ✅' : 'FAILED ❌'}
  Correct: ${questionResults.where((r) => r.isCorrect).length}/${questionResults.length}
  Completed: $completedAt
''';
  }
}

/// Quiz statistics
class QuizStatistics {
  final String quizId;
  final int totalAttempts;
  final int completedAttempts;
  final double averageScore;
  final int highestScore;
  final int lowestScore;

  QuizStatistics({
    required this.quizId,
    required this.totalAttempts,
    required this.completedAttempts,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
  });
}

/// Overall quiz statistics
class QuizOverallStatistics {
  final int totalQuizzes;
  final int totalAttempts;
  final int completedAttempts;
  final double averagePerformance;

  QuizOverallStatistics({
    required this.totalQuizzes,
    required this.totalAttempts,
    required this.completedAttempts,
    required this.averagePerformance,
  });

  @override
  String toString() {
    return '''
Quiz Statistics:
  Total Quizzes: $totalQuizzes
  Total Attempts: $totalAttempts
  Completed: $completedAttempts
  Average Score: ${averagePerformance.toStringAsFixed(1)}
''';
  }
}
