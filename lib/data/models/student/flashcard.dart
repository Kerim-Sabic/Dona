/// Flashcard Models
/// Data models for flashcard generation, decks, and spaced repetition

/// Flashcard types
enum FlashcardType {
  basic, // Question/Answer
  cloze, // Fill in the blank
  image, // Image-based question
  multiChoice, // Multiple choice (future)
}

/// Review quality (for spaced repetition)
enum ReviewQuality {
  again, // Didn't remember
  hard, // Remembered with difficulty
  good, // Remembered correctly
  easy, // Remembered easily
}

/// Flashcard model
class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String? hint;
  final FlashcardType type;
  final List<String> tags;
  final String? imageUrl;
  final DateTime created;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.hint,
    this.type = FlashcardType.basic,
    this.tags = const [],
    this.imageUrl,
    required this.created,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'hint': hint,
        'type': type.toString(),
        'tags': tags,
        'imageUrl': imageUrl,
        'created': created.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      hint: json['hint'] as String?,
      type: FlashcardType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => FlashcardType.basic,
      ),
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ?? [],
      imageUrl: json['imageUrl'] as String?,
      created: DateTime.parse(json['created'] as String),
    );
  }
}

/// Flashcard deck model
class FlashcardDeck {
  final String id;
  final String title;
  final String? description;
  final List<Flashcard> flashcards;
  final String? courseId;
  final String? examId;
  final DateTime created;
  final DateTime? lastStudied;

  FlashcardDeck({
    required this.id,
    required this.title,
    this.description,
    required this.flashcards,
    this.courseId,
    this.examId,
    required this.created,
    this.lastStudied,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'courseId': courseId,
        'examId': examId,
        'created': created.toIso8601String(),
        'lastStudied': lastStudied?.toIso8601String(),
      };

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      flashcards: (json['flashcards'] as List<dynamic>).map((f) => Flashcard.fromJson(f)).toList(),
      courseId: json['courseId'] as String?,
      examId: json['examId'] as String?,
      created: DateTime.parse(json['created'] as String),
      lastStudied: json['lastStudied'] != null ? DateTime.parse(json['lastStudied'] as String) : null,
    );
  }
}

/// Flashcard review record
class FlashcardReview {
  final String id;
  final String deckId;
  final String flashcardId;
  final ReviewQuality quality;
  final DateTime reviewedAt;

  FlashcardReview({
    required this.id,
    required this.deckId,
    required this.flashcardId,
    required this.quality,
    required this.reviewedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'flashcardId': flashcardId,
        'quality': quality.toString(),
        'reviewedAt': reviewedAt.toIso8601String(),
      };

  factory FlashcardReview.fromJson(Map<String, dynamic> json) {
    return FlashcardReview(
      id: json['id'] as String,
      deckId: json['deckId'] as String,
      flashcardId: json['flashcardId'] as String,
      quality: ReviewQuality.values.firstWhere(
        (q) => q.toString() == json['quality'],
        orElse: () => ReviewQuality.again,
      ),
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
    );
  }
}

/// Deck statistics model
class DeckStatistics {
  final String deckId;
  final int totalCards;
  final int cardsReviewed;
  final int cardsDue;
  final double masteryRate;
  final int? totalReviews;
  final DateTime? lastStudied;

  DeckStatistics({
    required this.deckId,
    required this.totalCards,
    required this.cardsReviewed,
    required this.cardsDue,
    required this.masteryRate,
    this.totalReviews,
    this.lastStudied,
  });

  @override
  String toString() {
    return '''
Deck Statistics:
  Total Cards: $totalCards
  Cards Reviewed: $cardsReviewed
  Cards Due: $cardsDue
  Mastery Rate: ${masteryRate.toStringAsFixed(1)}%
  ${totalReviews != null ? 'Total Reviews: $totalReviews' : ''}
  ${lastStudied != null ? 'Last Studied: $lastStudied' : 'Never studied'}
''';
  }
}

/// Overall flashcard statistics model
class FlashcardOverallStatistics {
  final int totalDecks;
  final int totalCards;
  final int totalReviews;
  final double averageMastery;
  final int cardsDueToday;

  FlashcardOverallStatistics({
    required this.totalDecks,
    required this.totalCards,
    required this.totalReviews,
    required this.averageMastery,
    required this.cardsDueToday,
  });

  @override
  String toString() {
    return '''
Flashcard Statistics:
  Total Decks: $totalDecks
  Total Cards: $totalCards
  Total Reviews: $totalReviews
  Average Mastery: ${averageMastery.toStringAsFixed(1)}%
  Cards Due Today: $cardsDueToday
''';
  }
}
