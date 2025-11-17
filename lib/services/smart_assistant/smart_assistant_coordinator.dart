import 'dart:async';
import '../../core/utils/logger.dart';
import '../ai/ai_service.dart';
import '../ai/intent_recognition.dart';
import '../weather/weather_service.dart';
import '../news/news_service.dart';
import '../calendar/calendar_service.dart';
import '../quotes/quotes_service.dart';
import '../jokes/jokes_service.dart';
import '../facts/facts_service.dart';
import '../activity/activity_service.dart';
import '../advice/advice_service.dart';
import '../affirmations/affirmations_service.dart';
import '../speech/speech_service.dart';
import '../proactive/proactive_assistant.dart';
import '../../data/user_profile.dart';

/// Smart Assistant Coordinator
///
/// This is the brain of Dona AI - coordinates all services to provide
/// intelligent, contextual, and proactive assistance.
class SmartAssistantCoordinator {
  static final SmartAssistantCoordinator _instance = SmartAssistantCoordinator._internal();
  static SmartAssistantCoordinator get instance => _instance;

  SmartAssistantCoordinator._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final ConversationContext _context = ConversationContext();
  Timer? _morningRoutineTimer;
  Timer? _eveningRoutineTimer;

  Future<void> init() async {
    try {
      AppLogger.info('Initializing Smart Assistant Coordinator...');

      // Initialize all services
      await Future.wait([
        QuotesService.instance.init(),
        JokesService.instance.init(),
        FactsService.instance.init(),
        ActivityService.instance.init(),
        AdviceService.instance.init(),
        AffirmationsService.instance.init(),
      ]);

      // Start proactive monitoring
      ProactiveAssistant.instance.startMonitoring();

      // Schedule daily routines
      _scheduleDailyRoutines();

      _isInitialized = true;
      AppLogger.info('Smart Assistant Coordinator initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Smart Assistant Coordinator', e, stackTrace);
    }
  }

  /// Handle user message with full context awareness
  Future<String> handleMessage(String message, {bool useVoice = false}) async {
    try {
      // Add to context
      _context.addUserMessage(message);

      // Parse intent
      final intent = await IntentRecognizer.instance.parseIntent(message);

      // Log user interaction
      UserProfile.instance.logInteraction(
        intent.type.name,
        intent.entities,
      );

      String response;

      // Handle based on intent
      switch (intent.type) {
        case IntentType.checkWeather:
          response = await _handleWeatherIntent(intent);
          break;
        case IntentType.readNews:
          response = await _handleNewsIntent(intent);
          break;
        case IntentType.greeting:
          response = await _handleGreeting();
          break;
        case IntentType.help:
          response = _getHelpMessage();
          break;
        case IntentType.checkCalendar:
          response = await _handleCalendarIntent(intent);
          break;
        default:
          // Use AI for general conversation
          response = await AIService.instance.chat(message);
      }

      // Add response to context
      _context.addAssistantMessage(response);

      // Speak if voice mode enabled
      if (useVoice && SpeechService.instance.isInitialized) {
        await SpeechService.instance.speak(response);
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Error handling message', e, stackTrace);
      return 'I apologize, but I encountered an error. Please try again.';
    }
  }

  /// Morning briefing - comprehensive daily start
  Future<String> getMorningBriefing() async {
    try {
      AppLogger.info('Generating morning briefing...');

      final now = DateTime.now();
      final greeting = _getTimeBasedGreeting();

      final List<String> briefingParts = [greeting];

      // Get quote of the day
      final quote = await QuotesService.instance.getQuoteOfTheDay();
      if (quote != null) {
        briefingParts.add('\n📖 Quote of the Day:\n"${quote.text}" - ${quote.author}');
      }

      // Get affirmation
      final affirmation = await AffirmationsService.instance.getRandomAffirmation();
      if (affirmation != null) {
        briefingParts.add('\n💪 Today\'s Affirmation:\n${affirmation.text}');
      }

      // Get weather
      final weather = await WeatherService.instance.getCurrentWeather();
      if (weather != null) {
        briefingParts.add(
          '\n🌤️ Weather in ${weather.cityName}:\n'
          '${weather.temperature.toInt()}°C, ${weather.description}\n'
          'High: ${weather.tempMax.toInt()}°C, Low: ${weather.tempMin.toInt()}°C',
        );
      }

      // Get calendar events
      final events = await CalendarService.instance.getUpcomingEvents(maxResults: 5);
      if (events.isNotEmpty) {
        briefingParts.add('\n📅 Today\'s Schedule:');
        for (var event in events.take(3)) {
          final timeStr = _formatTime(event.startTime);
          briefingParts.add('  • $timeStr - ${event.title}');
        }
      } else {
        briefingParts.add('\n📅 You have no scheduled events today. Great time to be productive!');
      }

      // Get news headlines
      final news = await NewsService.instance.getTopNews(limit: 3);
      if (news.isNotEmpty) {
        briefingParts.add('\n📰 Top News:');
        for (var article in news) {
          briefingParts.add('  • ${article.title}');
        }
      }

      // Add motivational close
      briefingParts.add('\n✨ Make today amazing!');

      final briefing = briefingParts.join('\n');

      // Log interaction
      UserProfile.instance.logInteraction('morning_briefing', {});

      return briefing;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate morning briefing', e, stackTrace);
      return 'Good morning! I encountered an issue preparing your briefing, but I\'m here to help with anything you need.';
    }
  }

  /// Evening wrap-up - end of day summary
  Future<String> getEveningWrapup() async {
    try {
      AppLogger.info('Generating evening wrap-up...');

      final List<String> wrapupParts = ['🌅 Evening Wrap-up'];

      // Tomorrow's preview
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowEvents = await CalendarService.instance.getEventsInRange(
        tomorrow,
        tomorrow.add(const Duration(days: 1)),
      );

      if (tomorrowEvents.isNotEmpty) {
        wrapupParts.add('\n📅 Tomorrow\'s Schedule:');
        for (var event in tomorrowEvents.take(5)) {
          final timeStr = _formatTime(event.startTime);
          wrapupParts.add('  • $timeStr - ${event.title}');
        }
      } else {
        wrapupParts.add('\n📅 No events scheduled for tomorrow.');
      }

      // Tomorrow's weather
      final weather = await WeatherService.instance.getCurrentWeather();
      if (weather != null) {
        wrapupParts.add(
          '\n🌤️ Tomorrow\'s Weather:\n'
          'Expected: ${weather.description}, ${weather.temperature.toInt()}°C',
        );
      }

      // Evening affirmation
      final affirmation = await AffirmationsService.instance.getRandomAffirmation();
      if (affirmation != null) {
        wrapupParts.add('\n🌙 Evening Reflection:\n${affirmation.text}');
      }

      // Relaxation suggestion
      final activity = await ActivityService.instance.getRelaxationActivity();
      if (activity != null) {
        wrapupParts.add('\n😌 Relaxation Suggestion:\n${activity.activity}');
      }

      wrapupParts.add('\n✨ Rest well and recharge for tomorrow!');

      return wrapupParts.join('\n');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate evening wrap-up', e, stackTrace);
      return 'Have a wonderful evening! Rest well.';
    }
  }

  /// Get personalized suggestion based on context
  Future<String> getPersonalizedSuggestion() async {
    try {
      final hour = DateTime.now().hour;

      // Morning suggestions (6 AM - 11 AM)
      if (hour >= 6 && hour < 11) {
        final activity = await ActivityService.instance.getEducationalActivity();
        if (activity != null) {
          return '🌅 Morning suggestion: ${activity.activity}';
        }
      }

      // Afternoon suggestions (12 PM - 5 PM)
      else if (hour >= 12 && hour < 17) {
        final activity = await ActivityService.instance.getRecreationalActivity();
        if (activity != null) {
          return '☀️ Afternoon break idea: ${activity.activity}';
        }
      }

      // Evening suggestions (6 PM - 10 PM)
      else if (hour >= 18 && hour < 22) {
        final activity = await ActivityService.instance.getRelaxationActivity();
        if (activity != null) {
          return '🌙 Evening relaxation: ${activity.activity}';
        }
      }

      // Default random suggestion
      final activity = await ActivityService.instance.getRandomActivity();
      return activity != null ? '💡 Suggestion: ${activity.activity}' : 'How can I help you today?';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get personalized suggestion', e, stackTrace);
      return 'How can I assist you?';
    }
  }

  /// Get entertainment (joke, fact, or quote)
  Future<String> getEntertainment({String? type}) async {
    try {
      if (type == 'joke' || (type == null && DateTime.now().second % 3 == 0)) {
        final joke = await JokesService.instance.getRandomJoke();
        if (joke != null) {
          return '😄 ${joke.setup}\n\n${joke.punchline}';
        }
      }

      if (type == 'fact' || (type == null && DateTime.now().second % 3 == 1)) {
        final fact = await FactsService.instance.getRandomFact();
        if (fact != null) {
          return '🧠 Did you know?\n${fact.text}';
        }
      }

      // Default to quote
      final quote = await QuotesService.instance.getRandomQuote();
      if (quote != null) {
        return '📖 "${quote.text}"\n- ${quote.author}';
      }

      return 'Let me know how I can help you!';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get entertainment', e, stackTrace);
      return 'What would you like to do?';
    }
  }

  /// Handle weather intent
  Future<String> _handleWeatherIntent(Intent intent) async {
    final city = intent.entities['city'] ?? intent.entities['where'];
    final weather = await WeatherService.instance.getCurrentWeather(city: city as String?);

    if (weather != null) {
      return 'The weather in ${weather.cityName} is ${weather.description} '
          'with a temperature of ${weather.temperature.toInt()}°C. '
          'It feels like ${weather.feelsLike.toInt()}°C. '
          'The humidity is ${weather.humidity}%.';
    }

    return 'I couldn\'t fetch the weather information right now. Please try again.';
  }

  /// Handle news intent
  Future<String> _handleNewsIntent(Intent intent) async {
    final news = await NewsService.instance.getTopNews(limit: 5);

    if (news.isEmpty) {
      return 'I couldn\'t fetch the news right now. Please try again later.';
    }

    final headlines = news.map((article) => '• ${article.title}').join('\n');
    return '📰 Here are the top headlines:\n\n$headlines';
  }

  /// Handle greeting
  Future<String> _handleGreeting() async {
    final greeting = _getTimeBasedGreeting();
    final quote = await QuotesService.instance.getRandomQuote();

    if (quote != null) {
      return '$greeting\n\n"${quote.text}" - ${quote.author}\n\nHow can I assist you today?';
    }

    return '$greeting\nHow can I help you today?';
  }

  /// Handle calendar intent
  Future<String> _handleCalendarIntent(Intent intent) async {
    final events = await CalendarService.instance.getUpcomingEvents(maxResults: 10);

    if (events.isEmpty) {
      return 'You have no upcoming events on your calendar.';
    }

    final eventList = events.take(5).map((event) {
      final timeStr = _formatTime(event.startTime);
      return '• $timeStr - ${event.title}';
    }).join('\n');

    return '📅 Your upcoming events:\n\n$eventList';
  }

  /// Get time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return '☀️ Good morning!';
    } else if (hour < 17) {
      return '👋 Good afternoon!';
    } else if (hour < 22) {
      return '🌆 Good evening!';
    } else {
      return '🌙 Good night!';
    }
  }

  /// Get help message
  String _getHelpMessage() {
    return '''I'm Dona, your personal AI assistant! Here's what I can do:

📅 Calendar & Events
  • Check your schedule
  • Create and manage events

🌤️ Weather & News
  • Get weather forecasts
  • Read latest news headlines

💡 Smart Suggestions
  • Activity recommendations
  • Motivational quotes & affirmations
  • Interesting facts & jokes

🎯 Proactive Assistance
  • Morning briefings
  • Meeting reminders
  • Travel time alerts

🗣️ Voice Control
  • Voice commands
  • Text-to-speech responses

Just ask me anything, and I'll do my best to help!''';
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Schedule daily routines
  void _scheduleDailyRoutines() {
    // Morning briefing at 7 AM
    final now = DateTime.now();
    var morningTime = DateTime(now.year, now.month, now.day, 7, 0);
    if (morningTime.isBefore(now)) {
      morningTime = morningTime.add(const Duration(days: 1));
    }

    final morningDelay = morningTime.difference(now);
    _morningRoutineTimer = Timer.periodic(const Duration(days: 1), (_) async {
      final briefing = await getMorningBriefing();
      AppLogger.info('Morning briefing ready: $briefing');
      // You can add notification here
    });

    // Evening wrap-up at 6 PM
    var eveningTime = DateTime(now.year, now.month, now.day, 18, 0);
    if (eveningTime.isBefore(now)) {
      eveningTime = eveningTime.add(const Duration(days: 1));
    }

    final eveningDelay = eveningTime.difference(now);
    _eveningRoutineTimer = Timer.periodic(const Duration(days: 1), (_) async {
      final wrapup = await getEveningWrapup();
      AppLogger.info('Evening wrap-up ready: $wrapup');
      // You can add notification here
    });
  }

  /// Clear conversation context
  void clearContext() {
    _context.clear();
    AppLogger.debug('Conversation context cleared');
  }

  /// Get conversation context
  String getContextSummary() {
    return _context.getLastMessages(5);
  }

  /// Dispose resources
  void dispose() {
    _morningRoutineTimer?.cancel();
    _eveningRoutineTimer?.cancel();
    ProactiveAssistant.instance.stopMonitoring();
    AppLogger.info('Smart Assistant Coordinator disposed');
  }
}
