import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Translation result model
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final String? detectedLanguage;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.detectedLanguage,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('🌐 Translation:');
    if (detectedLanguage != null) {
      buffer.writeln('Detected: $detectedLanguage');
    }
    buffer.writeln('From: $sourceLanguage → To: $targetLanguage');
    buffer.writeln();
    buffer.writeln('Original: $originalText');
    buffer.writeln('Translation: $translatedText');
    return buffer.toString();
  }
}

/// Language model
class Language {
  final String code;
  final String name;
  final String nativeName;

  Language({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

/// Translation Service
/// Uses MyMemory Translation API (FREE, NO API KEY REQUIRED!)
/// https://mymemory.translated.net/ - 100% FREE with rate limits
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  static TranslationService get instance => _instance;

  TranslationService._internal();

  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  static const Duration _timeout = Duration(seconds: 15);

  // Supported languages (top 50 most common)
  static final List<Language> supportedLanguages = [
    Language(code: 'en', name: 'English', nativeName: 'English'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
    Language(code: 'fr', name: 'French', nativeName: 'Français'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch'),
    Language(code: 'it', name: 'Italian', nativeName: 'Italiano'),
    Language(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    Language(code: 'ko', name: 'Korean', nativeName: '한국어'),
    Language(code: 'zh-CN', name: 'Chinese (Simplified)', nativeName: '简体中文'),
    Language(code: 'zh-TW', name: 'Chinese (Traditional)', nativeName: '繁體中文'),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
    Language(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    Language(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
    Language(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
    Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
    Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
    Language(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
    Language(code: 'pl', name: 'Polish', nativeName: 'Polski'),
    Language(code: 'uk', name: 'Ukrainian', nativeName: 'Українська'),
    Language(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
    Language(code: 'ro', name: 'Romanian', nativeName: 'Română'),
    Language(code: 'el', name: 'Greek', nativeName: 'Ελληνικά'),
    Language(code: 'cs', name: 'Czech', nativeName: 'Čeština'),
    Language(code: 'sv', name: 'Swedish', nativeName: 'Svenska'),
    Language(code: 'hu', name: 'Hungarian', nativeName: 'Magyar'),
    Language(code: 'fi', name: 'Finnish', nativeName: 'Suomi'),
    Language(code: 'no', name: 'Norwegian', nativeName: 'Norsk'),
    Language(code: 'da', name: 'Danish', nativeName: 'Dansk'),
    Language(code: 'th', name: 'Thai', nativeName: 'ไทย'),
    Language(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
    Language(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
    Language(code: 'fa', name: 'Persian', nativeName: 'فارسی'),
    Language(code: 'he', name: 'Hebrew', nativeName: 'עברית'),
    Language(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili'),
    Language(code: 'af', name: 'Afrikaans', nativeName: 'Afrikaans'),
    Language(code: 'sq', name: 'Albanian', nativeName: 'Shqip'),
    Language(code: 'hr', name: 'Croatian', nativeName: 'Hrvatski'),
    Language(code: 'sr', name: 'Serbian', nativeName: 'Српски'),
    Language(code: 'sk', name: 'Slovak', nativeName: 'Slovenčina'),
    Language(code: 'sl', name: 'Slovenian', nativeName: 'Slovenščina'),
    Language(code: 'bg', name: 'Bulgarian', nativeName: 'Български'),
    Language(code: 'lt', name: 'Lithuanian', nativeName: 'Lietuvių'),
    Language(code: 'lv', name: 'Latvian', nativeName: 'Latviešu'),
    Language(code: 'et', name: 'Estonian', nativeName: 'Eesti'),
    Language(code: 'bs', name: 'Bosnian', nativeName: 'Bosanski'),
    Language(code: 'ca', name: 'Catalan', nativeName: 'Català'),
  ];

  Future<void> init() async {
    AppLogger.info('TranslationService initialized with MyMemory API');
  }

  /// Translate text between languages
  Future<TranslationResult?> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    try {
      if (text.isEmpty) {
        AppLogger.warning('Empty text provided for translation');
        return null;
      }

      AppLogger.debug('Translating: "$text" from $sourceLanguage to $targetLanguage');

      // Build language pair
      final langPair = sourceLanguage == 'auto'
          ? '${_detectLanguageCode(text)}|$targetLanguage'
          : '$sourceLanguage|$targetLanguage';

      final params = {
        'q': text,
        'langpair': langPair,
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['responseStatus'] == 200 || data['responseStatus'] == '200') {
          final translatedText = data['responseData']['translatedText'] as String;
          final detectedLang = data['responseData']['match'] as double? ?? 0.0;

          return TranslationResult(
            originalText: text,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            detectedLanguage: detectedLang > 0.5 ? _getLanguageName(sourceLanguage) : null,
          );
        }
      }

      AppLogger.warning('Translation API returned non-200 status: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to translate text', e, stackTrace);
      return null;
    }
  }

  /// Detect language of text (simple heuristic-based detection)
  String _detectLanguageCode(String text) {
    // Simple heuristic: check character ranges

    // Chinese characters
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return 'zh-CN';
    }

    // Japanese characters (Hiragana/Katakana)
    if (RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text)) {
      return 'ja';
    }

    // Korean characters
    if (RegExp(r'[\uac00-\ud7af]').hasMatch(text)) {
      return 'ko';
    }

    // Arabic characters
    if (RegExp(r'[\u0600-\u06ff]').hasMatch(text)) {
      return 'ar';
    }

    // Cyrillic characters (Russian, etc.)
    if (RegExp(r'[\u0400-\u04ff]').hasMatch(text)) {
      return 'ru';
    }

    // Greek characters
    if (RegExp(r'[\u0370-\u03ff]').hasMatch(text)) {
      return 'el';
    }

    // Hebrew characters
    if (RegExp(r'[\u0590-\u05ff]').hasMatch(text)) {
      return 'he';
    }

    // Thai characters
    if (RegExp(r'[\u0e00-\u0e7f]').hasMatch(text)) {
      return 'th';
    }

    // Default to English
    return 'en';
  }

  /// Get language name from code
  String _getLanguageName(String code) {
    try {
      return supportedLanguages
          .firstWhere((lang) => lang.code == code)
          .name;
    } catch (_) {
      return code.toUpperCase();
    }
  }

  /// Get language by name or code
  Language? getLanguage(String query) {
    final lowerQuery = query.toLowerCase();

    try {
      return supportedLanguages.firstWhere(
        (lang) =>
            lang.code.toLowerCase() == lowerQuery ||
            lang.name.toLowerCase() == lowerQuery ||
            lang.nativeName.toLowerCase() == lowerQuery,
      );
    } catch (_) {
      return null;
    }
  }

  /// Translate to multiple languages
  Future<List<TranslationResult>> translateToMultiple({
    required String text,
    required List<String> targetLanguages,
    String sourceLanguage = 'auto',
  }) async {
    final results = <TranslationResult>[];

    for (final targetLang in targetLanguages) {
      final result = await translate(
        text: text,
        targetLanguage: targetLang,
        sourceLanguage: sourceLanguage,
      );

      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  /// Get supported languages list
  String getSupportedLanguages() {
    final buffer = StringBuffer('🌐 Supported Languages:\n\n');

    // Group by region/script
    final european = supportedLanguages.where((l) =>
        ['en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'pl', 'ro', 'el', 'cs', 'sv', 'hu', 'fi', 'no', 'da'].contains(l.code));
    final asian = supportedLanguages.where((l) =>
        ['ja', 'ko', 'zh-CN', 'zh-TW', 'th', 'vi', 'id', 'ms', 'hi', 'bn', 'pa', 'te', 'mr', 'ta'].contains(l.code));
    final middleEastern = supportedLanguages.where((l) =>
        ['ar', 'fa', 'he', 'tr', 'ur'].contains(l.code));
    final slavic = supportedLanguages.where((l) =>
        ['ru', 'uk', 'pl', 'cs', 'sr', 'hr', 'sk', 'sl', 'bg', 'bs'].contains(l.code));

    buffer.writeln('🇪🇺 European:');
    for (var lang in european) {
      buffer.writeln('   ${lang.code}: ${lang.name} (${lang.nativeName})');
    }

    buffer.writeln('\n🌏 Asian:');
    for (var lang in asian) {
      buffer.writeln('   ${lang.code}: ${lang.name} (${lang.nativeName})');
    }

    buffer.writeln('\n🌍 Middle Eastern:');
    for (var lang in middleEastern) {
      buffer.writeln('   ${lang.code}: ${lang.name} (${lang.nativeName})');
    }

    buffer.writeln('\n🇷🇺 Slavic:');
    for (var lang in slavic) {
      buffer.writeln('   ${lang.code}: ${lang.name} (${lang.nativeName})');
    }

    buffer.writeln('\nTotal: ${supportedLanguages.length} languages supported!');
    buffer.writeln('\n💡 Usage: "Translate hello to Spanish" or "Translate bonjour to English"');

    return buffer.toString();
  }

  /// Get translation help
  String getTranslationHelp() {
    return '''
🌐 Translation Help:

Usage Examples:
• "Translate hello to Spanish"
• "Translate bonjour to English"
• "What is hello in Japanese"
• "Translate I love you to French"

Supported Languages:
Type "show supported languages" to see all ${supportedLanguages.length} supported languages.

Popular Languages:
🇬🇧 English (en)    🇪🇸 Spanish (es)    🇫🇷 French (fr)
🇩🇪 German (de)     🇮🇹 Italian (it)    🇵🇹 Portuguese (pt)
🇷🇺 Russian (ru)    🇯🇵 Japanese (ja)   🇰🇷 Korean (ko)
🇨🇳 Chinese (zh-CN) 🇸🇦 Arabic (ar)     🇮🇳 Hindi (hi)

Features:
✅ 50+ languages supported
✅ Automatic language detection
✅ FREE with NO API KEY required
✅ Fast and accurate translations
''';
  }

  /// Format translation result
  String formatTranslation(TranslationResult result) {
    final buffer = StringBuffer();
    buffer.writeln('🌐 Translation Result:\n');

    if (result.detectedLanguage != null) {
      buffer.writeln('📍 Detected: ${result.detectedLanguage}');
    }

    final sourceLang = _getLanguageName(result.sourceLanguage);
    final targetLang = _getLanguageName(result.targetLanguage);

    buffer.writeln('🔄 $sourceLang → $targetLang\n');
    buffer.writeln('Original:');
    buffer.writeln('   "${result.originalText}"\n');
    buffer.writeln('Translation:');
    buffer.writeln('   "${result.translatedText}"');

    return buffer.toString();
  }

  /// Quick translate with formatted output
  Future<String> quickTranslate({
    required String text,
    required String targetLanguage,
  }) async {
    try {
      // Try to find language by name or code
      final lang = getLanguage(targetLanguage);
      final targetCode = lang?.code ?? targetLanguage.toLowerCase();

      final result = await translate(
        text: text,
        targetLanguage: targetCode,
      );

      if (result == null) {
        return 'Unable to translate. Please try again or check if the language is supported.';
      }

      return formatTranslation(result);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to quick translate', e, stackTrace);
      return 'Translation failed. Please try again.';
    }
  }

  /// Get popular translations for a phrase
  Future<String> getPopularTranslations(String text) async {
    final popularLangs = ['es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh-CN'];

    final buffer = StringBuffer('🌐 "$text" in popular languages:\n\n');

    for (final langCode in popularLangs) {
      final result = await translate(
        text: text,
        targetLanguage: langCode,
      );

      if (result != null) {
        final lang = _getLanguageName(langCode);
        buffer.writeln('🇺🇳 $lang: ${result.translatedText}');
      }

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return buffer.toString();
  }
}
