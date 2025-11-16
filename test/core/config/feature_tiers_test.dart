import 'package:flutter_test/flutter_test.dart';
import 'package:dona/core/config/feature_tiers.dart';
import 'package:dona/assistant/ai_router/ai_models.dart';

void main() {
  group('FeatureTiers', () {
    test('Free mode allows only free features', () {
      expect(FeatureTiers.isFeatureAvailable('plan_my_day', AppMode.free), true);
      expect(FeatureTiers.isFeatureAvailable('study_autopilot', AppMode.free), true);
      expect(FeatureTiers.isFeatureAvailable('command_center', AppMode.free), true);

      expect(FeatureTiers.isFeatureAvailable('weekly_review', AppMode.free), false);
      expect(FeatureTiers.isFeatureAvailable('focus_mode', AppMode.free), false);
      expect(FeatureTiers.isFeatureAvailable('triage', AppMode.free), false);
      expect(FeatureTiers.isFeatureAvailable('relationship', AppMode.free), false);
      expect(FeatureTiers.isFeatureAvailable('autopilot_history', AppMode.free), false);
    });

    test('Premium mode allows all features', () {
      expect(FeatureTiers.isFeatureAvailable('plan_my_day', AppMode.premium), true);
      expect(FeatureTiers.isFeatureAvailable('weekly_review', AppMode.premium), true);
      expect(FeatureTiers.isFeatureAvailable('focus_mode', AppMode.premium), true);
      expect(FeatureTiers.isFeatureAvailable('triage', AppMode.premium), true);
      expect(FeatureTiers.isFeatureAvailable('relationship', AppMode.premium), true);
      expect(FeatureTiers.isFeatureAvailable('autopilot_history', AppMode.premium), true);
    });

    test('Premium Trial mode allows all features', () {
      expect(FeatureTiers.isFeatureAvailable('weekly_review', AppMode.premiumTrial), true);
      expect(FeatureTiers.isFeatureAvailable('autopilot_history', AppMode.premiumTrial), true);
    });

    test('Daily limits are enforced correctly', () {
      expect(FeatureTiers.getDailyLimit('plan_my_day', AppMode.free), 1);
      expect(FeatureTiers.getDailyLimit('study_autopilot', AppMode.free), 2);
      expect(FeatureTiers.getDailyLimit('total_autopilots', AppMode.free), 3);
      expect(FeatureTiers.getDailyLimit('ai_requests', AppMode.free), 50);

      expect(FeatureTiers.getDailyLimit('total_autopilots', AppMode.premium), 50);
      expect(FeatureTiers.getDailyLimit('ai_requests', AppMode.premium), 1000);
    });

    test('getFeatureTier returns correct tier', () {
      expect(FeatureTiers.getFeatureTier('plan_my_day'), FeatureTier.free);
      expect(FeatureTiers.getFeatureTier('weekly_review'), FeatureTier.premium);
      expect(FeatureTiers.getFeatureTier('unknown_feature'), FeatureTier.premium);
    });
  });

  group('FeatureUsageTracker', () {
    setUp(() {
      FeatureUsageTracker.instance.reset();
    });

    test('Records usage correctly', () {
      FeatureUsageTracker.instance.recordUsage('plan_my_day');
      expect(FeatureUsageTracker.instance.getTodayUsage('plan_my_day'), 1);

      FeatureUsageTracker.instance.recordUsage('plan_my_day');
      expect(FeatureUsageTracker.instance.getTodayUsage('plan_my_day'), 2);
    });

    test('isUnderLimit works correctly', () {
      expect(
        FeatureUsageTracker.instance.isUnderLimit('plan_my_day', AppMode.free),
        true,
      );

      FeatureUsageTracker.instance.recordUsage('plan_my_day');
      expect(
        FeatureUsageTracker.instance.isUnderLimit('plan_my_day', AppMode.free),
        false,
      );
    });

    test('getRemainingUses calculates correctly', () {
      expect(
        FeatureUsageTracker.instance.getRemainingUses('plan_my_day', AppMode.free),
        1,
      );

      FeatureUsageTracker.instance.recordUsage('plan_my_day');
      expect(
        FeatureUsageTracker.instance.getRemainingUses('plan_my_day', AppMode.free),
        0,
      );

      expect(
        FeatureUsageTracker.instance.getRemainingUses('unknown_feature', AppMode.premium),
        -1,
      );
    });

    test('Multiple features tracked independently', () {
      FeatureUsageTracker.instance.recordUsage('plan_my_day');
      FeatureUsageTracker.instance.recordUsage('study_autopilot');
      FeatureUsageTracker.instance.recordUsage('study_autopilot');

      expect(FeatureUsageTracker.instance.getTodayUsage('plan_my_day'), 1);
      expect(FeatureUsageTracker.instance.getTodayUsage('study_autopilot'), 2);
    });

    test('Reset clears all usage', () {
      FeatureUsageTracker.instance.recordUsage('plan_my_day');
      FeatureUsageTracker.instance.recordUsage('study_autopilot');

      FeatureUsageTracker.instance.reset();

      expect(FeatureUsageTracker.instance.getTodayUsage('plan_my_day'), 0);
      expect(FeatureUsageTracker.instance.getTodayUsage('study_autopilot'), 0);
    });
  });

  group('FeatureDescriptions', () {
    test('Returns correct descriptions for known features', () {
      expect(
        FeatureDescriptions.getDescription('weekly_review'),
        'Review your week and plan ahead with Weekly Review Autopilot',
      );
      expect(
        FeatureDescriptions.getDescription('focus_mode'),
        'Create structured deep work sessions with Pomodoro breaks',
      );
    });

    test('Returns generic description for unknown features', () {
      expect(
        FeatureDescriptions.getDescription('unknown_feature'),
        'Premium feature',
      );
    });
  });
}
