import 'dart:convert';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../ai/ai_service.dart';
import '../../data/models/student/flashcard.dart';
import 'course_manager.dart';

/// Flashcard Generator Service
/// AI-powered flashcard generation with spaced repetition algorithm
class FlashcardGeneratorService {
  static final FlashcardGeneratorService _instance = FlashcardGeneratorService._internal();
  static FlashcardGeneratorService get instance => _instance;

  FlashcardGeneratorService._internal();

  List<FlashcardDeck> _decks = [];
  List<FlashcardReview> _reviews = [];

  /// Initialize flashcard service
  Future<void> init() async {
    try {
      await _loadDecks();
      await _loadReviews();
      AppLogger.info('FlashcardGeneratorService initialized with ${_decks.length} decks');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize FlashcardGeneratorService', e, stackTrace);
    }
  }

  /// Generate flashcards from text using AI
  Future<FlashcardDeck> generateFromText({
    required String text,
    required String title,
    String? courseId,
    String? examId,
    int? targetCount,
  }) async {
    try {
      AppLogger.info('Generating flashcards from text: $title');

      final count = targetCount ?? 10;

      final prompt = '''
Create $count high-quality flashcards from this text:

$text

Requirements:
- Return ONLY a JSON array of flashcards
- Each flashcard should have: "question" (string), "answer" (string), "hint" (optional string)
- Questions should test understanding, not just memorization
- Answers should be concise but complete
- Focus on key concepts, definitions, and relationships
- Use active recall principles

Example format:
[
  {
    "question": "What is photosynthesis?",
    "answer": "The process by which plants convert light energy into chemical energy stored in glucose",
    "hint": "Think about how plants make food"
  },
  {
    "question": "What is the chemical equation for photosynthesis?",
    "answer": "6CO2 + 6H2O + light energy → C6H12O6 + 6O2"
  }
]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        // Extract JSON from response
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          final flashcards = data.map((item) {
            return Flashcard(
              id: DateTime.now().millisecondsSinceEpoch.toString() + data.indexOf(item).toString(),
              question: item['question'] as String,
              answer: item['answer'] as String,
              hint: item['hint'] as String?,
              type: FlashcardType.basic,
              created: DateTime.now(),
            );
          }).toList();

          final deck = FlashcardDeck(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: 'AI-generated from text',
            flashcards: flashcards,
            courseId: courseId,
            examId: examId,
            created: DateTime.now(),
          );

          _decks.add(deck);
          await _saveDecks();

          AppLogger.info('Generated ${flashcards.length} flashcards');
          return deck;
        }
      } catch (e) {
        AppLogger.warning('Could not parse AI flashcards: $e');
      }

      // Fallback: create basic flashcard deck
      return _createFallbackDeck(title, courseId, examId);
    } catch (e, stackTrace) {
      AppLogger.error('Error generating flashcards from text', e, stackTrace);
      rethrow;
    }
  }

  /// Generate flashcards from a list of topics/keywords
  Future<FlashcardDeck> generateFromTopics({
    required List<String> topics,
    required String title,
    String? courseId,
    String? examId,
  }) async {
    try {
      AppLogger.info('Generating flashcards from topics: $title');

      final prompt = '''
Create comprehensive flashcards for these topics:

${topics.map((t) => '- $t').join('\n')}

Requirements:
- Return ONLY a JSON array of flashcards
- Create 2-3 flashcards per topic
- Each flashcard should have: "question" (string), "answer" (string), "hint" (optional string), "topic" (string)
- Cover key concepts, definitions, examples, and applications
- Use varied question formats (what, why, how, when, etc.)
- Answers should be detailed enough to learn from

Example format:
[
  {
    "question": "What is mitosis?",
    "answer": "Cell division that produces two identical daughter cells",
    "hint": "Think about how cells reproduce",
    "topic": "Cell Division"
  }
]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          final flashcards = data.map((item) {
            return Flashcard(
              id: DateTime.now().millisecondsSinceEpoch.toString() + data.indexOf(item).toString(),
              question: item['question'] as String,
              answer: item['answer'] as String,
              hint: item['hint'] as String?,
              tags: [item['topic'] as String],
              type: FlashcardType.basic,
              created: DateTime.now(),
            );
          }).toList();

          final deck = FlashcardDeck(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: 'AI-generated from topics: ${topics.join(", ")}',
            flashcards: flashcards,
            courseId: courseId,
            examId: examId,
            created: DateTime.now(),
          );

          _decks.add(deck);
          await _saveDecks();

          AppLogger.info('Generated ${flashcards.length} flashcards from ${topics.length} topics');
          return deck;
        }
      } catch (e) {
        AppLogger.warning('Could not parse AI flashcards: $e');
      }

      return _createFallbackDeck(title, courseId, examId);
    } catch (e, stackTrace) {
      AppLogger.error('Error generating flashcards from topics', e, stackTrace);
      rethrow;
    }
  }

  /// Create a manual flashcard deck
  Future<FlashcardDeck> createDeck({
    required String title,
    String? description,
    String? courseId,
    String? examId,
    List<Flashcard>? flashcards,
  }) async {
    try {
      final deck = FlashcardDeck(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        flashcards: flashcards ?? [],
        courseId: courseId,
        examId: examId,
        created: DateTime.now(),
      );

      _decks.add(deck);
      await _saveDecks();

      AppLogger.info('Created flashcard deck: $title');
      return deck;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating deck', e, stackTrace);
      rethrow;
    }
  }

  /// Add flashcard to deck
  Future<void> addFlashcardToDeck(String deckId, Flashcard flashcard) async {
    try {
      final deckIndex = _decks.indexWhere((d) => d.id == deckId);
      if (deckIndex != -1) {
        final deck = _decks[deckIndex];
        final updatedFlashcards = List<Flashcard>.from(deck.flashcards)..add(flashcard);

        _decks[deckIndex] = FlashcardDeck(
          id: deck.id,
          title: deck.title,
          description: deck.description,
          flashcards: updatedFlashcards,
          courseId: deck.courseId,
          examId: deck.examId,
          created: deck.created,
          lastStudied: deck.lastStudied,
        );

        await _saveDecks();
        AppLogger.info('Added flashcard to deck: $deckId');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error adding flashcard to deck', e, stackTrace);
    }
  }

  /// Update flashcard
  Future<void> updateFlashcard(String deckId, Flashcard flashcard) async {
    try {
      final deckIndex = _decks.indexWhere((d) => d.id == deckId);
      if (deckIndex != -1) {
        final deck = _decks[deckIndex];
        final flashcards = List<Flashcard>.from(deck.flashcards);
        final cardIndex = flashcards.indexWhere((c) => c.id == flashcard.id);

        if (cardIndex != -1) {
          flashcards[cardIndex] = flashcard;

          _decks[deckIndex] = FlashcardDeck(
            id: deck.id,
            title: deck.title,
            description: deck.description,
            flashcards: flashcards,
            courseId: deck.courseId,
            examId: deck.examId,
            created: deck.created,
            lastStudied: deck.lastStudied,
          );

          await _saveDecks();
          AppLogger.info('Updated flashcard: ${flashcard.id}');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating flashcard', e, stackTrace);
    }
  }

  /// Delete flashcard from deck
  Future<void> deleteFlashcard(String deckId, String flashcardId) async {
    try {
      final deckIndex = _decks.indexWhere((d) => d.id == deckId);
      if (deckIndex != -1) {
        final deck = _decks[deckIndex];
        final updatedFlashcards = deck.flashcards.where((c) => c.id != flashcardId).toList();

        _decks[deckIndex] = FlashcardDeck(
          id: deck.id,
          title: deck.title,
          description: deck.description,
          flashcards: updatedFlashcards,
          courseId: deck.courseId,
          examId: deck.examId,
          created: deck.created,
          lastStudied: deck.lastStudied,
        );

        await _saveDecks();
        AppLogger.info('Deleted flashcard: $flashcardId');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting flashcard', e, stackTrace);
    }
  }

  /// Delete deck
  Future<bool> deleteDeck(String deckId) async {
    try {
      final removedCount = _decks.removeWhere((d) => d.id == deckId);
      if (removedCount > 0) {
        // Also delete related reviews
        _reviews.removeWhere((r) => r.deckId == deckId);

        await _saveDecks();
        await _saveReviews();

        AppLogger.info('Deleted deck: $deckId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting deck', e, stackTrace);
      return false;
    }
  }

  /// Record a flashcard review (for spaced repetition)
  Future<void> recordReview({
    required String deckId,
    required String flashcardId,
    required ReviewQuality quality,
  }) async {
    try {
      final review = FlashcardReview(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deckId: deckId,
        flashcardId: flashcardId,
        quality: quality,
        reviewedAt: DateTime.now(),
      );

      _reviews.add(review);
      await _saveReviews();

      // Update deck last studied time
      final deckIndex = _decks.indexWhere((d) => d.id == deckId);
      if (deckIndex != -1) {
        final deck = _decks[deckIndex];
        _decks[deckIndex] = FlashcardDeck(
          id: deck.id,
          title: deck.title,
          description: deck.description,
          flashcards: deck.flashcards,
          courseId: deck.courseId,
          examId: deck.examId,
          created: deck.created,
          lastStudied: DateTime.now(),
        );
        await _saveDecks();
      }

      AppLogger.debug('Recorded review for flashcard: $flashcardId');
    } catch (e, stackTrace) {
      AppLogger.error('Error recording review', e, stackTrace);
    }
  }

  /// Get cards due for review using spaced repetition algorithm
  List<Flashcard> getCardsForReview(String deckId) {
    try {
      final deck = getDeck(deckId);
      if (deck == null) return [];

      final now = DateTime.now();
      final dueCards = <Flashcard>[];

      for (final card in deck.flashcards) {
        final cardReviews = _reviews
            .where((r) => r.deckId == deckId && r.flashcardId == card.id)
            .toList()
          ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));

        if (cardReviews.isEmpty) {
          // Never reviewed - show immediately
          dueCards.add(card);
        } else {
          // Calculate next review date using SM-2 algorithm (simplified)
          final lastReview = cardReviews.first;
          final daysSinceReview = now.difference(lastReview.reviewedAt).inDays;

          // Calculate interval based on review quality
          int interval = _calculateInterval(cardReviews);

          if (daysSinceReview >= interval) {
            dueCards.add(card);
          }
        }
      }

      return dueCards;
    } catch (e) {
      AppLogger.warning('Error getting cards for review', e);
      return [];
    }
  }

  /// Calculate review interval using simplified SM-2 algorithm
  int _calculateInterval(List<FlashcardReview> reviews) {
    if (reviews.isEmpty) return 1;

    // Start with 1 day
    int interval = 1;
    int consecutiveGood = 0;

    for (final review in reviews.reversed) {
      switch (review.quality) {
        case ReviewQuality.again:
          // Reset to 1 day
          interval = 1;
          consecutiveGood = 0;
          break;
        case ReviewQuality.hard:
          // Increase slightly
          interval = (interval * 1.2).round();
          consecutiveGood = 0;
          break;
        case ReviewQuality.good:
          // Standard increase
          consecutiveGood++;
          if (consecutiveGood == 1) {
            interval = 1;
          } else if (consecutiveGood == 2) {
            interval = 6;
          } else {
            interval = (interval * 2.5).round();
          }
          break;
        case ReviewQuality.easy:
          // Larger increase
          consecutiveGood++;
          if (consecutiveGood == 1) {
            interval = 4;
          } else {
            interval = (interval * 3).round();
          }
          break;
      }
    }

    return interval.clamp(1, 365); // Max 1 year
  }

  /// Get deck by ID
  FlashcardDeck? getDeck(String deckId) {
    try {
      return _decks.firstWhere((d) => d.id == deckId);
    } catch (e) {
      return null;
    }
  }

  /// Get all decks
  List<FlashcardDeck> get allDecks => List.unmodifiable(_decks);

  /// Get decks for course
  List<FlashcardDeck> getDecksForCourse(String courseId) =>
      _decks.where((d) => d.courseId == courseId).toList();

  /// Get decks for exam
  List<FlashcardDeck> getDecksForExam(String examId) =>
      _decks.where((d) => d.examId == examId).toList();

  /// Get study statistics for a deck
  DeckStatistics getDeckStatistics(String deckId) {
    final deck = getDeck(deckId);
    if (deck == null) {
      return DeckStatistics(
        deckId: deckId,
        totalCards: 0,
        cardsReviewed: 0,
        cardsDue: 0,
        masteryRate: 0.0,
      );
    }

    final deckReviews = _reviews.where((r) => r.deckId == deckId).toList();
    final uniqueCardsReviewed = deckReviews.map((r) => r.flashcardId).toSet().length;
    final cardsDue = getCardsForReview(deckId).length;

    // Calculate mastery rate (cards reviewed well / total cards)
    final wellReviewed = deck.flashcards.where((card) {
      final cardReviews = deckReviews
          .where((r) => r.flashcardId == card.id)
          .toList()
        ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));

      if (cardReviews.isEmpty) return false;

      // Count as mastered if last 3 reviews were good or easy
      final recentReviews = cardReviews.take(3);
      return recentReviews.every((r) =>
        r.quality == ReviewQuality.good || r.quality == ReviewQuality.easy
      );
    }).length;

    final masteryRate = deck.flashcards.isEmpty ? 0.0 :
      (wellReviewed / deck.flashcards.length) * 100;

    return DeckStatistics(
      deckId: deckId,
      totalCards: deck.flashcards.length,
      cardsReviewed: uniqueCardsReviewed,
      cardsDue: cardsDue,
      masteryRate: masteryRate,
      totalReviews: deckReviews.length,
      lastStudied: deck.lastStudied,
    );
  }

  /// Get overall statistics
  FlashcardOverallStatistics getOverallStatistics() {
    final totalDecks = _decks.length;
    final totalCards = _decks.fold<int>(0, (sum, d) => sum + d.flashcards.length);
    final totalReviews = _reviews.length;

    final allStats = _decks.map((d) => getDeckStatistics(d.id)).toList();
    final avgMastery = allStats.isEmpty ? 0.0 :
      allStats.fold<double>(0.0, (sum, s) => sum + s.masteryRate) / allStats.length;

    final totalDue = allStats.fold<int>(0, (sum, s) => sum + s.cardsDue);

    return FlashcardOverallStatistics(
      totalDecks: totalDecks,
      totalCards: totalCards,
      totalReviews: totalReviews,
      averageMastery: avgMastery,
      cardsDueToday: totalDue,
    );
  }

  /// Create fallback deck when AI fails
  FlashcardDeck _createFallbackDeck(String title, String? courseId, String? examId) {
    final deck = FlashcardDeck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: 'Deck created',
      flashcards: [],
      courseId: courseId,
      examId: examId,
      created: DateTime.now(),
    );

    _decks.add(deck);
    return deck;
  }

  /// Save decks
  Future<void> _saveDecks() async {
    try {
      final json = jsonEncode(_decks.map((d) => {
        'id': d.id,
        'title': d.title,
        'description': d.description,
        'flashcards': d.flashcards.map((c) => {
          'id': c.id,
          'question': c.question,
          'answer': c.answer,
          'hint': c.hint,
          'type': c.type.toString(),
          'tags': c.tags,
          'imageUrl': c.imageUrl,
          'created': c.created.toIso8601String(),
        }).toList(),
        'courseId': d.courseId,
        'examId': d.examId,
        'created': d.created.toIso8601String(),
        'lastStudied': d.lastStudied?.toIso8601String(),
      }).toList());

      await LocalStorageService.instance.setString('flashcard_decks', json);
      AppLogger.debug('Saved ${_decks.length} flashcard decks');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving decks', e, stackTrace);
    }
  }

  /// Load decks
  Future<void> _loadDecks() async {
    try {
      final json = LocalStorageService.instance.getString('flashcard_decks');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _decks = data.map((item) {
          final flashcards = (item['flashcards'] as List<dynamic>).map((c) {
            return Flashcard(
              id: c['id'] as String,
              question: c['question'] as String,
              answer: c['answer'] as String,
              hint: c['hint'] as String?,
              type: FlashcardType.values.firstWhere(
                (t) => t.toString() == c['type'],
                orElse: () => FlashcardType.basic,
              ),
              tags: (c['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ?? [],
              imageUrl: c['imageUrl'] as String?,
              created: DateTime.parse(c['created'] as String),
            );
          }).toList();

          return FlashcardDeck(
            id: item['id'] as String,
            title: item['title'] as String,
            description: item['description'] as String?,
            flashcards: flashcards,
            courseId: item['courseId'] as String?,
            examId: item['examId'] as String?,
            created: DateTime.parse(item['created'] as String),
            lastStudied: item['lastStudied'] != null
              ? DateTime.parse(item['lastStudied'] as String)
              : null,
          );
        }).toList();

        AppLogger.info('Loaded ${_decks.length} flashcard decks');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading decks', e, stackTrace);
    }
  }

  /// Save reviews
  Future<void> _saveReviews() async {
    try {
      final json = jsonEncode(_reviews.map((r) => {
        'id': r.id,
        'deckId': r.deckId,
        'flashcardId': r.flashcardId,
        'quality': r.quality.toString(),
        'reviewedAt': r.reviewedAt.toIso8601String(),
      }).toList());

      await LocalStorageService.instance.setString('flashcard_reviews', json);
      AppLogger.debug('Saved ${_reviews.length} flashcard reviews');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving reviews', e, stackTrace);
    }
  }

  /// Load reviews
  Future<void> _loadReviews() async {
    try {
      final json = LocalStorageService.instance.getString('flashcard_reviews');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _reviews = data.map((item) {
          return FlashcardReview(
            id: item['id'] as String,
            deckId: item['deckId'] as String,
            flashcardId: item['flashcardId'] as String,
            quality: ReviewQuality.values.firstWhere(
              (q) => q.toString() == item['quality'],
              orElse: () => ReviewQuality.good,
            ),
            reviewedAt: DateTime.parse(item['reviewedAt'] as String),
          );
        }).toList();

        AppLogger.info('Loaded ${_reviews.length} flashcard reviews');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading reviews', e, stackTrace);
    }
  }
}

