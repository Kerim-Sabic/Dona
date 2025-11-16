import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../demo/demo_data_service.dart';
import 'privacy_settings_screen.dart';
import 'feedback_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _isDemoMode = DemoDataService.instance.isDemoMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // Demo Mode Indicator (if active)
          if (_isDemoMode)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Demo Mode Active',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _exitDemoMode,
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ),

          _buildSettingsSection(
            context,
            'General',
            [
              _buildSettingsTile(
                icon: Icons.language,
                title: AppStrings.language,
                subtitle: 'English',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language selection coming soon!')),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode,
                title: 'Theme',
                subtitle: 'System default',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme selection coming soon!')),
                  );
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Voice & Speech',
            [
              _buildSettingsTile(
                icon: Icons.record_voice_over,
                title: AppStrings.voiceSettings,
                subtitle: 'Configure voice input and output',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice settings coming soon!')),
                  );
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Privacy & Data',
            [
              _buildSettingsTile(
                icon: Icons.lock,
                title: AppStrings.privacy,
                subtitle: 'Privacy and data management',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacySettingsScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.notifications,
                title: AppStrings.notifications,
                subtitle: 'Manage notification preferences',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings coming soon!')),
                  );
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Demo & Testing',
            [
              _buildSettingsTile(
                icon: _isDemoMode ? Icons.exit_to_app : Icons.science,
                title: _isDemoMode ? 'Exit Demo Mode' : 'Enter Demo Mode',
                subtitle: _isDemoMode
                    ? 'Exit demo mode and restore normal data'
                    : 'Generate sample data for showcases',
                onTap: _isDemoMode ? _exitDemoMode : _enterDemoMode,
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Support',
            [
              _buildSettingsTile(
                icon: Icons.feedback,
                title: 'Feedback & Support',
                subtitle: 'Report bugs or suggest features',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.history,
                title: 'Autopilot History',
                subtitle: 'View past autopilot runs',
                onTap: () {
                  Navigator.of(context).pushNamed('/autopilot-history');
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'About',
            [
              _buildSettingsTile(
                icon: Icons.info,
                title: AppStrings.about,
                subtitle: 'App info and version',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _enterDemoMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.orange),
            SizedBox(width: 8),
            Text('Enter Demo Mode?'),
          ],
        ),
        content: const Text(
          'This will generate realistic sample data for demonstrations and screenshots.\n\n'
          'Demo data will be clearly marked and can be removed by exiting demo mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Enter Demo Mode'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DemoDataService.instance.enterDemoMode();
        setState(() => _isDemoMode = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo mode activated with sample data!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enter demo mode: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exitDemoMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red),
            SizedBox(width: 8),
            Text('Exit Demo Mode?'),
          ],
        ),
        content: const Text(
          'This will remove all demo data.\n\n'
          'Your real data (if any) will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit Demo Mode'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DemoDataService.instance.exitDemoMode();
        setState(() => _isDemoMode = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo mode exited. Demo data cleared.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to exit demo mode: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
