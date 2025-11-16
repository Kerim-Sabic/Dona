import 'package:flutter/material.dart';
import '../../../core/config/feature_tiers.dart';
import '../../../assistant/ai_router/ai_models.dart';
import '../../../assistant/ai_router/ai_router.dart';

/// Upgrade Dialog
///
/// Shows when user tries to access premium features or hits limits
class UpgradeDialog {
  /// Show upgrade prompt for a premium feature
  static Future<void> showFeatureLocked(
    BuildContext context,
    String featureName,
  ) async {
    final description = FeatureDescriptions.getDescription(featureName);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Dona Premium to unlock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _FeatureList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showUpgradeOptions(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  /// Show limit reached prompt
  static Future<void> showLimitReached(
    BuildContext context,
    String featureName,
    int limit,
  ) async {
    final currentMode = AiRouter.instance.currentMode;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Daily Limit Reached'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve reached your daily limit of $limit uses for this feature.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Current Plan: ${_getModeName(currentMode)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Premium for higher limits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _LimitComparison(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showUpgradeOptions(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  /// Show upgrade options (mock UI)
  static Future<void> _showUpgradeOptions(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 Upgrade to Dona Premium',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildPricingCard(
              'Monthly',
              '\$9.99/month',
              'Perfect for getting started',
            ),
            const SizedBox(height: 12),
            _buildPricingCard(
              'Annual',
              '\$99.99/year',
              'Save 17% • Best value',
              isPopular: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement billing integration
                _showComingSoon(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPricingCard(String name, String price, String description, {bool isPopular = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? Colors.amber : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'POPULAR',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Billing integration coming soon! For now, you can manually switch modes in Settings.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  static String _getModeName(AppMode mode) {
    switch (mode) {
      case AppMode.free:
        return 'Free';
      case AppMode.premiumTrial:
        return 'Premium Trial';
      case AppMode.premium:
        return 'Premium';
    }
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _FeatureItem('Weekly Review Autopilot'),
        _FeatureItem('Focus Mode with Pomodoro'),
        _FeatureItem('Inbox & Task Triage'),
        _FeatureItem('Relationship Maintenance'),
        _FeatureItem('Autopilot History & Analytics'),
        _FeatureItem('50 Autopilots/day (vs 3 in Free)'),
        _FeatureItem('1000 AI requests/day (vs 50 in Free)'),
        _FeatureItem('Extended AI context'),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _LimitComparison extends StatelessWidget {
  const _LimitComparison();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLimitRow('Autopilots/day', '3', '50'),
        _buildLimitRow('AI Requests/day', '50', '1000'),
        _buildLimitRow('Premium Features', '✗', '✓'),
      ],
    );
  }

  Widget _buildLimitRow(String feature, String free, String premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(feature)),
          SizedBox(
            width: 40,
            child: Text(
              free,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16),
          SizedBox(
            width: 40,
            child: Text(
              premium,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
