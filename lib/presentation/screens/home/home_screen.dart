import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/voice_button.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/glassmorphic_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppStrings.goodMorning;
    } else if (hour < 17) {
      return AppStrings.goodAfternoon;
    } else {
      return AppStrings.goodEvening;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F6FA),
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.secondary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.psychology,
                color: isDark ? AppColors.secondary : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(AppStrings.appName),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Glassmorphic Header Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.primary.withOpacity(0.3),
                                AppColors.secondary.withOpacity(0.2),
                              ]
                            : [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.secondary.withOpacity(0.15),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getGreetingIcon(),
                                color: AppColors.accentYellow,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: isDark ? Colors.white : AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.howCanIHelp,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.7)
                                              : AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        QuickActionCard(
                          icon: Icons.newspaper,
                          title: AppStrings.news,
                          color: AppColors.info,
                          onTap: () {
                            Navigator.pushNamed(context, '/news');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.wb_sunny,
                          title: AppStrings.weather,
                          color: AppColors.accentYellow,
                          onTap: () {
                            Navigator.pushNamed(context, '/weather');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.calendar_today,
                          title: AppStrings.calendar,
                          color: AppColors.secondary,
                          onTap: () {
                            Navigator.pushNamed(context, '/calendar');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.restaurant,
                          title: AppStrings.foodOrdering,
                          color: AppColors.accent,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Food ordering coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Conversations
                    Text(
                      'Recent Conversations',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildRecentConversations(),
                  ],
                ),
              ),
            ),

            // Voice Button at Bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: VoiceButton(
                onTap: () {
                  Navigator.pushNamed(context, '/chat');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny;
    } else if (hour < 17) {
      return Icons.wb_twilight;
    } else {
      return Icons.nightlight_round;
    }
  }

  Widget _buildRecentConversations() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Placeholder for recent conversations
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: isDark ? AppColors.info.withOpacity(0.8) : AppColors.info,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent conversations',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withOpacity(0.9) : AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with Dona',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
