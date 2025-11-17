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
import '../sleep/sleep_service.dart';
import '../calculator/calculator_service.dart';
import '../translation/translation_service.dart';
import '../tasks/tasks_reminders_service.dart';
import '../music/music_control_service.dart';
import '../travel/travel_transportation_service.dart';
import '../photos/photo_gallery_service.dart';
import '../cat_facts/cat_facts_service.dart';
import '../dad_jokes/dad_jokes_service.dart';
import '../astronomy/astronomy_service.dart';
import '../cocktails/cocktails_service.dart';
import '../random_user/random_user_service.dart';

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
        SleepService.instance.init(),
        CalculatorService.instance.init(),
        TranslationService.instance.init(),
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

      // SLEEP & WELLNESS
      if (lowerMessage.contains('sleep') || lowerMessage.contains('alarm') || lowerMessage.contains('wake') ||
          lowerMessage.contains('rest') || lowerMessage.contains('bedtime')) {
        return await _handleSleepRequest(message);
      }

      // TASKS & REMINDERS
      if (lowerMessage.contains('task') || lowerMessage.contains('todo') || lowerMessage.contains('remind') ||
          lowerMessage.contains('due') || lowerMessage.contains('add task') || lowerMessage.contains('create task') ||
          lowerMessage.contains('my tasks') || lowerMessage.contains('show tasks')) {
        return await _handleTasksRequest(message);
      }

      // MUSIC & PLAYBACK CONTROL
      if (lowerMessage.contains('play') || lowerMessage.contains('pause') || lowerMessage.contains('music') ||
          lowerMessage.contains('song') || lowerMessage.contains('spotify') || lowerMessage.contains('apple music') ||
          lowerMessage.contains('skip') || lowerMessage.contains('next track') || lowerMessage.contains('volume')) {
        return await _handleMusicRequest(message);
      }

      // TRAVEL & TRANSPORTATION
      if (lowerMessage.contains('flight') || lowerMessage.contains('travel') || lowerMessage.contains('direction') ||
          lowerMessage.contains('how to get') || lowerMessage.contains('transit') || lowerMessage.contains('trip') ||
          lowerMessage.contains('destination') || lowerMessage.contains('visit')) {
        return await _handleTravelRequest(message);
      }

      // PHOTOS & GALLERY
      if (lowerMessage.contains('photo') || lowerMessage.contains('picture') || lowerMessage.contains('gallery') ||
          lowerMessage.contains('album') || lowerMessage.contains('favorite') && lowerMessage.contains('photo')) {
        return await _handlePhotoRequest(message);
      }

      // CAT FACTS
      if (lowerMessage.contains('cat fact') || lowerMessage.contains('tell me about cat')) {
        return await CatFactsService.instance.getCatFactSummary();
      }

      // DAD JOKES
      if (lowerMessage.contains('dad joke')) {
        return await DadJokesService.instance.getDadJokeSummary();
      }

      // ASTRONOMY
      if (lowerMessage.contains('astronomy') || lowerMessage.contains('space picture') ||
          lowerMessage.contains('nasa picture') || lowerMessage.contains('picture of the day')) {
        return await AstronomyService.instance.getAstronomySummary();
      }

      // COCKTAILS
      if (lowerMessage.contains('cocktail') || lowerMessage.contains('drink recipe') ||
          lowerMessage.contains('how to make') && (lowerMessage.contains('martini') ||
          lowerMessage.contains('margarita') || lowerMessage.contains('mojito'))) {
        return await _handleCocktailRequest(message);
      }

      // RANDOM USER
      if (lowerMessage.contains('random user') || lowerMessage.contains('generate user') ||
          lowerMessage.contains('test user')) {
        return await RandomUserService.instance.getUserSummary();
      }

      // CALCULATOR & UNIT CONVERSION
      if ((lowerMessage.contains('calculate') || lowerMessage.contains('what is') ||
          lowerMessage.contains('how much is') || RegExp(r'\d+\s*[\+\-\*\/\^]\s*\d+').hasMatch(message)) &&
          !lowerMessage.contains('translate')) {
        return await _handleCalculatorRequest(message);
      }

      // TRANSLATION
      if (lowerMessage.contains('translate') || lowerMessage.contains('in spanish') ||
          lowerMessage.contains('in french') || lowerMessage.contains('in german') ||
          lowerMessage.contains('what is') && (lowerMessage.contains('in ') || lowerMessage.contains(' to '))) {
        return await _handleTranslationRequest(message);
      }

      // Unit conversion (separate from calculator if no translate keyword)
      if (lowerMessage.contains('convert') && !lowerMessage.contains('translate')) {
        return await _handleCalculatorRequest(message);
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

  /// Handle sleep & wellness request
  Future<String> _handleSleepRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Set smart alarm
      if (lowerMessage.contains('set') && lowerMessage.contains('alarm')) {
        // Parse alarm time window
        final timePattern = RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm)?', caseSensitive: false);
        final matches = timePattern.allMatches(message).toList();

        if (matches.length >= 2) {
          // Extract earliest and latest wake times
          final now = DateTime.now();
          final tomorrow = now.add(const Duration(days: 1));

          // Parse first time (earliest)
          final firstMatch = matches[0];
          var hour1 = int.parse(firstMatch.group(1)!);
          final minute1 = firstMatch.group(2) != null ? int.parse(firstMatch.group(2)!) : 0;
          final period1 = firstMatch.group(3)?.toLowerCase();
          if (period1 == 'pm' && hour1 < 12) hour1 += 12;
          if (period1 == 'am' && hour1 == 12) hour1 = 0;

          // Parse second time (latest)
          final secondMatch = matches[1];
          var hour2 = int.parse(secondMatch.group(1)!);
          final minute2 = secondMatch.group(2) != null ? int.parse(secondMatch.group(2)!) : 0;
          final period2 = secondMatch.group(3)?.toLowerCase();
          if (period2 == 'pm' && hour2 < 12) hour2 += 12;
          if (period2 == 'am' && hour2 == 12) hour2 = 0;

          final earliestWake = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour1, minute1);
          final latestWake = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour2, minute2);

          final alarm = await SleepService.instance.createSmartAlarm(
            earliestWake: earliestWake,
            latestWake: latestWake,
            label: 'Smart wake',
          );

          return 'Okay! I\'ll wake you between ${_formatTime(alarm.earliestWake)} and ${_formatTime(alarm.latestWake)}.\n'
              '🎯 Optimal wake time: ${alarm.optimalWakeTime != null ? _formatTime(alarm.optimalWakeTime!) : "Calculating..."}\n\n'
              'Your alarm is now active. Sweet dreams! 😴';
        } else if (matches.length == 1) {
          // Single time provided - use 30 minute window
          final match = matches[0];
          var hour = int.parse(match.group(1)!);
          final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
          final period = match.group(3)?.toLowerCase();
          if (period == 'pm' && hour < 12) hour += 12;
          if (period == 'am' && hour == 12) hour = 0;

          final now = DateTime.now();
          final tomorrow = now.add(const Duration(days: 1));
          final targetTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
          final earliestWake = targetTime.subtract(const Duration(minutes: 15));
          final latestWake = targetTime.add(const Duration(minutes: 15));

          final alarm = await SleepService.instance.createSmartAlarm(
            earliestWake: earliestWake,
            latestWake: latestWake,
            label: 'Smart wake',
          );

          return 'Alarm set! I\'ll wake you around ${_formatTime(targetTime)} (between ${_formatTime(earliestWake)} and ${_formatTime(latestWake)}).\n'
              '🎯 Optimal wake time: ${alarm.optimalWakeTime != null ? _formatTime(alarm.optimalWakeTime!) : "Calculating..."}\n\n'
              'Sleep well! 😴';
        }

        return 'Please specify a time range, like "Set alarm between 6:30 and 7:00 AM"';
      }

      // Sleep analysis/summary
      if (lowerMessage.contains('how') && (lowerMessage.contains('slept') || lowerMessage.contains('sleep'))) {
        return await SleepService.instance.getSleepAnalysis();
      }

      // Sleep tips
      if (lowerMessage.contains('tip') || lowerMessage.contains('advice') || lowerMessage.contains('help')) {
        return SleepService.instance.getWellnessTips();
      }

      // Show alarms
      if (lowerMessage.contains('show') && lowerMessage.contains('alarm')) {
        final alarms = SleepService.instance.getActiveAlarms();
        if (alarms.isEmpty) {
          return 'You don\'t have any active alarms. Say "Set alarm between 6:30 and 7:00 AM" to create one.';
        }

        final buffer = StringBuffer('⏰ Your Active Alarms:\n\n');
        for (var i = 0; i < alarms.length; i++) {
          buffer.writeln('${i + 1}. ${SleepService.instance.formatAlarm(alarms[i])}\n');
        }
        return buffer.toString();
      }

      // Default: sleep analysis
      return await SleepService.instance.getSleepAnalysis();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling sleep request', e, stackTrace);
      return 'Unable to process sleep request at the moment.';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Handle calculator & unit conversion request
  Future<String> _handleCalculatorRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for unit conversion
      if (lowerMessage.contains('convert') || lowerMessage.contains('to')) {
        // Parse conversion request: "convert X Y to Z" or "X Y to Z"
        final conversionPattern = RegExp(
          r'(\d+\.?\d*)\s*([a-zA-Z]+)\s+(?:to|in)\s+([a-zA-Z]+)',
          caseSensitive: false,
        );
        final match = conversionPattern.firstMatch(message);

        if (match != null) {
          final value = double.parse(match.group(1)!);
          final fromUnit = match.group(2)!;
          final toUnit = match.group(3)!;

          final result = CalculatorService.instance.convertUnits(
            value: value,
            fromUnit: fromUnit,
            toUnit: toUnit,
          );

          if (result != null) {
            return '🔄 Unit Conversion:\n\n${result.value} ${result.fromUnit} = ${result.formattedResult} ${result.toUnit}';
          } else {
            return 'I couldn\'t convert "$fromUnit" to "$toUnit". ${CalculatorService.instance.getUnitConverterHelp()}';
          }
        }

        // Fallback: Show conversion help
        return CalculatorService.instance.getUnitConverterHelp();
      }

      // Mathematical calculation
      // Extract mathematical expression
      var expression = message
          .replaceAll(RegExp(r'calculate|what is|how much is|equals?', caseSensitive: false), '')
          .trim();

      // Remove question mark
      expression = expression.replaceAll('?', '');

      if (expression.isEmpty) {
        return CalculatorService.instance.getCalculatorHelp();
      }

      final result = CalculatorService.instance.calculate(expression);

      if (result != null) {
        return '🔢 Calculation:\n\n${result.expression} = ${result.formattedResult}';
      } else {
        return 'I couldn\'t calculate that expression. ${CalculatorService.instance.getCalculatorHelp()}';
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error handling calculator request', e, stackTrace);
      return 'Unable to process calculation. Try: "Calculate 5 + 3" or "Convert 10 km to miles"';
    }
  }

  /// Handle translation request
  Future<String> _handleTranslationRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Check for "show supported languages"
      if (lowerMessage.contains('show') && lowerMessage.contains('language')) {
        return TranslationService.instance.getSupportedLanguages();
      }

      // Parse translation request: "translate X to Y" or "what is X in Y"
      var translationPattern = RegExp(
        r'translate\s+(.+?)\s+to\s+([a-zA-Z]+)',
        caseSensitive: false,
      );
      var match = translationPattern.firstMatch(message);

      if (match != null) {
        final text = match.group(1)!.trim();
        final targetLang = match.group(2)!.trim();

        return await TranslationService.instance.quickTranslate(
          text: text,
          targetLanguage: targetLang,
        );
      }

      // Alternative pattern: "what is X in Y"
      translationPattern = RegExp(
        r'what\s+is\s+(.+?)\s+in\s+([a-zA-Z]+)',
        caseSensitive: false,
      );
      match = translationPattern.firstMatch(message);

      if (match != null) {
        final text = match.group(1)!.trim();
        final targetLang = match.group(2)!.trim();

        return await TranslationService.instance.quickTranslate(
          text: text,
          targetLanguage: targetLang,
        );
      }

      // Check for "translate X in Spanish/French/etc"
      for (final lang in TranslationService.supportedLanguages) {
        if (lowerMessage.contains('in ${lang.name.toLowerCase()}')) {
          final text = message
              .replaceAll(RegExp('translate|in ${lang.name}', caseSensitive: false), '')
              .trim();

          if (text.isNotEmpty) {
            return await TranslationService.instance.quickTranslate(
              text: text,
              targetLanguage: lang.code,
            );
          }
        }
      }

      // Fallback: Show translation help
      return TranslationService.instance.getTranslationHelp();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling translation request', e, stackTrace);
      return 'Unable to translate. Try: "Translate hello to Spanish" or "What is goodbye in French"';
    }
  }

  /// Handle tasks & reminders request
  Future<String> _handleTasksRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Show all tasks
      if (lowerMessage.contains('show') || lowerMessage.contains('list') || lowerMessage.contains('my tasks')) {
        return await TasksRemindersService.instance.getTaskSummary();
      }

      // Show today's tasks
      if (lowerMessage.contains('today')) {
        final tasks = await TasksRemindersService.instance.getTasksDueToday();
        if (tasks.isEmpty) {
          return '✅ No tasks due today! You\'re all caught up.';
        }

        final buffer = StringBuffer('📅 Tasks Due Today (${tasks.length}):\n\n');
        for (var i = 0; i < tasks.length; i++) {
          buffer.writeln('${i + 1}. ${TasksRemindersService.instance.formatTask(tasks[i])}\n');
        }
        return buffer.toString();
      }

      // Show overdue tasks
      if (lowerMessage.contains('overdue') || lowerMessage.contains('late')) {
        final tasks = await TasksRemindersService.instance.getOverdueTasks();
        if (tasks.isEmpty) {
          return '✅ No overdue tasks! Great job staying on top of things.';
        }

        final buffer = StringBuffer('⚠️ Overdue Tasks (${tasks.length}):\n\n');
        for (var i = 0; i < tasks.length; i++) {
          buffer.writeln('${i + 1}. ${TasksRemindersService.instance.formatTask(tasks[i])}\n');
        }
        return buffer.toString();
      }

      // Create new task
      if (lowerMessage.contains('create') || lowerMessage.contains('add') || lowerMessage.contains('new task')) {
        // Parse task details
        var taskTitle = message
            .replaceAll(RegExp(r'(create|add|new)\s+(task|todo|reminder)', caseSensitive: false), '')
            .trim();

        // Remove common words
        taskTitle = taskTitle.replaceAll(RegExp(r'^(to|a)\s+', caseSensitive: false), '');

        if (taskTitle.isEmpty) {
          return 'Please specify the task. Example: "Add task buy groceries tomorrow"';
        }

        // Parse due date
        DateTime? dueDate;
        TaskPriority priority = TaskPriority.medium;

        if (lowerMessage.contains('tomorrow')) {
          dueDate = DateTime.now().add(const Duration(days: 1));
          taskTitle = taskTitle.replaceAll(RegExp(r'\s*tomorrow\s*', caseSensitive: false), '').trim();
        } else if (lowerMessage.contains('today')) {
          dueDate = DateTime.now();
          taskTitle = taskTitle.replaceAll(RegExp(r'\s*today\s*', caseSensitive: false), '').trim();
        } else if (lowerMessage.contains('next week')) {
          dueDate = DateTime.now().add(const Duration(days: 7));
          taskTitle = taskTitle.replaceAll(RegExp(r'\s*next week\s*', caseSensitive: false), '').trim();
        }

        // Parse priority
        if (lowerMessage.contains('urgent') || lowerMessage.contains('important')) {
          priority = TaskPriority.urgent;
          taskTitle = taskTitle
              .replaceAll(RegExp(r'\s*(urgent|important)\s*', caseSensitive: false), '')
              .trim();
        } else if (lowerMessage.contains('high priority')) {
          priority = TaskPriority.high;
          taskTitle = taskTitle.replaceAll(RegExp(r'\s*high priority\s*', caseSensitive: false), '').trim();
        }

        // Create the task
        final task = await TasksRemindersService.instance.createTask(
          title: taskTitle,
          dueDate: dueDate,
          priority: priority,
        );

        String response = '✅ Task created: "${task.title}"';
        if (task.dueDate != null) {
          if (task.isDueToday) {
            response += '\n📅 Due: Today';
          } else if (task.isDueTomorrow) {
            response += '\n📅 Due: Tomorrow';
          } else {
            response += '\n📅 Due: ${_formatDate(task.dueDate!)}';
          }
        }
        return response;
      }

      // Complete task
      if (lowerMessage.contains('complete') || lowerMessage.contains('done') || lowerMessage.contains('finish')) {
        return 'To complete a task, please say: "Complete task [task name]" or use the app interface.';
      }

      // Default: Show task summary
      return await TasksRemindersService.instance.getTaskSummary();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling tasks request', e, stackTrace);
      return 'Unable to process task request. Try: "Show my tasks" or "Add task buy groceries"';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return 'in $diff days';
    if (diff < -1 && diff > -7) return '${-diff} days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  /// Handle music & playback control request
  Future<String> _handleMusicRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Pause music
      if (lowerMessage.contains('pause') || lowerMessage.contains('stop')) {
        return await MusicControlService.instance.pause();
      }

      // Resume/Next/Previous
      if (lowerMessage.contains('resume')) {
        return await MusicControlService.instance.resume();
      }
      if (lowerMessage.contains('next') || lowerMessage.contains('skip')) {
        return await MusicControlService.instance.next();
      }
      if (lowerMessage.contains('previous') || lowerMessage.contains('back')) {
        return await MusicControlService.instance.previous();
      }

      // Volume control
      if (lowerMessage.contains('volume')) {
        final volumePattern = RegExp(r'(\d+)\s*%?');
        final match = volumePattern.firstMatch(message);
        if (match != null) {
          final level = int.parse(match.group(1)!);
          return await MusicControlService.instance.setVolume(level);
        }
        return 'Please specify volume level, e.g., "Set volume to 70"';
      }

      // Shuffle/Repeat
      if (lowerMessage.contains('shuffle')) {
        return await MusicControlService.instance.toggleShuffle();
      }
      if (lowerMessage.contains('repeat')) {
        return await MusicControlService.instance.toggleRepeat();
      }

      // Play music (extract search query)
      if (lowerMessage.contains('play')) {
        var query = message
            .replaceAll(RegExp(r'play|on spotify|on apple music', caseSensitive: false), '')
            .trim();

        // Detect service preference
        String? service;
        if (lowerMessage.contains('spotify')) {
          service = 'spotify';
        } else if (lowerMessage.contains('apple music')) {
          service = 'apple_music';
        }

        if (query.isEmpty) {
          return 'What would you like to play? Try: "Play Bohemian Rhapsody" or "Play chill music"';
        }

        return await MusicControlService.instance.play(query: query, service: service);
      }

      // Default: show current playing
      return await MusicControlService.instance.getCurrentlyPlaying();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling music request', e, stackTrace);
      return 'Unable to control music. Try: "Play Bohemian Rhapsody" or "Pause music"';
    }
  }

  /// Handle travel & transportation request
  Future<String> _handleTravelRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Flight status
      if (lowerMessage.contains('flight')) {
        final flightPattern = RegExp(r'([A-Z]{2}\d{1,4})', caseSensitive: false);
        final match = flightPattern.firstMatch(message);

        if (match != null) {
          final flightNumber = match.group(1)!.toUpperCase();
          final flightInfo = await TravelTransportationService.instance.getFlightStatus(flightNumber);

          if (flightInfo != null) {
            return '✈️ Flight ${flightInfo.flightNumber} (${flightInfo.airline})\n\n'
                '🛫 Departure: ${flightInfo.departure ?? "N/A"}\n'
                '   ${flightInfo.departureTime != null ? _formatTime(flightInfo.departureTime!) : "Time TBD"}\n\n'
                '🛬 Arrival: ${flightInfo.arrival ?? "N/A"}\n'
                '   ${flightInfo.arrivalTime != null ? _formatTime(flightInfo.arrivalTime!) : "Time TBD"}\n\n'
                '📊 Status: ${flightInfo.status}';
          } else {
            return 'Flight information not found. Please check the flight number and try again.';
          }
        }

        return 'Please provide a flight number, e.g., "Check flight AA1234"';
      }

      // Directions
      if (lowerMessage.contains('direction') || lowerMessage.contains('how to get')) {
        final dirPattern = RegExp(r'from\s+(.+?)\s+to\s+(.+)', caseSensitive: false);
        var match = dirPattern.firstMatch(message);

        if (match != null) {
          final from = match.group(1)!.trim();
          final to = match.group(2)!.trim();

          // Detect transport mode
          TransportMode mode = TransportMode.driving;
          if (lowerMessage.contains('walk') || lowerMessage.contains('walking')) {
            mode = TransportMode.walking;
          } else if (lowerMessage.contains('bike') || lowerMessage.contains('cycling')) {
            mode = TransportMode.bicycling;
          } else if (lowerMessage.contains('transit') || lowerMessage.contains('bus') || lowerMessage.contains('train')) {
            mode = TransportMode.transit;
          }

          return await TravelTransportationService.instance.getDirections(
            from: from,
            to: to,
            mode: mode,
          );
        }

        // Alternative pattern: "to X"
        final toPattern = RegExp(r'to\s+(.+)', caseSensitive: false);
        match = toPattern.firstMatch(message);
        if (match != null) {
          final destination = match.group(1)!.trim();
          return await TravelTransportationService.instance.getDirections(
            from: 'current location',
            to: destination,
          );
        }

        return 'Please specify origin and destination, e.g., "Directions from Paris to London"';
      }

      // Travel recommendations
      if (lowerMessage.contains('recommend') || lowerMessage.contains('where to') || lowerMessage.contains('visit')) {
        final recommendations = await TravelTransportationService.instance.getTravelRecommendations();

        if (recommendations.isEmpty) {
          return 'No travel recommendations available at the moment.';
        }

        final buffer = StringBuffer('✈️ Travel Recommendations:\n\n');
        for (var i = 0; i < recommendations.length && i < 5; i++) {
          final rec = recommendations[i];
          buffer.writeln('${i + 1}. ${rec.destination}');
          buffer.writeln('   ${rec.description}');
          if (rec.bestTime != null) {
            buffer.writeln('   🗓️ Best time: ${rec.bestTime}');
          }
          if (rec.rating != null) {
            buffer.writeln('   ⭐ Rating: ${rec.rating}/5.0');
          }
          buffer.writeln();
        }
        return buffer.toString();
      }

      // Public transit
      if (lowerMessage.contains('transit') || lowerMessage.contains('bus') || lowerMessage.contains('train')) {
        final locationPattern = RegExp(r'in\s+(.+)', caseSensitive: false);
        final match = locationPattern.firstMatch(message);

        if (match != null) {
          final location = match.group(1)!.trim();
          return await TravelTransportationService.instance.getPublicTransit(location);
        }

        return await TravelTransportationService.instance.getPublicTransit('your city');
      }

      // Travel tips
      if (lowerMessage.contains('tip') || lowerMessage.contains('advice')) {
        String? destination;
        final destPattern = RegExp(r'for\s+(.+)', caseSensitive: false);
        final match = destPattern.firstMatch(message);
        if (match != null) {
          destination = match.group(1)!.trim();
        }

        return TravelTransportationService.instance.getTravelTips(destination);
      }

      // Nearby attractions
      final nearbyPattern = RegExp(r'(near|in|around)\s+(.+)', caseSensitive: false);
      final match = nearbyPattern.firstMatch(message);
      if (match != null) {
        final location = match.group(2)!.trim();
        return await TravelTransportationService.instance.getNearbyAttractions(location);
      }

      // Default: Travel recommendations
      return await TravelTransportationService.instance.getTravelTips();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling travel request', e, stackTrace);
      return 'Unable to fetch travel information. Try: "Flight AA1234" or "Directions to Paris"';
    }
  }

  /// Handle photo & gallery request
  Future<String> _handlePhotoRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Show gallery summary
      if (lowerMessage.contains('show') && (lowerMessage.contains('photo') || lowerMessage.contains('gallery'))) {
        if (lowerMessage.contains('favorite')) {
          final favorites = await PhotoGalleryService.instance.getFavoritePhotos();
          if (favorites.isEmpty) {
            return '⭐ You don\'t have any favorite photos yet. Mark photos as favorites to see them here!';
          }

          final buffer = StringBuffer('⭐ Favorite Photos (${favorites.length}):\n\n');
          for (var i = 0; i < favorites.length && i < 10; i++) {
            buffer.writeln('${i + 1}. ${favorites[i].name} (${favorites[i].formattedSize})');
          }
          return buffer.toString();
        }

        return await PhotoGalleryService.instance.getGallerySummary();
      }

      // Photos from time period
      if (lowerMessage.contains('today')) {
        final photos = await PhotoGalleryService.instance.getPhotosToday();
        if (photos.isEmpty) {
          return '📸 No photos taken today yet.';
        }

        final buffer = StringBuffer('📸 Photos from Today (${photos.length}):\n\n');
        for (var i = 0; i < photos.length && i < 10; i++) {
          buffer.writeln('${i + 1}. ${photos[i].name} (${_formatTime(photos[i].dateTime)})');
        }
        return buffer.toString();
      }

      if (lowerMessage.contains('this week')) {
        final photos = await PhotoGalleryService.instance.getPhotosThisWeek();
        if (photos.isEmpty) {
          return '📸 No photos from this week.';
        }

        final buffer = StringBuffer('📸 Photos from This Week (${photos.length}):\n\n');
        for (var i = 0; i < photos.length && i < 10; i++) {
          buffer.writeln('${i + 1}. ${photos[i].name}');
        }
        return buffer.toString();
      }

      if (lowerMessage.contains('this month')) {
        final photos = await PhotoGalleryService.instance.getPhotosThisMonth();
        if (photos.isEmpty) {
          return '📸 No photos from this month.';
        }

        final buffer = StringBuffer('📸 Photos from This Month (${photos.length}):\n\n');
        for (var i = 0; i < photos.length && i < 10; i++) {
          buffer.writeln('${i + 1}. ${photos[i].name}');
        }
        return buffer.toString();
      }

      // Show albums
      if (lowerMessage.contains('show') && lowerMessage.contains('album')) {
        final albums = await PhotoGalleryService.instance.getAllAlbums();
        if (albums.isEmpty) {
          return '📁 You don\'t have any albums yet. Create one by saying "Create album [name]"';
        }

        final buffer = StringBuffer('📁 Your Albums (${albums.length}):\n\n');
        for (var i = 0; i < albums.length; i++) {
          final album = albums[i];
          final photoCount = (await PhotoGalleryService.instance.getPhotosByAlbum(album.id)).length;
          buffer.writeln('${i + 1}. ${album.name} ($photoCount photos)');
          if (album.description != null && album.description!.isNotEmpty) {
            buffer.writeln('   ${album.description}');
          }
          buffer.writeln();
        }
        return buffer.toString();
      }

      // Create album
      if (lowerMessage.contains('create') && lowerMessage.contains('album')) {
        var albumName = message
            .replaceAll(RegExp(r'create\s+album', caseSensitive: false), '')
            .trim();

        if (albumName.isEmpty) {
          return 'Please provide an album name, e.g., "Create album Summer 2024"';
        }

        final album = await PhotoGalleryService.instance.createAlbum(name: albumName);
        return '✅ Album "${album.name}" created successfully!';
      }

      // Photos in album
      if (lowerMessage.contains('in') && lowerMessage.contains('album')) {
        final albumPattern = RegExp(r'in\s+album\s+(.+)', caseSensitive: false);
        final match = albumPattern.firstMatch(message);

        if (match != null) {
          final albumName = match.group(1)!.trim();
          final albums = await PhotoGalleryService.instance.getAllAlbums();
          final album = albums.where((a) => a.name.toLowerCase().contains(albumName.toLowerCase())).firstOrNull;

          if (album == null) {
            return 'Album "$albumName" not found. Say "Show albums" to see all albums.';
          }

          final photos = await PhotoGalleryService.instance.getPhotosByAlbum(album.id);
          if (photos.isEmpty) {
            return '📁 Album "${album.name}" is empty. Add photos to this album!';
          }

          final buffer = StringBuffer('📁 ${album.name} (${photos.length} photos):\n\n');
          for (var i = 0; i < photos.length && i < 10; i++) {
            buffer.writeln('${i + 1}. ${photos[i].name} (${photos[i].formattedSize})');
          }
          return buffer.toString();
        }
      }

      // Search by tag
      if (lowerMessage.contains('tag') || lowerMessage.contains('tagged')) {
        final tagPattern = RegExp(r'tag(?:ged)?\s+(?:with\s+)?(.+)', caseSensitive: false);
        final match = tagPattern.firstMatch(message);

        if (match != null) {
          final tagQuery = match.group(1)!.trim();
          final photos = await PhotoGalleryService.instance.searchPhotosByTags([tagQuery]);

          if (photos.isEmpty) {
            return '🔍 No photos found with tag "$tagQuery"';
          }

          final buffer = StringBuffer('🏷️ Photos tagged "$tagQuery" (${photos.length}):\n\n');
          for (var i = 0; i < photos.length && i < 10; i++) {
            buffer.writeln('${i + 1}. ${photos[i].name}');
          }
          return buffer.toString();
        }
      }

      // Search by location
      if (lowerMessage.contains('in') && !lowerMessage.contains('album')) {
        final locationPattern = RegExp(r'in\s+(.+)', caseSensitive: false);
        final match = locationPattern.firstMatch(message);

        if (match != null) {
          final location = match.group(1)!.trim();
          final photos = await PhotoGalleryService.instance.searchPhotosByLocation(location);

          if (photos.isEmpty) {
            return '🔍 No photos found in "$location"';
          }

          final buffer = StringBuffer('📍 Photos in $location (${photos.length}):\n\n');
          for (var i = 0; i < photos.length && i < 10; i++) {
            buffer.writeln('${i + 1}. ${photos[i].name}');
          }
          return buffer.toString();
        }
      }

      // Default: Show gallery summary
      return await PhotoGalleryService.instance.getGallerySummary();
    } catch (e, stackTrace) {
      AppLogger.error('Error handling photo request', e, stackTrace);
      return 'Unable to access photo gallery. Try: "Show my photos" or "Show albums"';
    }
  }

  /// Handle cocktail request
  Future<String> _handleCocktailRequest(String message) async {
    try {
      final lowerMessage = message.toLowerCase();

      // Extract cocktail name if specified
      String? cocktailName;

      if (lowerMessage.contains('how to make')) {
        cocktailName = message
            .replaceAll(RegExp(r'how to make (a |the )?', caseSensitive: false), '')
            .trim();
      } else if (lowerMessage.contains('cocktail')) {
        // Check if specific cocktail mentioned
        final commonCocktails = [
          'margarita',
          'martini',
          'mojito',
          'cosmopolitan',
          'old fashioned',
          'manhattan',
          'daiquiri',
          'bloody mary',
          'whiskey sour',
          'mai tai'
        ];

        for (final name in commonCocktails) {
          if (lowerMessage.contains(name)) {
            cocktailName = name;
            break;
          }
        }
      }

      return await CocktailsService.instance.getCocktailSummary(cocktailName);
    } catch (e, stackTrace) {
      AppLogger.error('Error handling cocktail request', e, stackTrace);
      return 'Unable to fetch cocktail recipe. Try: "How to make a Margarita" or "Random cocktail"';
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

😴 SLEEP & WELLNESS (NEW!)
  • Smart alarm with optimal wake time
  • Sleep quality analysis
  • Wellness coaching & tips
  • Bedtime routine suggestions

🔢 CALCULATOR & CONVERTER (NEW!)
  • Mathematical calculations
  • Unit conversions (length, weight, temp, etc.)
  • Scientific functions (sqrt, sin, cos, etc.)
  • Convert between 50+ units

🌐 TRANSLATION (NEW!)
  • Translate between 50+ languages
  • Automatic language detection
  • No API key required!
  • Popular languages: EN, ES, FR, DE, JA, KO, ZH, AR

✅ TASKS & REMINDERS (NEW!)
  • Create and manage tasks
  • Set due dates and priorities
  • Recurring tasks support
  • Overdue task tracking
  • Task lists and categories
  • Google Tasks sync

🎵 MUSIC & PLAYBACK CONTROL (NEW!)
  • Play music on Spotify or Apple Music
  • Pause, resume, skip tracks
  • Volume control
  • Shuffle and repeat modes
  • Search for songs, artists, albums
  • Playlist management

✈️ TRAVEL & TRANSPORTATION (NEW!)
  • Flight status tracking
  • Directions and navigation
  • Travel recommendations
  • Public transit information
  • Nearby attractions
  • Travel tips and advice

📸 PHOTO & GALLERY MANAGEMENT (NEW!)
  • Organize photos in albums
  • Search by tags, location, date
  • Mark favorites
  • View photos by time period
  • Create and manage albums
  • Photo metadata and details

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

🐱 CAT FACTS (NEW!)
  • Fun and interesting cat facts
  • Learn about feline friends
  • FREE - No API key needed

👨 DAD JOKES (NEW!)
  • Family-friendly dad jokes
  • Wholesome humor
  • FREE - No API key needed

🌌 ASTRONOMY (NEW!)
  • NASA's Picture of the Day
  • Space exploration
  • Daily astronomy content
  • FREE - NASA APOD API

🍹 COCKTAILS & DRINKS (NEW!)
  • 600+ cocktail recipes
  • Alcoholic & non-alcoholic
  • Ingredients and instructions
  • FREE - TheCocktailDB API

👤 RANDOM USER GENERATOR (NEW!)
  • Generate realistic user profiles
  • Testing and demo data
  • Multiple countries supported
  • FREE - RandomUser.me API

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

🌟 36 Services & 33+ FREE APIs integrated for the ultimate experience!
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
