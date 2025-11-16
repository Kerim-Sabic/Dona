/// Quiz Models
/// Data models for quiz generation, attempts, and results

/// Question types
enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  essay,
}

/// Question difficulty levels
enum QuestionDifficulty {
  easy,
  medium,
  hard,
  expert,
}

/// Quiz Question model
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
      questions: (json['questions'] as List<dynamic>).map((q) => QuizQuestion.fromJson(q)).toList(),
      totalPoints: json['totalPoints'] as int,
      courseId: json['courseId'] as String?,
      examId: json['examId'] as String?,
      difficulty: QuestionDifficulty.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      timeLimit: json['timeLimit'] != null ? Duration(minutes: json['timeLimit'] as int) : null,
      created: DateTime.parse(json['created'] as String),
    );
  }
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
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      answers: Map<String, dynamic>.from(json['answers']),
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
    );
  }
}

/// Question result model
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

/// Quiz result model
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

/// Quiz statistics model
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

/// Overall quiz statistics model
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
  Average Score: ${averagePerformance.toStringAsFixed(1)}%
''';
  }
}
