import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/logger.dart';
import '../../../assistant/ai_router/ai_router.dart';
import '../../../services/feedback/feedback_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

/// Feedback & Support Screen
///
/// Allows users to report bugs, suggest features, or provide general feedback.
/// Collects sanitized diagnostic data while respecting privacy constraints.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  FeedbackType _selectedType = FeedbackType.bug;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  bool _includeEmail = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final snapshot = await FeedbackService.instance.createFeedbackSnapshot(
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        email: _includeEmail ? _emailController.text.trim() : null,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showFeedbackOptions(snapshot);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create feedback snapshot', e, stackTrace);

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate feedback. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFeedbackOptions(String snapshot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How would you like to send this feedback?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.blue),
              title: const Text('Copy to Clipboard'),
              subtitle: const Text('Copy feedback data to share manually'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: snapshot));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _resetForm();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mail, color: Colors.orange),
              title: const Text('Email Support'),
              subtitle: const Text('Opens your email app (if available)'),
              onTap: () {
                Navigator.of(context).pop();
                _showEmailOption(snapshot);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailOption(String snapshot) {
    // In a real app, you would use url_launcher to open email client
    // For now, just show a dialog with instructions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email your feedback to:\n\nsupport@dona.ai\n\nThe feedback data has been copied to your clipboard. Paste it in the email body.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: snapshot));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback copied!')),
                );
              },
              icon: const Icon(Icons.content_copy),
              label: const Text('Copy Again'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _emailController.clear();
    setState(() {
      _includeEmail = false;
      _selectedType = FeedbackType.bug;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Support'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback type selector
            const Text(
              'What would you like to share?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(),

            const SizedBox(height: 24),

            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Brief summary of your feedback',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Please provide details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
              maxLength: 1000,
            ),

            const SizedBox(height: 16),

            // Email opt-in
            CheckboxListTile(
              title: const Text('Include my email for follow-up'),
              subtitle: const Text('Optional - we respect your privacy'),
              value: _includeEmail,
              onChanged: (value) {
                setState(() => _includeEmail = value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            if (_includeEmail) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],

            const SizedBox(height: 24),

            // Privacy notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'We only collect sanitized diagnostic data (logs, app version, OS). No personal messages or email content.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            type: FeedbackType.bug,
            icon: Icons.bug_report,
            label: 'Bug Report',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            type: FeedbackType.feature,
            icon: Icons.lightbulb,
            label: 'Feature Idea',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            type: FeedbackType.general,
            icon: Icons.chat,
            label: 'General',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required FeedbackType type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
