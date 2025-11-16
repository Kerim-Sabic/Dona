import 'dart:convert';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../ai/ai_service.dart';

/// Document Summarizer Service
/// AI-powered document summarization for research papers, textbooks, articles
class DocumentSummarizerService {
  static final DocumentSummarizerService _instance = DocumentSummarizerService._internal();
  static DocumentSummarizerService get instance => _instance;

  DocumentSummarizerService._internal();

  List<DocumentSummary> _summaries = [];

  /// Initialize summarizer service
  Future<void> init() async {
    try {
      await _loadSummaries();
      AppLogger.info('DocumentSummarizerService initialized with ${_summaries.length} summaries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize DocumentSummarizerService', e, stackTrace);
    }
  }

  /// Summarize document using AI
  Future<DocumentSummary> summarizeDocument({
    required String content,
    required String title,
    String? sourceUrl,
    String? courseId,
    String? examId,
    SummaryMode mode = SummaryMode.balanced,
    SummaryLength length = SummaryLength.medium,
  }) async {
    try {
      AppLogger.info('Summarizing document: $title');

      // Generate main summary
      final mainSummary = await _generateMainSummary(content, mode, length);

      // Extract key points
      final keyPoints = await _extractKeyPoints(content);

      // Extract vocabulary
      final vocabulary = await _extractVocabulary(content);

      // Identify main ideas
      final mainIdeas = await _extractMainIdeas(content);

      final summary = DocumentSummary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        originalContent: content,
        summary: mainSummary,
        keyPoints: keyPoints,
        mainIdeas: mainIdeas,
        vocabulary: vocabulary,
        sourceUrl: sourceUrl,
        courseId: courseId,
        examId: examId,
        mode: mode,
        length: length,
        wordCount: content.split(RegExp(r'\s+')).length,
        created: DateTime.now(),
      );

      _summaries.add(summary);
      await _saveSummaries();

      AppLogger.info('Created summary for: $title');
      return summary;
    } catch (e, stackTrace) {
      AppLogger.error('Error summarizing document', e, stackTrace);
      rethrow;
    }
  }

  /// Generate main summary based on mode and length
  Future<String> _generateMainSummary(String content, SummaryMode mode, SummaryLength length) async {
    try {
      // Calculate target length
      int targetSentences;
      switch (length) {
        case SummaryLength.brief:
          targetSentences = 3;
          break;
        case SummaryLength.medium:
          targetSentences = 7;
          break;
        case SummaryLength.detailed:
          targetSentences = 15;
          break;
      }

      String modeInstructions;
      switch (mode) {
        case SummaryMode.brief:
          modeInstructions = 'Provide only the most essential information in the simplest terms possible.';
          break;
        case SummaryMode.balanced:
          modeInstructions = 'Balance between brevity and detail. Include main points and key supporting facts.';
          break;
        case SummaryMode.detailed:
          modeInstructions = 'Provide comprehensive coverage with important details, examples, and context.';
          break;
        case SummaryMode.bulletPoints:
          modeInstructions = 'Create a bullet-point list of main ideas.';
          break;
        case SummaryMode.keyConcepts:
          modeInstructions = 'Focus on identifying and explaining key concepts and terminology.';
          break;
      }

      final prompt = '''
Summarize this document in approximately $targetSentences sentences:

$content

Instructions:
- $modeInstructions
- ${mode == SummaryMode.bulletPoints ? 'Use bullet points (-)' : 'Write in paragraph form'}
- Focus on main ideas and important facts
- Be clear and concise
- Maintain academic accuracy
- Return ONLY the summary text, no additional commentary
''';

      final response = await AIService.instance.chat(prompt);
      return response.trim();
    } catch (e) {
      AppLogger.warning('Error generating main summary: $e');
      return 'Summary could not be generated.';
    }
  }

  /// Extract key points from document
  Future<List<String>> _extractKeyPoints(String content) async {
    try {
      final prompt = '''
Extract 5-10 key points from this document:

$content

Requirements:
- Return ONLY a JSON array of strings
- Each point should be concise (1-2 sentences)
- Focus on main takeaways and important facts
- Order by importance

Example format:
["Point 1", "Point 2", "Point 3"]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        final jsonMatch = RegExp(r'\[[^\]]*\]', multiLine: true, dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          return data.map((item) => item as String).toList();
        }
      } catch (e) {
        AppLogger.warning('Could not parse key points: $e');
      }

      // Fallback
      return ['Key points could not be extracted.'];
    } catch (e) {
      AppLogger.warning('Error extracting key points: $e');
      return [];
    }
  }

  /// Extract main ideas
  Future<List<String>> _extractMainIdeas(String content) async {
    try {
      final prompt = '''
Identify 3-5 main ideas/themes from this document:

$content

Requirements:
- Return ONLY a JSON array of strings
- Each idea should be a complete sentence
- Focus on central themes and arguments
- Order by prominence in the text

Example format:
["Main idea 1", "Main idea 2", "Main idea 3"]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        final jsonMatch = RegExp(r'\[[^\]]*\]', multiLine: true, dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          return data.map((item) => item as String).toList();
        }
      } catch (e) {
        AppLogger.warning('Could not parse main ideas: $e');
      }

      return ['Main ideas could not be extracted.'];
    } catch (e) {
      AppLogger.warning('Error extracting main ideas: $e');
      return [];
    }
  }

  /// Extract important vocabulary
  Future<List<VocabularyTerm>> _extractVocabulary(String content) async {
    try {
      final prompt = '''
Extract 5-10 important vocabulary terms from this document:

$content

Requirements:
- Return ONLY a JSON array of vocabulary terms
- Each term should have: "term" (string), "definition" (string)
- Focus on academic/technical terms
- Include terms essential for understanding the document

Example format:
[
  {"term": "Photosynthesis", "definition": "The process by which plants convert light energy into chemical energy"},
  {"term": "Chloroplast", "definition": "The organelle where photosynthesis occurs"}
]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        final jsonMatch = RegExp(r'\[[^\]]*\]', multiLine: true, dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          return data.map((item) {
            return VocabularyTerm(
              term: item['term'] as String,
              definition: item['definition'] as String,
            );
          }).toList();
        }
      } catch (e) {
        AppLogger.warning('Could not parse vocabulary: $e');
      }

      return [];
    } catch (e) {
      AppLogger.warning('Error extracting vocabulary: $e');
      return [];
    }
  }

  /// Generate questions from summary
  Future<List<String>> generateQuestionsFromSummary(String summaryId) async {
    try {
      final summary = getSummary(summaryId);
      if (summary == null) {
        throw Exception('Summary not found: $summaryId');
      }

      final prompt = '''
Generate 5-8 study questions based on this summary:

${summary.summary}

Key Points:
${summary.keyPoints.map((p) => '- $p').join('\n')}

Requirements:
- Return ONLY a JSON array of question strings
- Mix of question types (what, why, how, explain, compare)
- Questions should test understanding, not just memorization
- Clear and specific

Example format:
["What is photosynthesis?", "Why do plants need chlorophyll?", "How does light intensity affect photosynthesis?"]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        final jsonMatch = RegExp(r'\[[^\]]*\]', multiLine: true, dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          return data.map((item) => item as String).toList();
        }
      } catch (e) {
        AppLogger.warning('Could not parse questions: $e');
      }

      return ['Questions could not be generated.'];
    } catch (e, stackTrace) {
      AppLogger.error('Error generating questions from summary', e, stackTrace);
      return [];
    }
  }

  /// Create comparison summary of multiple documents
  Future<String> compareDocuments({
    required List<String> summaryIds,
    String? focusQuestion,
  }) async {
    try {
      if (summaryIds.length < 2) {
        throw Exception('Need at least 2 summaries to compare');
      }

      final summaries = summaryIds
          .map((id) => getSummary(id))
          .where((s) => s != null)
          .toList();

      if (summaries.length < 2) {
        throw Exception('Could not find all summaries');
      }

      final summariesText = summaries.map((s) {
        return '''
Document: ${s!.title}
Summary: ${s.summary}
Key Points:
${s.keyPoints.map((p) => '- $p').join('\n')}
''';
      }).join('\n\n---\n\n');

      final prompt = '''
Compare and contrast these documents:

$summariesText

${focusQuestion != null ? '\nFocus on: $focusQuestion\n' : ''}

Requirements:
- Identify similarities and differences
- Highlight unique contributions of each document
- Note any contradictions or agreements
- Organize comparison clearly
- Provide a synthesis of the main themes

Return a clear, well-structured comparison.
''';

      final response = await AIService.instance.chat(prompt);
      return response.trim();
    } catch (e, stackTrace) {
      AppLogger.error('Error comparing documents', e, stackTrace);
      rethrow;
    }
  }

  /// Update summary
  Future<void> updateSummary(DocumentSummary summary) async {
    try {
      final index = _summaries.indexWhere((s) => s.id == summary.id);
      if (index != -1) {
        _summaries[index] = summary;
        await _saveSummaries();
        AppLogger.info('Updated summary: ${summary.title}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating summary', e, stackTrace);
    }
  }

  /// Delete summary
  Future<bool> deleteSummary(String summaryId) async {
    try {
      final removedCount = _summaries.removeWhere((s) => s.id == summaryId);
      if (removedCount > 0) {
        await _saveSummaries();
        AppLogger.info('Deleted summary: $summaryId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting summary', e, stackTrace);
      return false;
    }
  }

  /// Get summary by ID
  DocumentSummary? getSummary(String summaryId) {
    try {
      return _summaries.firstWhere((s) => s.id == summaryId);
    } catch (e) {
      return null;
    }
  }

  /// Get all summaries
  List<DocumentSummary> get allSummaries => List.unmodifiable(_summaries);

  /// Get summaries for course
  List<DocumentSummary> getSummariesForCourse(String courseId) =>
      _summaries.where((s) => s.courseId == courseId).toList();

  /// Get summaries for exam
  List<DocumentSummary> getSummariesForExam(String examId) =>
      _summaries.where((s) => s.examId == examId).toList();

  /// Get statistics
  SummarizerStatistics getStatistics() {
    final totalWords = _summaries.fold<int>(0, (sum, s) => sum + s.wordCount);
    final avgWordCount = _summaries.isEmpty ? 0 : totalWords ~/ _summaries.length;

    // Calculate compression ratio
    final totalOriginalWords = totalWords;
    final totalSummaryWords = _summaries.fold<int>(
      0,
      (sum, s) => sum + s.summary.split(RegExp(r'\s+')).length,
    );
    final compressionRatio = totalOriginalWords > 0
      ? (totalSummaryWords / totalOriginalWords) * 100
      : 0.0;

    return SummarizerStatistics(
      totalSummaries: _summaries.length,
      totalWordsProcessed: totalWords,
      averageDocumentLength: avgWordCount,
      averageCompressionRatio: compressionRatio,
    );
  }

  /// Save summaries
  Future<void> _saveSummaries() async {
    try {
      final json = jsonEncode(_summaries.map((s) => {
        'id': s.id,
        'title': s.title,
        'originalContent': s.originalContent,
        'summary': s.summary,
        'keyPoints': s.keyPoints,
        'mainIdeas': s.mainIdeas,
        'vocabulary': s.vocabulary.map((v) => {
          'term': v.term,
          'definition': v.definition,
        }).toList(),
        'sourceUrl': s.sourceUrl,
        'courseId': s.courseId,
        'examId': s.examId,
        'mode': s.mode.toString(),
        'length': s.length.toString(),
        'wordCount': s.wordCount,
        'created': s.created.toIso8601String(),
      }).toList());

      await LocalStorageService.instance.setString('document_summaries', json);
      AppLogger.debug('Saved ${_summaries.length} summaries');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving summaries', e, stackTrace);
    }
  }

  /// Load summaries
  Future<void> _loadSummaries() async {
    try {
      final json = LocalStorageService.instance.getString('document_summaries');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _summaries = data.map((item) {
          final vocabulary = (item['vocabulary'] as List<dynamic>).map((v) {
            return VocabularyTerm(
              term: v['term'] as String,
              definition: v['definition'] as String,
            );
          }).toList();

          return DocumentSummary(
            id: item['id'] as String,
            title: item['title'] as String,
            originalContent: item['originalContent'] as String,
            summary: item['summary'] as String,
            keyPoints: (item['keyPoints'] as List<dynamic>).map((p) => p as String).toList(),
            mainIdeas: (item['mainIdeas'] as List<dynamic>).map((m) => m as String).toList(),
            vocabulary: vocabulary,
            sourceUrl: item['sourceUrl'] as String?,
            courseId: item['courseId'] as String?,
            examId: item['examId'] as String?,
            mode: SummaryMode.values.firstWhere(
              (m) => m.toString() == item['mode'],
              orElse: () => SummaryMode.balanced,
            ),
            length: SummaryLength.values.firstWhere(
              (l) => l.toString() == item['length'],
              orElse: () => SummaryLength.medium,
            ),
            wordCount: item['wordCount'] as int,
            created: DateTime.parse(item['created'] as String),
          );
        }).toList();

        AppLogger.info('Loaded ${_summaries.length} summaries');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading summaries', e, stackTrace);
    }
  }
}

/// Document summary model
class DocumentSummary {
  final String id;
  final String title;
  final String originalContent;
  final String summary;
  final List<String> keyPoints;
  final List<String> mainIdeas;
  final List<VocabularyTerm> vocabulary;
  final String? sourceUrl;
  final String? courseId;
  final String? examId;
  final SummaryMode mode;
  final SummaryLength length;
  final int wordCount;
  final DateTime created;

  DocumentSummary({
    required this.id,
    required this.title,
    required this.originalContent,
    required this.summary,
    required this.keyPoints,
    required this.mainIdeas,
    required this.vocabulary,
    this.sourceUrl,
    this.courseId,
    this.examId,
    required this.mode,
    required this.length,
    required this.wordCount,
    required this.created,
  });

  /// Get compression ratio
  double get compressionRatio {
    final summaryWords = summary.split(RegExp(r'\s+')).length;
    return wordCount > 0 ? (summaryWords / wordCount) * 100 : 0.0;
  }
}

/// Vocabulary term
class VocabularyTerm {
  final String term;
  final String definition;

  VocabularyTerm({
    required this.term,
    required this.definition,
  });
}

/// Summary modes
enum SummaryMode {
  brief,        // Shortest, only essentials
  balanced,     // Balance between brevity and detail
  detailed,     // Comprehensive with examples
  bulletPoints, // Bullet-point format
  keyConcepts,  // Focus on key concepts
}

/// Summary length
enum SummaryLength {
  brief,    // ~3 sentences
  medium,   // ~7 sentences
  detailed, // ~15 sentences
}

/// Summarizer statistics
class SummarizerStatistics {
  final int totalSummaries;
  final int totalWordsProcessed;
  final int averageDocumentLength;
  final double averageCompressionRatio;

  SummarizerStatistics({
    required this.totalSummaries,
    required this.totalWordsProcessed,
    required this.averageDocumentLength,
    required this.averageCompressionRatio,
  });

  @override
  String toString() {
    return '''
Summarizer Statistics:
  Total Summaries: $totalSummaries
  Total Words Processed: $totalWordsProcessed
  Average Document Length: $averageDocumentLength words
  Average Compression: ${averageCompressionRatio.toStringAsFixed(1)}%
''';
  }
}
