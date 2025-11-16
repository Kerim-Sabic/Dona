import 'package:flutter/material.dart';
import '../../../assistant/persona_manager.dart';
import '../../../assistant/persona_profiles.dart';
import '../../../assistant/memory/user_model.dart';
import '../../../core/utils/logger.dart';
import '../../../services/storage/local_storage_service.dart';

/// First-Run Onboarding Flow
///
/// Helps new users understand Dona Pro and configure their profile
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  UsageProfile? _selectedProfile;
  PersonaProfile? _selectedPersona;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      // Save selections
      if (_selectedProfile != null) {
        await UserModelService.instance.setUsageProfile(_selectedProfile!);
      }

      if (_selectedPersona != null) {
        await PersonaManager.instance.switchPersona(_selectedPersona!.id);
      }

      // Mark onboarding as completed
      await LocalStorageService.instance.setBool('onboarding_completed', true);

      AppLogger.info('Onboarding completed');

      // Navigate to Command Center
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/command-center');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to complete onboarding', e, stackTrace);
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildProfileSelectionPage(),
                  _buildPersonaSelectionPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back/Skip button
                  TextButton(
                    onPressed: _currentPage == 0 ? _skip : _previousPage,
                    child: Text(_currentPage == 0 ? 'Skip' : 'Back'),
                  ),

                  // Next/Done button
                  ElevatedButton(
                    onPressed: _canProceed() ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return true; // Welcome page, always can proceed
      case 1:
        return _selectedProfile != null; // Must select profile
      case 2:
        return _selectedPersona != null; // Must select persona
      default:
        return false;
    }
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo or icon
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Welcome to Dona Pro',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            'Your AI-powered productivity operating system',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Value propositions
          _buildFeatureItem(
            Icons.calendar_today,
            'Plan Your Day & Week',
            'Intelligent autopilots that organize your schedule',
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.rocket_launch,
            'Run Autopilots That Execute',
            'Not just chat - actual task execution and automation',
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.psychology,
            'Founder & Student Modes',
            'Personalized experience for your role and goals',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Choose Your Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize Dona for your needs',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Profile options
          Expanded(
            child: ListView(
              children: [
                _buildProfileCard(
                  UsageProfile.student,
                  '🎓 Student',
                  'Academic tools, study helpers, exam prep',
                ),
                const SizedBox(height: 12),
                _buildProfileCard(
                  UsageProfile.founder,
                  '🚀 Founder / CEO',
                  'Strategic planning, deep work, weekly reviews',
                ),
                const SizedBox(height: 12),
                _buildProfileCard(
                  UsageProfile.professional,
                  '💼 Professional',
                  'Productivity, task management, meetings',
                ),
                const SizedBox(height: 12),
                _buildProfileCard(
                  UsageProfile.mixed,
                  '🌟 Mixed',
                  'Balanced experience with all features',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UsageProfile profile, String title, String description) {
    final isSelected = _selectedProfile == profile;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedProfile = profile;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaSelectionPage() {
    // Recommend personas based on selected profile
    List<PersonaProfile> recommendedPersonas = [];
    if (_selectedProfile == UsageProfile.student) {
      recommendedPersonas = [
        PersonaProfiles.studyCoach,
        PersonaProfiles.defaultDona,
      ];
    } else if (_selectedProfile == UsageProfile.founder) {
      recommendedPersonas = [
        PersonaProfiles.founderMode,
        PersonaProfiles.professionalMode,
      ];
    } else if (_selectedProfile == UsageProfile.professional) {
      recommendedPersonas = [
        PersonaProfiles.professionalMode,
        PersonaProfiles.defaultDona,
      ];
    } else {
      recommendedPersonas = [
        PersonaProfiles.defaultDona,
        PersonaProfiles.studyCoach,
      ];
    }

    // Set default if not selected
    if (_selectedPersona == null && recommendedPersonas.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedPersona = recommendedPersonas.first;
        });
      });
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Choose Your Assistant Persona',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How would you like Dona to communicate with you?',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Persona options
          Expanded(
            child: ListView(
              children: recommendedPersonas
                  .map((persona) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPersonaCard(persona),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCard(PersonaProfile persona) {
    final isSelected = _selectedPersona?.id == persona.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPersona = persona;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    persona.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              persona.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
