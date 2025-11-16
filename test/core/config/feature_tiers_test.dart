import 'package:flutter_test/flutter_test.dart';
import 'package:dona_ai/core/config/feature_tiers.dart';
import 'package:dona_ai/assistant/ai_router/ai_models.dart';

void main() {
  group('Feature Tiers', () {
    group('Feature Availability', () {
      test('Free users can access free features', () {
        expect(
          FeatureTiers.isFeatureAvailable('plan_my_day', AppMode.free),
          isTrue,
        );
        expect(
          FeatureTiers.isFeatureAvailable('study_autopilot', AppMode.free),
          isTrue,
        );
        expect(
          FeatureTiers.isFeatureAvailable('command_center', AppMode.free),
          isTrue,
        );
      });

      test('Free users cannot access premium features', () {
        expect(
          FeatureTiers.isFeatureAvailable('weekly_review', AppMode.free),
          isFalse,
        );
        expect(
          FeatureTiers.isFeatureAvailable('focus_mode', AppMode.free),
          isFalse,
        );
        expect(
          FeatureTiers.isFeatureAvailable('triage', AppMode.free),
          isFalse,
        );
      });

      test('Premium users can access all features', () {
        expect(
          FeatureTiers.isFeatureAvailable('plan_my_day', AppMode.premium),
          isTrue,
        );
        expect(
          FeatureTiers.isFeatureAvailable('weekly_review', AppMode.premium),
          isTrue,
        );
        expect(
          FeatureTiers.isFeatureAvailable('focus_mode', AppMode.premium),
          isTrue,
        );
      });

      test('Premium trial users can access all features', () {
        expect(
          FeatureTiers.isFeatureAvailable('weekly_review', AppMode.premiumTrial),
          isTrue,
        );
        expect(
          FeatureTiers.isFeatureAvailable('triage', AppMode.premiumTrial),
          isTrue,
        );
      });
    });

    group('Daily Limits', () {
      test('Free tier has correct daily limits', () {
        expect(
          FeatureTiers.getDailyLimit('plan_my_day', AppMode.free),
          equals(1),
        );
        expect(
          FeatureTiers.getDailyLimit('study_autopilot', AppMode.free),
          equals(2),
        );
        expect(
          FeatureTiers.getDailyLimit('total_autopilots', AppMode.free),
          equals(3),
        );
      });

      test('Premium tier has correct daily limits', () {
        expect(
          FeatureTiers.getDailyLimit('total_autopilots', AppMode.premium),
          equals(50),
        );
        expect(
          FeatureTiers.getDailyLimit('ai_requests', AppMode.premium),
          equals(1000),
        );
      });

      test('Premium trial has intermediate limits', () {
        expect(
          FeatureTiers.getDailyLimit('total_autopilots', AppMode.premiumTrial),
          equals(10),
        );
        expect(
          FeatureTiers.getDailyLimit('ai_requests', AppMode.premiumTrial),
          equals(200),
        );
      });
    });

    group('Feature Tier Detection', () {
      test('Correctly identifies free tier features', () {
        expect(
          FeatureTiers.getFeatureTier('plan_my_day'),
          equals(FeatureTier.free),
        );
      });

      test('Correctly identifies premium tier features', () {
        expect(
          FeatureTiers.getFeatureTier('weekly_review'),
          equals(FeatureTier.premium),
        );
      });

      test('Unknown features default to premium', () {
        expect(
          FeatureTiers.getFeatureTier('unknown_feature'),
          equals(FeatureTier.premium),
        );
      });
    });
  });

  group('Feature Usage Tracker', () {
    setUp(() {
      FeatureUsageTracker.instance.reset();
    });

    test('Tracks feature usage', () {
      expect(
        FeatureUsageTracker.instance.getTodayUsage('plan_my_day'),
        equals(0),
      );

      FeatureUsageTracker.instance.recordUsage('plan_my_day');

      expect(
        FeatureUsageTracker.instance.getTodayUsage('plan_my_day'),
        equals(1),
      );
    });

    test('Increments usage count on multiple uses', () {
      FeatureUsageTracker.instance.recordUsage('study_autopilot');
      FeatureUsageTracker.instance.recordUsage('study_autopilot');
      FeatureUsageTracker.instance.recordUsage('study_autopilot');

      expect(
        FeatureUsageTracker.instance.getTodayUsage('study_autopilot'),
        equals(3),
      );
    });

    test('Correctly checks if under limit (free tier)', () {
      // Plan My Day has limit of 1 in free tier
      expect(
        FeatureUsageTracker.instance.isUnderLimit('plan_my_day', AppMode.free),
        isTrue,
      );

      FeatureUsageTracker.instance.recordUsage('plan_my_day');

      expect(
        FeatureUsageTracker.instance.isUnderLimit('plan_my_day', AppMode.free),
        isFalse,
      );
    });

    test('Correctly checks if under limit (premium tier)', () {
      // Premium has much higher limits
      for (int i = 0; i < 10; i++) {
        FeatureUsageTracker.instance.recordUsage('plan_my_day');
      }

      expect(
        FeatureUsageTracker.instance.isUnderLimit('total_autopilots', AppMode.premium),
        isTrue,
      );
    });

    test('Calculates remaining uses correctly', () {
      expect(
        FeatureUsageTracker.instance.getRemainingUses('plan_my_day', AppMode.free),
        equals(1),
      );

      FeatureUsageTracker.instance.recordUsage('plan_my_day');

      expect(
        FeatureUsageTracker.instance.getRemainingUses('plan_my_day', AppMode.free),
        equals(0),
      );
    });

    test('Returns -1 for unlimited features', () {
      // Features without limits return -1
      expect(
        FeatureUsageTracker.instance.getRemainingUses('unknown_feature', AppMode.premium),
        equals(-1),
      );
    });

    test('Reset clears all usage', () {
      FeatureUsageTracker.instance.recordUsage('plan_my_day');
      FeatureUsageTracker.instance.recordUsage('study_autopilot');

      FeatureUsageTracker.instance.reset();

      expect(
        FeatureUsageTracker.instance.getTodayUsage('plan_my_day'),
        equals(0),
      );
      expect(
        FeatureUsageTracker.instance.getTodayUsage('study_autopilot'),
        equals(0),
      );
    });
  });

  group('Feature Descriptions', () {
    test('Returns description for known features', () {
      expect(
        FeatureDescriptions.getDescription('weekly_review'),
        isNotEmpty,
      );
      expect(
        FeatureDescriptions.getDescription('focus_mode'),
        contains('deep work'),
      );
    });

    test('Returns default for unknown features', () {
      expect(
        FeatureDescriptions.getDescription('unknown_feature'),
        equals('Premium feature'),
      );
    });
  });
}
