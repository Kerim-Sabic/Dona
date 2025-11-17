import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Word definition model
class WordDefinition {
  final String word;
  final String phonetic;
  final List<String> phonetics;
  final List<Meaning> meanings;
  final String? origin;

  WordDefinition({
    required this.word,
    required this.phonetic,
    required this.phonetics,
    required this.meanings,
    this.origin,
  });

  factory WordDefinition.fromJson(Map<String, dynamic> json) {
    final phoneticsList = <String>[];
    if (json['phonetics'] is List) {
      for (var p in json['phonetics']) {
        if (p['text'] != null) {
          phoneticsList.add(p['text']);
        }
      }
    }

    final meaningsList = <Meaning>[];
    if (json['meanings'] is List) {
      for (var m in json['meanings']) {
        meaningsList.add(Meaning.fromJson(m));
      }
    }

    return WordDefinition(
      word: json['word'] ?? '',
      phonetic: json['phonetic'] ?? '',
      phonetics: phoneticsList,
      meanings: meaningsList,
      origin: json['origin'],
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
    required this.synonyms,
    required this.antonyms,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    final defs = <Definition>[];
    if (json['definitions'] is List) {
      for (var d in json['definitions']) {
        defs.add(Definition.fromJson(d));
      }
    }

    return Meaning(
      partOfSpeech: json['partOfSpeech'] ?? '',
      definitions: defs,
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }
}

class Definition {
  final String definition;
  final String? example;
  final List<String> synonyms;
  final List<String> antonyms;

  Definition({
    required this.definition,
    this.example,
    required this.synonyms,
    required this.antonyms,
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] ?? '',
      example: json['example'],
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }
}

/// Free Dictionary API Service
/// https://dictionaryapi.dev/ - Completely FREE, No API Key Required!
class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  static DictionaryService get instance => _instance;

  DictionaryService._internal();

  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries';
  static const Duration _timeout = Duration(seconds: 10);

  Future<void> init() async {
    AppLogger.info('DictionaryService initialized with Free Dictionary API');
  }

  /// Get word definition
  Future<List<WordDefinition>> getDefinition(String word, {String lang = 'en'}) async {
    try {
      AppLogger.debug('Looking up word: $word');

      final cleanWord = word.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '');
      final url = Uri.parse('$_baseUrl/$lang/$cleanWord');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => WordDefinition.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        AppLogger.warning('Word not found: $word');
        return [];
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get definition for $word', e, stackTrace);
      return [];
    }
  }

  /// Get word with examples and usage
  Future<String> getWordSummary(String word) async {
    try {
      final definitions = await getDefinition(word);

      if (definitions.isEmpty) {
        return 'No definition found for "$word"';
      }

      final def = definitions.first;
      final buffer = StringBuffer();

      buffer.writeln('📖 Word: ${def.word}');
      if (def.phonetic.isNotEmpty) {
        buffer.writeln('🔊 Pronunciation: ${def.phonetic}');
      }

      for (var meaning in def.meanings.take(3)) {
        buffer.writeln('\n📝 ${meaning.partOfSpeech.toUpperCase()}');
        for (var definition in meaning.definitions.take(2)) {
          buffer.writeln('  • ${definition.definition}');
          if (definition.example != null) {
            buffer.writeln('    Example: "${definition.example}"');
          }
        }

        if (meaning.synonyms.isNotEmpty) {
          buffer.writeln('  Synonyms: ${meaning.synonyms.take(5).join(', ')}');
        }
      }

      if (def.origin != null && def.origin!.isNotEmpty) {
        buffer.writeln('\n📚 Origin: ${def.origin}');
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get word summary', e, stackTrace);
      return 'Unable to fetch definition for "$word"';
    }
  }
}
