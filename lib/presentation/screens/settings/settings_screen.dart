import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          _buildSettingsSection(
            context,
            'General',
            [
              _buildSettingsTile(
                icon: Icons.language,
                title: AppStrings.language,
                subtitle: 'English',
                onTap: () {
                  // TODO: Language selection
                },
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode,
                title: 'Theme',
                subtitle: 'System default',
                onTap: () {
                  // TODO: Theme selection
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
                  // TODO: Voice settings
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Permissions',
            [
              _buildSettingsTile(
                icon: Icons.notifications,
                title: AppStrings.notifications,
                subtitle: 'Manage notification preferences',
                onTap: () {
                  // TODO: Notification settings
                },
              ),
              _buildSettingsTile(
                icon: Icons.lock,
                title: AppStrings.privacy,
                subtitle: 'Privacy and security settings',
                onTap: () {
                  // TODO: Privacy settings
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
                subtitle: 'Version 1.0.0',
                onTap: () {
                  // TODO: About page
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
}
