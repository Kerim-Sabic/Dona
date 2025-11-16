import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/utils/logger.dart';
import 'dart:io';

/// About Screen
///
/// Shows app information, version, and credits
class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = info;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load package info', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header section with logo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // App icon placeholder
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 60,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _packageInfo?.appName ?? 'Dona Pro',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your AI-powered life assistant',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Version info
                  _buildInfoSection(
                    context,
                    title: 'Version Information',
                    items: [
                      _buildInfoTile(
                        icon: Icons.info_outline,
                        title: 'Version',
                        subtitle: _packageInfo?.version ?? 'Unknown',
                      ),
                      _buildInfoTile(
                        icon: Icons.build,
                        title: 'Build Number',
                        subtitle: _packageInfo?.buildNumber ?? 'Unknown',
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_android,
                        title: 'Platform',
                        subtitle: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // About section
                  _buildInfoSection(
                    context,
                    title: 'About Dona Pro',
                    items: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Dona Pro is your intelligent life assistant that helps you plan your day, '
                          'manage tasks, stay focused, and maintain relationships. With powerful '
                          'autopilots and AI-driven insights, Dona adapts to your unique lifestyle '
                          'and helps you achieve your goals.',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Links section
                  _buildInfoSection(
                    context,
                    title: 'Learn More',
                    items: [
                      _buildLinkTile(
                        icon: Icons.public,
                        title: 'Website',
                        subtitle: 'https://dona.ai',
                        onTap: () => _showComingSoon(context, 'Website link'),
                      ),
                      _buildLinkTile(
                        icon: Icons.privacy_tip,
                        title: 'Privacy Policy',
                        subtitle: 'How we protect your data',
                        onTap: () => _showComingSoon(context, 'Privacy Policy'),
                      ),
                      _buildLinkTile(
                        icon: Icons.description,
                        title: 'Terms of Service',
                        subtitle: 'Usage terms and conditions',
                        onTap: () => _showComingSoon(context, 'Terms of Service'),
                      ),
                      _buildLinkTile(
                        icon: Icons.code,
                        title: 'Open Source Licenses',
                        subtitle: 'Third-party licenses',
                        onTap: () => _showLicenses(context),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Credits
                  _buildInfoSection(
                    context,
                    title: 'Credits',
                    items: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Built with ❤️ by the Dona team\n\n'
                          'Special thanks to our beta testers and the Flutter community.',
                          style: TextStyle(fontSize: 14, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Copyright
                  Text(
                    '© ${DateTime.now().year} Dona AI. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: _packageInfo?.appName ?? 'Dona Pro',
      applicationVersion: _packageInfo?.version ?? 'Unknown',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.auto_awesome,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}
