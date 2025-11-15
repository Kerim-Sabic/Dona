import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/voice_button.dart';
import '../../widgets/quick_action_card.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.howCanIHelp,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
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

  Widget _buildRecentConversations() {
    // Placeholder for recent conversations
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No recent conversations',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a conversation with Dona',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
