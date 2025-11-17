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
import '../recipes/recipe_service.dart';
import '../dictionary/dictionary_service.dart';
import '../holidays/holidays_service.dart';
import '../currency/currency_service.dart';
import '../location/ip_location_service.dart';
import '../inspiration/inspiration_service.dart';
import '../speech/speech_service.dart';
import '../proactive/proactive_assistant.dart';
import '../../data/user_profile.dart';
import '../trivia/trivia_service.dart';
import '../books/books_service.dart';
import '../sports/sports_service.dart';
import '../movies/movies_service.dart';
import '../fitness/fitness_service.dart';
import '../nutrition/nutrition_service.dart';

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

      // Initialize all entertainment & wellness services
      await Future.wait([
        QuotesService.instance.init(),
        JokesService.instance.init(),
        FactsService.instance.init(),
        ActivityService.instance.init(),
        AdviceService.instance.init(),
        AffirmationsService.instance.init(),
      ]);

      // Initialize new utility services
      await Future.wait([
        RecipeService.instance.init(),
        DictionaryService.instance.init(),
        HolidaysService.instance.init(),
        CurrencyService.instance.init(),
        IPLocationService.instance.init(),
        InspirationService.instance.init(),
      ]);

      // Initialize WORLD-CLASS entertainment & learning services
      await Future.wait([
        TriviaService.instance.init(),
        BooksService.instance.init(),
        SportsService.instance.init(),
        MoviesService.instance.init(),
        FitnessService.instance.init(),
        NutritionService.instance.init(),
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

      final lowerMessage = message.toLowerCase();

      // Check for specific commands

      // TRIVIA & QUIZZES
      if (lowerMessage.contains('trivia') || lowerMessage.contains('quiz') || lowerMessage.contains('question')) {
        return await _handleTriviaRequest(message);
      }

      // BOOKS & READING
      if (lowerMessage.contains('book') || lowerMessage.contains('read') || lowerMessage.contains('author')) {
        return await _handleBookRequest(message);
      }

      // SPORTS & SCORES
      if (lowerMessage.contains('sport') || lowerMessage.contains('team') || lowerMessage.contains('match') ||
          lowerMessage.contains('game') || lowerMessage.contains('score')) {
        return await _handleSportsRequest(message);
      }

      // MOVIES & TV
      if (lowerMessage.contains('movie') || lowerMessage.contains('film') || lowerMessage.contains('tv show') ||
          lowerMessage.contains('watch')) {
        return await _handleMovieRequest(message);
      }

      // FITNESS & WORKOUT
      if (lowerMessage.contains('workout') || lowerMessage.contains('exercise') || lowerMessage.contains('fitness') ||
          lowerMessage.contains('gym')) {
        return await _handleFitnessRequest(message);
      }

      // NUTRITION & FOOD
      if (lowerMessage.contains('nutrition') || lowerMessage.contains('calorie') || lowerMessage.contains('diet') ||
          lowerMessage.contains('healthy eat')) {
        return await _handleNutritionRequest(message);
      }

      // RECIPES & COOKING
      if (lowerMessage.contains('recipe') || lowerMessage.contains('cook') || lowerMessage.contains('meal')) {
        return await _handleRecipeRequest(message);
      }

      // DICTIONARY
      if (lowerMessage.contains('define') || lowerMessage.contains('what does') || lowerMessage.contains('meaning of')) {
        return await _handleDictionaryRequest(message);
      }

      // CURRENCY
      if (lowerMessage.contains('currency') || lowerMessage.contains('exchange') || lowerMessage.contains('convert')) {
        return await _handleCurrencyRequest(message);
      }

      // HOLIDAYS
      if (lowerMessage.contains('holiday') || lowerMessage.contains('public holiday')) {
        return await _handleHolidayRequest(message);
      }

      // LOCATION
      if (lowerMessage.contains('my location') || lowerMessage.contains('where am i')) {
        return await IPLocationService.instance.getLocationSummary();
      }

      // Parse intent for other requests
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

      // Check if today is a holiday
      final isHoliday = await HolidaysService.instance.isTodayPublicHoliday('BA');
      if (isHoliday) {
        final holidays = await HolidaysService.instance.getHolidays(
          countryCode: 'BA',
          year: now.year,
        );
        final todayHoliday = holidays.where((h) => h.date.startsWith('${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}')).firstOrNull;
        if (todayHoliday != null) {
          briefingParts.add('\n🎉 Today is ${todayHoliday.name}!');
        }
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

      // Random meal suggestion for the day
      final meal = await RecipeService.instance.getRandomMeal();
      if (meal != null) {
        briefingParts.add('\n🍳 Meal Idea: ${meal.name}');
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

      // Check for upcoming holidays
      final nextHolidays = await HolidaysService.instance.getNextHolidays('BA');
      if (nextHolidays.isNotEmpty) {
        final next = nextHolidays.first;
        wrapupParts.add('\n🎉 Next Holiday: ${next.name} (${next.date})');
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

  /// Handle recipe request
  Future<String> _handleRecipeRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check if user wants random recipe
      if (lowerMessage.contains('random') || lowerMessage.contains('suggest')) {
        final meal = await RecipeService.instance.getRandomMeal();
        if (meal != null) {
          return '🍳 Recipe Suggestion: ${meal.name}\n\n'
              '📝 Category: ${meal.category}\n'
              '🌍 Cuisine: ${meal.area}\n\n'
              '📋 Ingredients:\n${meal.ingredientsList}\n\n'
              '👨‍🍳 Instructions:\n${meal.instructions?.substring(0, 200) ?? "See full recipe for instructions"}...';
        }
      }

      // Try to extract search term
      final searchTerm = message
          .replaceAll(RegExp(r'(recipe|cook|meal|for|make|how to)', caseSensitive: false), '')
          .trim();

      if (searchTerm.isNotEmpty) {
        final meals = await RecipeService.instance.searchMealsByName(searchTerm);
        if (meals.isNotEmpty) {
          final meal = meals.first;
          return '🍳 Found: ${meal.name}\n\n'
              '📝 Category: ${meal.category}\n'
              '🌍 Cuisine: ${meal.area}';
        }
      }

      return 'I can help you find recipes! Try asking for "random recipe" or "recipe for chicken"';
    } catch (e, stackTrace) {
      AppLogger.error('Error handling recipe request', e, stackTrace);
      return 'Unable to fetch recipe at the moment.';
    }
  }

  /// Handle dictionary request
  Future<String> _handleDictionaryRequest(String message) async {
    try {
      // Extract word from message
      final word = message
          .replaceAll(RegExp(r'(define|what does|meaning of|definition of)', caseSensitive: false), '')
          .replaceAll('mean', '')
          .trim()
          .split(' ')
          .first;

      if (word.isNotEmpty) {
        return await DictionaryService.instance.getWordSummary(word);
      }

      return 'What word would you like me to define?';
    } catch (e, stackTrace) {
      AppLogger.error('Error handling dictionary request', e, stackTrace);
      return 'Unable to fetch definition at the moment.';
    }
  }

  /// Handle currency request
  Future<String> _handleCurrencyRequest(String message) async {
    try {
      // Try to detect currency conversion request
      // Pattern: "convert X USD to EUR"
      final pattern = RegExp(r'(\d+\.?\d*)\s*([A-Z]{3})\s*to\s*([A-Z]{3})', caseSensitive: false);
      final match = pattern.firstMatch(message);

      if (match != null) {
        final amount = double.parse(match.group(1)!);
        final from = match.group(2)!.toUpperCase();
        final to = match.group(3)!.toUpperCase();

        return await CurrencyService.instance.getConversionSummary(
          from: from,
          to: to,
          amount: amount,
        );
      }

      // Default: show popular rates
      return await CurrencyService.instance.getPopularRates();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling currency request', e, stackTrace);
      return 'Unable to fetch currency rates at the moment.';
    }
  }

  /// Handle holiday request
  Future<String> _handleHolidayRequest(String message) async {
    try {
      return await HolidaysService.instance.getHolidaysSummary('BA');
    } catch (e, stackTrace) {
      AppLogger.error('Error handling holiday request', e, stackTrace);
      return 'Unable to fetch holiday information at the moment.';
    }
  }

  /// Handle trivia request
  Future<String> _handleTriviaRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for specific category
      if (lowerMessage.contains('science')) {
        return await TriviaService.instance.getTriviaQuizSummary(category: 'Science & Nature');
      } else if (lowerMessage.contains('history')) {
        return await TriviaService.instance.getTriviaQuizSummary(category: 'History');
      } else if (lowerMessage.contains('sport')) {
        return await TriviaService.instance.getTriviaQuizSummary(category: 'Sports');
      } else if (lowerMessage.contains('movie') || lowerMessage.contains('film')) {
        return await TriviaService.instance.getTriviaQuizSummary(category: 'Film');
      }

      // Default: random quiz
      return await TriviaService.instance.getTriviaQuizSummary();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling trivia request', e, stackTrace);
      return 'Unable to start trivia quiz at the moment.';
    }
  }

  /// Handle book request
  Future<String> _handleBookRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for genre/subject search
      if (lowerMessage.contains('fiction') || lowerMessage.contains('sci-fi') ||
          lowerMessage.contains('fantasy') || lowerMessage.contains('mystery')) {
        final genre = lowerMessage.contains('fiction') ? 'fiction' :
                      lowerMessage.contains('sci-fi') ? 'science fiction' :
                      lowerMessage.contains('fantasy') ? 'fantasy' : 'mystery';
        return await BooksService.instance.getGenreRecommendations(genre);
      }

      // Extract search term
      final searchTerm = message
          .replaceAll(RegExp(r'(book|read|author|about|find|search)', caseSensitive: false), '')
          .trim();

      if (searchTerm.isNotEmpty) {
        return await BooksService.instance.getBookSummary(searchTerm);
      }

      // Default: trending books
      final books = await BooksService.instance.getTrendingBooks();
      if (books.isNotEmpty) {
        final buffer = StringBuffer('📚 Popular Books:\n\n');
        for (var i = 0; i < books.length && i < 5; i++) {
          buffer.writeln('${i + 1}. ${books[i].title}');
          if (books[i].authors.isNotEmpty) {
            buffer.writeln('   by ${books[i].authors.first}\n');
          }
        }
        return buffer.toString();
      }

      return 'I can help you find books! Try asking for "science fiction books" or "books about history"';
    } catch (e, stackTrace) {
      AppLogger.error('Error handling book request', e, stackTrace);
      return 'Unable to search books at the moment.';
    }
  }

  /// Handle sports request
  Future<String> _handleSportsRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for today's sports
      if (lowerMessage.contains('today') || lowerMessage.contains('now')) {
        return await SportsService.instance.getTodaysSports();
      }

      // Check for specific team
      final teamPattern = RegExp(r'(team|about)\s+(.+)', caseSensitive: false);
      final teamMatch = teamPattern.firstMatch(message);
      if (teamMatch != null) {
        final teamName = teamMatch.group(2)!.trim();
        return await SportsService.instance.getTeamSummary(teamName);
      }

      // Default: today's sports
      return await SportsService.instance.getTodaysSports();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling sports request', e, stackTrace);
      return 'Unable to fetch sports information at the moment.';
    }
  }

  /// Handle movie request
  Future<String> _handleMovieRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for TV shows
      if (lowerMessage.contains('tv') || lowerMessage.contains('show') || lowerMessage.contains('series')) {
        return await MoviesService.instance.getTVShowRecommendations();
      }

      // Check for trending/popular
      if (lowerMessage.contains('trending') || lowerMessage.contains('popular') || lowerMessage.contains('recommend')) {
        return await MoviesService.instance.getMovieRecommendations(trending: true);
      }

      // Extract search term
      final searchTerm = message
          .replaceAll(RegExp(r'(movie|film|watch|about|find)', caseSensitive: false), '')
          .trim();

      if (searchTerm.isNotEmpty) {
        return await MoviesService.instance.getMovieInfo(searchTerm);
      }

      // Default: trending movies
      return await MoviesService.instance.getMovieRecommendations();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling movie request', e, stackTrace);
      return 'Unable to fetch movie information at the moment.';
    }
  }

  /// Handle fitness request
  Future<String> _handleFitnessRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for quick workout
      if (lowerMessage.contains('quick') || lowerMessage.contains('15') || lowerMessage.contains('short')) {
        return await FitnessService.instance.getQuickWorkout(durationMinutes: 15);
      }

      // Check for specific muscle group
      if (lowerMessage.contains('chest')) {
        return await FitnessService.instance.getWorkoutRecommendations(level: 'beginner');
      } else if (lowerMessage.contains('leg')) {
        return await FitnessService.instance.getWorkoutRecommendations(level: 'beginner');
      }

      // Default: workout recommendations
      return await FitnessService.instance.getWorkoutRecommendations(
        goal: 'General Fitness',
        level: 'beginner',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error handling fitness request', e, stackTrace);
      return 'Unable to fetch workout information at the moment.';
    }
  }

  /// Handle nutrition request
  Future<String> _handleNutritionRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for healthy tips
      if (lowerMessage.contains('tip') || lowerMessage.contains('advice') || lowerMessage.contains('guide')) {
        return NutritionService.instance.getHealthyEatingTips();
      }

      // Check for specific food nutrition
      final foodPattern = RegExp(r'(nutrition|calorie|in)\s+(.+)', caseSensitive: false);
      final foodMatch = foodPattern.firstMatch(message);
      if (foodMatch != null) {
        final foodName = foodMatch.group(2)!.trim();
        return await NutritionService.instance.getFoodNutrition(foodName);
      }

      // Default: healthy eating tips
      return NutritionService.instance.getHealthyEatingTips();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling nutrition request', e, stackTrace);
      return 'Unable to fetch nutrition information at the moment.';
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

      // Default to quote or inspiration
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
    final inspiration = await InspirationService.instance.getRandomInspiration();

    return '$greeting\n\n$inspiration\n\nHow can I assist you today?';
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
    return '''I'm Dona, your WORLD-CLASS personal AI assistant! Here's what I can do:

📅 Calendar & Events
  • Check your schedule
  • Create and manage events

🌤️ Weather & News
  • Get weather forecasts
  • Read latest news headlines

🎮 TRIVIA & QUIZZES (NEW!)
  • Play trivia games across 24 categories
  • Test your knowledge with 4,000+ questions
  • Science, History, Sports, Movies & more!

📚 BOOKS & READING (NEW!)
  • Search 30 million books
  • Find books by genre, author, or title
  • Get book recommendations

⚽ SPORTS & SCORES (NEW!)
  • Today's sports events
  • Team information & scores
  • 1,200+ leagues worldwide

🎬 MOVIES & TV SHOWS (NEW!)
  • Trending movies and TV shows
  • Search by title or genre
  • Movie recommendations with ratings

💪 FITNESS & WORKOUTS (NEW!)
  • Custom workout plans
  • Exercise database with instructions
  • Quick 15-minute routines

🥗 NUTRITION & DIET (NEW!)
  • Food nutrition information
  • Calorie tracking
  • Healthy eating tips & meal plans

🍳 Recipes & Cooking
  • Find recipes by name or ingredient
  • Get random meal suggestions
  • 500+ recipes with instructions

📖 Dictionary & Learning
  • Define words with examples
  • Get synonyms and antonyms
  • Multiple language support

💱 Currency & Finance
  • Convert 160+ currencies
  • Real-time exchange rates
  • Popular currency tracking

🎉 Holidays & Events
  • Check public holidays (100+ countries)
  • Upcoming celebrations
  • Holiday countdown

📍 Location
  • Get your IP location
  • Timezone information
  • ISP details

💡 Smart Suggestions
  • Activity recommendations
  • Motivational quotes & affirmations
  • Interesting facts & jokes
  • Inspirational content

🎯 Proactive Assistance
  • Morning briefings
  • Evening wrap-ups
  • Meeting reminders
  • Travel time alerts

🗣️ Voice Control
  • Voice commands
  • Text-to-speech responses

🌟 27 FREE APIs integrated for the ultimate experience!
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
