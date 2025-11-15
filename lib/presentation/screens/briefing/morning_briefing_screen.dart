import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme/glassmorphism_theme.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../services/weather/weather_service.dart';
import '../../../services/news/news_service.dart';
import '../../../services/google_tasks/google_tasks_service.dart';
import '../../../data/models/calendar_event.dart';
import '../../../data/models/weather_data.dart';
import '../../../data/models/news_article.dart';
import '../../../services/ai/ai_service.dart';

class MorningBriefingScreen extends StatefulWidget {
  const MorningBriefingScreen({Key? key}) : super(key: key);

  @override
  State<MorningBriefingScreen> createState() => _MorningBriefingScreenState();
}

class _MorningBriefingScreenState extends State<MorningBriefingScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _greeting = '';
  WeatherData? _weather;
  List<CalendarEvent> _todayEvents = [];
  List<NewsArticle> _newsHeadlines = [];
  List<GoogleTask> _todayTasks = [];
  String? _aiInsight;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadBriefing();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBriefing() async {
    setState(() => _isLoading = true);

    // Load all data in parallel
    await Future.wait([
      _loadGreeting(),
      _loadWeather(),
      _loadCalendar(),
      _loadNews(),
      _loadTasks(),
    ]);

    // Generate AI insight
    await _generateAIInsight();

    setState(() => _isLoading = false);
    _animationController.forward();
  }

  Future<void> _loadGreeting() async {
    final hour = DateTime.now().hour;
    final userName = 'there'; // Get from UserProfile

    if (hour < 12) {
      _greeting = 'Good morning, $userName';
    } else if (hour < 17) {
      _greeting = 'Good afternoon, $userName';
    } else {
      _greeting = 'Good evening, $userName';
    }
  }

  Future<void> _loadWeather() async {
    try {
      _weather = await WeatherService.instance.getCurrentWeather();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadCalendar() async {
    try {
      final events = await CalendarService.instance.getUpcomingEvents(maxResults: 10);
      _todayEvents = events.where((e) => _isToday(e.startTime)).toList();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadNews() async {
    try {
      _newsHeadlines = await NewsService.instance.getTopHeadlines(limit: 5);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadTasks() async {
    try {
      final taskLists = await GoogleTasksService.instance.getTaskLists();
      if (taskLists.isNotEmpty) {
        final tasks = await GoogleTasksService.instance.getTasks(taskLists.first.id);
        _todayTasks = tasks.where((t) {
          if (t.due == null) return false;
          return _isToday(t.due!);
        }).toList();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _generateAIInsight() async {
    try {
      final prompt = '''
Generate a brief, encouraging insight for the user's day.

Context:
- ${_todayEvents.length} meetings today
- Weather: ${_weather?.description ?? 'unknown'}
- ${_todayTasks.length} tasks due today

Generate a single sentence that:
1. Is warm and encouraging
2. Highlights something specific about their day
3. Sounds like Donna Paulsen from Suits

Example: "You have a packed day ahead, but you've handled busier schedules—let's make it count!"
''';

      _aiInsight = await AIService.instance.chat(prompt);
    } catch (e) {
      _aiInsight = 'Ready to make today amazing? Let\'s do this!';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildBriefingContent(),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulseAnimation(
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 80,
              color: GlassmorphismTheme.accentOrange,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Preparing your briefing...',
            style: GlassmorphismTheme.title2,
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingContent() {
    return RefreshIndicator(
      onRefresh: _loadBriefing,
      backgroundColor: GlassmorphismTheme.glassWhite,
      color: GlassmorphismTheme.primaryBlue,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(GlassmorphismTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    _greeting,
                    style: GlassmorphismTheme.heroTitle,
                  ),
                  const SizedBox(height: GlassmorphismTheme.spacingS),

                  // Date
                  Text(
                    _formatDate(DateTime.now()),
                    style: GlassmorphismTheme.callout,
                  ),

                  const SizedBox(height: GlassmorphismTheme.spacingL),

                  // AI Insight
                  if (_aiInsight != null)
                    GlassContainer(
                      gradient: GlassmorphismTheme.primaryGradient,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: GlassmorphismTheme.spacingM),
                          Expanded(
                            child: Text(
                              _aiInsight!,
                              style: GlassmorphismTheme.body.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Weather Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlassmorphismTheme.spacingL,
              ),
              child: _buildWeatherCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingL),
          ),

          // Today's Schedule
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlassmorphismTheme.spacingL,
              ),
              child: _buildScheduleSection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingL),
          ),

          // Tasks
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlassmorphismTheme.spacingL,
              ),
              child: _buildTasksSection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingL),
          ),

          // News Headlines
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlassmorphismTheme.spacingL,
              ),
              child: _buildNewsSection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingXXL),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weather == null) {
      return const ShimmerLoading(width: double.infinity, height: 120);
    }

    return GlassContainer(
      gradient: _getWeatherGradient(_weather!.description),
      boxShadow: GlassmorphismTheme.mediumShadow,
      child: Row(
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWeatherIcon(_weather!.description),
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: GlassmorphismTheme.spacingL),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weather!.temperature.toInt()}°C',
                  style: GlassmorphismTheme.heroTitle.copyWith(fontSize: 48),
                ),
                Text(
                  _weather!.description,
                  style: GlassmorphismTheme.title3,
                ),
                const SizedBox(height: GlassmorphismTheme.spacingS),
                Text(
                  _weather!.cityName,
                  style: GlassmorphismTheme.callout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: GlassmorphismTheme.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: GlassmorphismTheme.spacingS),
            Text(
              'Today\'s Schedule',
              style: GlassmorphismTheme.title2,
            ),
            const Spacer(),
            Text(
              '${_todayEvents.length} events',
              style: GlassmorphismTheme.callout,
            ),
          ],
        ),

        const SizedBox(height: GlassmorphismTheme.spacingM),

        if (_todayEvents.isEmpty)
          GlassContainer(
            child: Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: GlassmorphismTheme.accentGreen,
                ),
                const SizedBox(width: GlassmorphismTheme.spacingM),
                Expanded(
                  child: Text(
                    'No events scheduled. Enjoy your free day!',
                    style: GlassmorphismTheme.body,
                  ),
                ),
              ],
            ),
          )
        else
          ..._todayEvents.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: GlassmorphismTheme.spacingM),
                child: _buildEventCard(event),
              )),
      ],
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return GlassContainer(
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              gradient: GlassmorphismTheme.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: GlassmorphismTheme.spacingM),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GlassmorphismTheme.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: GlassmorphismTheme.spacingXS),
                Text(
                  _formatEventTime(event),
                  style: GlassmorphismTheme.subheadline,
                ),
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: GlassmorphismTheme.spacingXS),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: GlassmorphismTheme.accentOrange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: GlassmorphismTheme.caption1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: GlassmorphismTheme.accentGreen,
              size: 24,
            ),
            const SizedBox(width: GlassmorphismTheme.spacingS),
            Text(
              'Tasks Due Today',
              style: GlassmorphismTheme.title2,
            ),
            const Spacer(),
            Text(
              '${_todayTasks.length} tasks',
              style: GlassmorphismTheme.callout,
            ),
          ],
        ),

        const SizedBox(height: GlassmorphismTheme.spacingM),

        if (_todayTasks.isEmpty)
          GlassContainer(
            child: Row(
              children: [
                const Icon(
                  Icons.celebration_outlined,
                  color: GlassmorphismTheme.accentGreen,
                ),
                const SizedBox(width: GlassmorphismTheme.spacingM),
                Expanded(
                  child: Text(
                    'All caught up! No tasks due today.',
                    style: GlassmorphismTheme.body,
                  ),
                ),
              ],
            ),
          )
        else
          ..._todayTasks.take(5).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: GlassmorphismTheme.spacingS),
                child: _buildTaskCard(task),
              )),
      ],
    );
  }

  Widget _buildTaskCard(GoogleTask task) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: GlassmorphismTheme.spacingM,
        vertical: GlassmorphismTheme.spacingM,
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: GlassmorphismTheme.primaryBlue,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: GlassmorphismTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GlassmorphismTheme.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.notes != null && task.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      task.notes!,
                      style: GlassmorphismTheme.caption1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.newspaper,
              color: GlassmorphismTheme.accentOrange,
              size: 24,
            ),
            const SizedBox(width: GlassmorphismTheme.spacingS),
            Text(
              'Top Headlines',
              style: GlassmorphismTheme.title2,
            ),
          ],
        ),

        const SizedBox(height: GlassmorphismTheme.spacingM),

        if (_newsHeadlines.isEmpty)
          const ShimmerLoading(width: double.infinity, height: 100)
        else
          ..._newsHeadlines.take(3).map((article) => Padding(
                padding: const EdgeInsets.only(bottom: GlassmorphismTheme.spacingM),
                child: _buildNewsCard(article),
              )),
      ],
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: GlassmorphismTheme.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (article.description != null) ...[
            const SizedBox(height: GlassmorphismTheme.spacingS),
            Text(
              article.description!,
              style: GlassmorphismTheme.subheadline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: GlassmorphismTheme.spacingS),
          Row(
            children: [
              Text(
                article.source,
                style: GlassmorphismTheme.caption1.copyWith(
                  color: GlassmorphismTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                _formatNewsTime(article.publishedAt),
                style: GlassmorphismTheme.caption1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
    return '$weekday, $month ${date.day}';
  }

  String _formatEventTime(CalendarEvent event) {
    final start = event.startTime;
    final end = event.endTime;
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatNewsTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Gradient _getWeatherGradient(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('rain')) {
      return const LinearGradient(
        colors: [Color(0xFF4A90E2), Color(0xFF5E72E4)],
      );
    } else if (lower.contains('cloud')) {
      return const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      );
    } else if (lower.contains('clear') || lower.contains('sun')) {
      return const LinearGradient(
        colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
      );
    }
    return GlassmorphismTheme.primaryGradient;
  }

  IconData _getWeatherIcon(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('rain')) return Icons.water_drop;
    if (lower.contains('cloud')) return Icons.cloud;
    if (lower.contains('clear') || lower.contains('sun')) return Icons.wb_sunny;
    if (lower.contains('snow')) return Icons.ac_unit;
    return Icons.wb_cloudy;
  }
}
