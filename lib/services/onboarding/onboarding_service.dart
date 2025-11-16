import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';

/// Onboarding Service
///
/// Manages first-run experience and onboarding state
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  static OnboardingService get instance => _instance;

  OnboardingService._internal();

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _tourCompletedKey = 'command_center_tour_completed';

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      return LocalStorageService.instance.getBool(_onboardingCompletedKey) ?? false;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check onboarding status', e, stackTrace);
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      await LocalStorageService.instance.setBool(_onboardingCompletedKey, true);
      AppLogger.info('Onboarding completed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark onboarding as completed', e, stackTrace);
    }
  }

  /// Check if user has completed Command Center tour
  Future<bool> hasCompletedTour() async {
    try {
      return LocalStorageService.instance.getBool(_tourCompletedKey) ?? false;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check tour status', e, stackTrace);
      return false;
    }
  }

  /// Mark Command Center tour as completed
  Future<void> completeTour() async {
    try {
      await LocalStorageService.instance.setBool(_tourCompletedKey, true);
      AppLogger.info('Command Center tour completed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark tour as completed', e, stackTrace);
    }
  }

  /// Reset onboarding (for testing/demo)
  Future<void> resetOnboarding() async {
    try {
      await LocalStorageService.instance.setBool(_onboardingCompletedKey, false);
      await LocalStorageService.instance.setBool(_tourCompletedKey, false);
      AppLogger.info('Onboarding reset');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to reset onboarding', e, stackTrace);
    }
  }

  /// Should show tour on Command Center
  Future<bool> shouldShowTour() async {
    final hasOnboarded = await hasCompletedOnboarding();
    final hasToured = await hasCompletedTour();
    return hasOnboarded && !hasToured;
  }
}
