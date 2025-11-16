import 'package:flutter/material.dart';
import '../../../core/theme/glassmorphism_theme.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../assistant/context/context_models.dart';
import '../../../assistant/assistant_brain.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/autopilot/autopilots/plan_my_day_autopilot.dart';
import '../../../domain/autopilot/autopilots/study_autopilot.dart';
import '../../../domain/autopilot/autopilots/weekly_review_autopilot.dart';
import '../../../domain/autopilot/autopilots/focus_mode_autopilot.dart';
import '../../../domain/autopilot/autopilots/triage_autopilot.dart';
import '../../../domain/autopilot/autopilots/relationship_autopilot.dart';
import '../../../domain/autopilot/autopilot_models.dart';
import '../../../core/config/feature_tiers.dart';
import '../../../assistant/ai_router/ai_router.dart';
import '../../widgets/upgrade/upgrade_dialog.dart';

/// Command Center - The main hub for Dona's intelligent assistance
/// Shows context-aware recommendations, priorities, and autopilot actions
class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({Key? key}) : super(key: key);

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  LifeContext? _context;
  List<PriorityItem> _priorities = [];
  List<Suggestion> _recommendations = [];

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

    _loadCommandCenter();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCommandCenter() async {
    setState(() => _isLoading = true);

    try {
      // Load context and priorities in parallel
      final results = await Future.wait([
        ContextEngine.instance.getTodayContext(),
        ContextEngine.instance.getTopPriorities(limit: 5),
      ]);

      _context = results[0] as LifeContext;
      _priorities = results[1] as List<PriorityItem>;

      // Generate AI recommendations based on context
      await _generateRecommendations();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load Command Center', e, stackTrace);
    }

    setState(() => _isLoading = false);
    _animationController.forward();
  }

  Future<void> _generateRecommendations() async {
    try {
      if (_context == null) return;

      // Use AssistantBrain to generate contextual suggestions
      final conversationContext = ConversationContext(
        summary: _context!.toBriefSummary(),
        timeOfDay: _context!.timeContext.timeOfDay,
        location: _context!.environmentContext.currentLocation,
      );

      _recommendations = await AssistantBrain.instance.generateSuggestions(
        context: conversationContext,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate recommendations', e, stackTrace);
      _recommendations = [];
    }
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
                  child: _buildCommandCenterContent(),
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
              Icons.dashboard_customize,
              size: 80,
              color: GlassmorphismTheme.primaryBlue,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading your Command Center...',
            style: GlassmorphismTheme.title2,
          ),
        ],
      ),
    );
  }

  Widget _buildCommandCenterContent() {
    if (_context == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadCommandCenter,
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
                  // Title
                  Row(
                    children: [
                      const Icon(
                        Icons.dashboard_customize,
                        color: GlassmorphismTheme.primaryBlue,
                        size: 32,
                      ),
                      const SizedBox(width: GlassmorphismTheme.spacingM),
                      Text(
                        'Command Center',
                        style: GlassmorphismTheme.heroTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: GlassmorphismTheme.spacingS),

                  // Context summary
                  Text(
                    _getContextGreeting(),
                    style: GlassmorphismTheme.callout,
                  ),
                ],
              ),
            ),
          ),

          // Stress indicator (if high)
          if (_context!.stressLevel > 0.6)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GlassmorphismTheme.spacingL,
                ),
                child: _buildStressWarning(),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingL),
          ),

          // Dona Recommends Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlassmorphismTheme.spacingL,
              ),
              child: _buildDonaRecommendsSection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingL),
          ),

          // Top Priorities
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlassmorphismTheme.spacingL,
              ),
              child: _buildPrioritiesSection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingL),
          ),

          // Quick Actions (Autopilot triggers)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlassmorphismTheme.spacingL,
              ),
              child: _buildQuickActionsSection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GlassmorphismTheme.spacingXXL),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: GlassmorphismTheme.errorRed,
          ),
          const SizedBox(height: 24),
          const Text(
            'Failed to load Command Center',
            style: GlassmorphismTheme.title2,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCommandCenter,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStressWarning() {
    return GlassContainer(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: GlassmorphismTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'High Stress Detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _context!.shouldTakeBreak
                      ? 'Your schedule is packed. Consider taking a break.'
                      : 'You have a lot on your plate. Stay focused!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonaRecommendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: GlassmorphismTheme.accentOrange,
              size: 24,
            ),
            const SizedBox(width: GlassmorphismTheme.spacingS),
            Text(
              'Dona Recommends',
              style: GlassmorphismTheme.title2,
            ),
          ],
        ),

        const SizedBox(height: GlassmorphismTheme.spacingM),

        if (_recommendations.isEmpty)
          GlassContainer(
            child: const Text(
              'No recommendations at the moment. You\'re all set!',
              style: GlassmorphismTheme.body,
            ),
          )
        else
          ..._recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: GlassmorphismTheme.spacingM),
                child: _buildRecommendationCard(rec),
              )),
      ],
    );
  }

  Widget _buildRecommendationCard(Suggestion recommendation) {
    return GlassContainer(
      gradient: recommendation.priority == SuggestionPriority.high
          ? GlassmorphismTheme.primaryGradient
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (recommendation.priority == SuggestionPriority.high)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HIGH PRIORITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GlassmorphismTheme.spacingS),
          Text(
            recommendation.text,
            style: recommendation.priority == SuggestionPriority.high
                ? GlassmorphismTheme.headline.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )
                : GlassmorphismTheme.headline,
          ),
          const SizedBox(height: GlassmorphismTheme.spacingS),
          Text(
            recommendation.reason,
            style: recommendation.priority == SuggestionPriority.high
                ? GlassmorphismTheme.subheadline.copyWith(color: Colors.white70)
                : GlassmorphismTheme.subheadline,
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flag,
              color: GlassmorphismTheme.errorRed,
              size: 24,
            ),
            const SizedBox(width: GlassmorphismTheme.spacingS),
            Text(
              'Top Priorities',
              style: GlassmorphismTheme.title2,
            ),
            const Spacer(),
            Text(
              '${_priorities.length} items',
              style: GlassmorphismTheme.callout,
            ),
          ],
        ),

        const SizedBox(height: GlassmorphismTheme.spacingM),

        if (_priorities.isEmpty)
          GlassContainer(
            child: Row(
              children: [
                const Icon(
                  Icons.celebration,
                  color: GlassmorphismTheme.accentGreen,
                ),
                const SizedBox(width: GlassmorphismTheme.spacingM),
                const Expanded(
                  child: Text(
                    'All clear! No urgent priorities right now.',
                    style: GlassmorphismTheme.body,
                  ),
                ),
              ],
            ),
          )
        else
          ..._priorities.asMap().entries.map((entry) {
            final index = entry.key;
            final priority = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: GlassmorphismTheme.spacingM),
              child: _buildPriorityCard(priority, index + 1),
            );
          }),
      ],
    );
  }

  Widget _buildPriorityCard(PriorityItem priority, int rank) {
    final priorityColor = _getPriorityColor(priority.priority);

    return GlassContainer(
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [priorityColor, priorityColor.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: GlassmorphismTheme.spacingM),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priority.title,
                  style: GlassmorphismTheme.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getTypeIcon(priority.type),
                      size: 14,
                      color: GlassmorphismTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(priority.dueDate),
                      style: GlassmorphismTheme.caption1,
                    ),
                  ],
                ),
                if (priority.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    priority.description!,
                    style: GlassmorphismTheme.caption1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flash_on,
              color: GlassmorphismTheme.accentYellow,
              size: 24,
            ),
            const SizedBox(width: GlassmorphismTheme.spacingS),
            Text(
              'Quick Actions',
              style: GlassmorphismTheme.title2,
            ),
          ],
        ),

        const SizedBox(height: GlassmorphismTheme.spacingM),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: GlassmorphismTheme.spacingM,
          crossAxisSpacing: GlassmorphismTheme.spacingM,
          childAspectRatio: 1.5,
          children: [
            // Free autopilots
            _buildQuickActionCard(
              icon: Icons.calendar_view_day,
              title: 'Plan My Day',
              gradient: GlassmorphismTheme.primaryGradient,
              onTap: () => _triggerPlanMyDayAutopilot(),
            ),
            _buildQuickActionCard(
              icon: Icons.school,
              title: 'Study Session',
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              onTap: () => _triggerStudyAutopilot(),
            ),

            // Premium autopilots
            _buildQuickActionCard(
              icon: Icons.calendar_month,
              title: 'Weekly Review',
              gradient: const LinearGradient(
                colors: [Color(0xFFf857a6), Color(0xFFff5858)],
              ),
              isPremium: true,
              onTap: () => _triggerWeeklyReviewAutopilot(),
            ),
            _buildQuickActionCard(
              icon: Icons.psychology,
              title: 'Focus Mode',
              gradient: const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              ),
              isPremium: true,
              onTap: () => _triggerFocusModeAutopilot(),
            ),
            _buildQuickActionCard(
              icon: Icons.inbox,
              title: 'Triage',
              gradient: const LinearGradient(
                colors: [Color(0xFFfa709a), Color(0xFFfee140)],
              ),
              isPremium: true,
              onTap: () => _triggerTriageAutopilot(),
            ),
            _buildQuickActionCard(
              icon: Icons.favorite,
              title: 'Relationships',
              gradient: const LinearGradient(
                colors: [Color(0xFFd66d75), Color(0xFFe29587)],
              ),
              isPremium: true,
              onTap: () => _triggerRelationshipAutopilot(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(GlassmorphismTheme.borderRadiusL),
          boxShadow: GlassmorphismTheme.mediumShadow,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(GlassmorphismTheme.spacingM),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: GlassmorphismTheme.spacingS),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getContextGreeting() {
    final timeOfDay = _context?.timeContext.timeOfDay ?? 'day';
    final userName = _context?.userSnapshot.profile.name;

    final greeting = timeOfDay == 'morning'
        ? 'Good morning'
        : timeOfDay == 'afternoon'
            ? 'Good afternoon'
            : timeOfDay == 'evening'
                ? 'Good evening'
                : 'Good night';

    if (userName != null) {
      return '$greeting, $userName! Here\'s what matters today.';
    }
    return '$greeting! Here\'s what matters today.';
  }

  Color _getPriorityColor(double priority) {
    if (priority >= 0.8) {
      return GlassmorphismTheme.errorRed;
    } else if (priority >= 0.6) {
      return GlassmorphismTheme.accentOrange;
    } else {
      return GlassmorphismTheme.primaryBlue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'exam':
        return Icons.school;
      case 'assignment':
        return Icons.assignment;
      case 'task':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now);

    if (diff.isNegative) {
      return 'Overdue';
    } else if (diff.inHours < 1) {
      return 'In ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'In ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays < 7) {
      return 'In ${diff.inDays} days';
    } else {
      return '${dueDate.month}/${dueDate.day}';
    }
  }

  /// Trigger Plan My Day autopilot
  Future<void> _triggerPlanMyDayAutopilot() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate plan
      final plan = await PlanMyDayAutopilot.instance.generatePlan();

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show plan preview (approval screen)
      if (mounted) {
        _showAutopilotPreview(plan);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to trigger Plan My Day autopilot', e, stackTrace);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate plan. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Trigger Study Autopilot
  Future<void> _triggerStudyAutopilot() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate plan
      final plan = await StudyAutopilot.instance.generatePlan();

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show plan preview (approval screen)
      if (mounted) {
        _showAutopilotPreview(plan);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to trigger Study autopilot', e, stackTrace);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate study plan. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show autopilot plan preview (approval dialog)
  void _showAutopilotPreview(AutopilotPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: GlassmorphismTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(plan.planName)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...plan.actions.map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${action.stepNumber}. ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(action.description),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _executeAutopilot(plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassmorphismTheme.primaryBlue,
            ),
            child: const Text('Execute Plan'),
          ),
        ],
      ),
    );
  }

  /// Execute the autopilot plan
  Future<void> _executeAutopilot(AutopilotPlan plan) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Executing ${plan.planName}...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Execute plan (this will be replaced with actual execution later)
      final result = await PlanMyDayAutopilot.instance.simulate(plan);

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.summary),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh context
        _loadCommandCenter();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to execute autopilot', e, stackTrace);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Execution failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Trigger Weekly Review Autopilot (Premium)
  Future<void> _triggerWeeklyReviewAutopilot() async {
    // Check feature availability
    final currentMode = AiRouter.instance.currentMode;
    if (!FeatureTiers.isFeatureAvailable('weekly_review', currentMode)) {
      await UpgradeDialog.showFeatureLocked(context, 'weekly_review');
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate plan
      final plan = await WeeklyReviewAutopilot.instance.generatePlan();

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show plan preview
      if (mounted) {
        _showAutopilotPreview(plan);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to trigger Weekly Review autopilot', e, stackTrace);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate weekly review. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Trigger Focus Mode Autopilot (Premium)
  Future<void> _triggerFocusModeAutopilot() async {
    // Check feature availability
    final currentMode = AiRouter.instance.currentMode;
    if (!FeatureTiers.isFeatureAvailable('focus_mode', currentMode)) {
      await UpgradeDialog.showFeatureLocked(context, 'focus_mode');
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate plan
      final plan = await FocusModeAutopilot.instance.generatePlan();

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show plan preview
      if (mounted) {
        _showAutopilotPreview(plan);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to trigger Focus Mode autopilot', e, stackTrace);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate focus plan. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Trigger Triage Autopilot (Premium)
  Future<void> _triggerTriageAutopilot() async {
    // Check feature availability
    final currentMode = AiRouter.instance.currentMode;
    if (!FeatureTiers.isFeatureAvailable('triage', currentMode)) {
      await UpgradeDialog.showFeatureLocked(context, 'triage');
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate plan
      final plan = await TriageAutopilot.instance.generatePlan();

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show plan preview
      if (mounted) {
        _showAutopilotPreview(plan);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to trigger Triage autopilot', e, stackTrace);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate triage plan. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Trigger Relationship Autopilot (Premium)
  Future<void> _triggerRelationshipAutopilot() async {
    // Check feature availability
    final currentMode = AiRouter.instance.currentMode;
    if (!FeatureTiers.isFeatureAvailable('relationship', currentMode)) {
      await UpgradeDialog.showFeatureLocked(context, 'relationship');
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate plan
      final plan = await RelationshipAutopilot.instance.generatePlan();

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show plan preview
      if (mounted) {
        _showAutopilotPreview(plan);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to trigger Relationship autopilot', e, stackTrace);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate relationship plan. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature autopilot coming soon!'),
        backgroundColor: GlassmorphismTheme.primaryBlue,
      ),
    );
  }
}
