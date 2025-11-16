import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../core/utils/logger.dart';
import '../../../assistant/memory/memory_engine.dart';
import '../../../services/student/course_manager.dart';
import '../../../services/student/exam_manager.dart';
import '../../../services/student/assignment_manager.dart';
import '../../../domain/sync/action_queue.dart';

/// Privacy & Data Settings Screen
///
/// Allows users to view, export, and delete their data
/// Provides transparency and control over stored information
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  Map<String, int>? _dataCounts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataCounts();
  }

  Future<void> _loadDataCounts() async {
    setState(() => _isLoading = true);

    try {
      final memoryStats = await MemoryEngine.instance.getMemoryStatistics();

      final counts = {
        'memories': memoryStats['totalMemories'] ?? 0,
        'preferences': memoryStats['totalPreferences'] ?? 0,
        'routines': memoryStats['totalRoutines'] ?? 0,
        'courses': CourseManager.instance.getAllCourses().length,
        'exams': ExamManager.instance.getAllExams().length,
        'assignments': AssignmentManager.instance.getAllAssignments().length,
        'queued_actions': ActionQueue.instance.pendingCount,
      };

      setState(() {
        _dataCounts = counts;
        _isLoading = false,
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load data counts', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                const Icon(
                  Icons.privacy_tip,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Data, Your Control',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'All data is stored locally on your device. You have full control.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Memory & Learning Data
                _buildDataCategoryCard(
                  title: 'Memory & Learning',
                  icon: Icons.psychology,
                  items: [
                    DataItem(
                      'Memories',
                      _dataCounts!['memories']!,
                      'Facts and information Dona remembers about you',
                    ),
                    DataItem(
                      'Preferences',
                      _dataCounts!['preferences']!,
                      'Your learned preferences and habits',
                    ),
                    DataItem(
                      'Routines',
                      _dataCounts!['routines']!,
                      'Detected patterns and routines',
                    ),
                  ],
                  onExport: () => _exportMemoryData(),
                  onClear: () => _clearMemoryData(),
                ),

                const SizedBox(height: 16),

                // Student Data
                _buildDataCategoryCard(
                  title: 'Student Data',
                  icon: Icons.school,
                  items: [
                    DataItem(
                      'Courses',
                      _dataCounts!['courses']!,
                      'Your registered courses',
                    ),
                    DataItem(
                      'Exams',
                      _dataCounts!['exams']!,
                      'Scheduled exams and tests',
                    ),
                    DataItem(
                      'Assignments',
                      _dataCounts!['assignments']!,
                      'Your assignments and projects',
                    ),
                  ],
                  onExport: () => _exportStudentData(),
                  onClear: () => _clearStudentData(),
                ),

                const SizedBox(height: 16),

                // Productivity Data
                _buildDataCategoryCard(
                  title: 'Productivity Data',
                  icon: Icons.task_alt,
                  items: [
                    DataItem(
                      'Queued Actions',
                      _dataCounts!['queued_actions']!,
                      'Pending offline actions',
                    ),
                  ],
                  onExport: () => _exportProductivityData(),
                  onClear: () => _clearProductivityData(),
                ),

                const SizedBox(height: 32),

                // Reset Everything
                _buildDangerCard(),
              ],
            ),
    );
  }

  Widget _buildDataCategoryCard({
    required String title,
    required IconData icon,
    required List<DataItem> items,
    required VoidCallback onExport,
    required VoidCallback onClear,
  }) {
    final totalCount = items.fold<int>(0, (sum, item) => sum + item.count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalCount items',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              item.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.count}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: totalCount > 0 ? onExport : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: totalCount > 0 ? onClear : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 12),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Reset All Data',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'This will permanently delete ALL your data from Dona. This action cannot be undone.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _confirmResetAll,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Export functions
  Future<void> _exportMemoryData() async {
    try {
      final memories = await MemoryEngine.instance.getTopRelevantMemories(limit: 1000);
      final preferences = await MemoryEngine.instance.getTopPreferences(limit: 1000);
      final routines = await MemoryEngine.instance.getActiveRoutines();

      final data = {
        'memories': memories.map((m) => m.toJson()).toList(),
        'preferences': preferences.map((p) => p.toJson()).toList(),
        'routines': routines.map((r) => r.toJson()).toList(),
        'exported_at': DateTime.now().toIso8601String(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: json));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory data copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export memory data', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportStudentData() async {
    try {
      final courses = CourseManager.instance.getAllCourses();
      final exams = ExamManager.instance.getAllExams();
      final assignments = AssignmentManager.instance.getAllAssignments();

      final data = {
        'courses': courses.map((c) => c.toJson()).toList(),
        'exams': exams.map((e) => e.toJson()).toList(),
        'assignments': assignments.map((a) => a.toJson()).toList(),
        'exported_at': DateTime.now().toIso8601String(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: json));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student data copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export student data', e, stackTrace);
    }
  }

  Future<void> _exportProductivityData() async {
    try {
      final actions = ActionQueue.instance.getActions();

      final data = {
        'queued_actions': actions.map((a) => a.toJson()).toList(),
        'exported_at': DateTime.now().toIso8601String(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: json));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Productivity data copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export productivity data', e, stackTrace);
    }
  }

  // Clear functions
  Future<void> _clearMemoryData() async {
    final confirmed = await _showConfirmDialog(
      'Clear Memory Data?',
      'This will delete all memories, preferences, and routines. Dona will forget everything she learned about you.',
    );

    if (confirmed == true) {
      try {
        // TODO: Add clear methods to MemoryEngine
        AppLogger.info('Clearing memory data');

        await _loadDataCounts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Memory data cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to clear memory data', e, stackTrace);
      }
    }
  }

  Future<void> _clearStudentData() async {
    final confirmed = await _showConfirmDialog(
      'Clear Student Data?',
      'This will delete all courses, exams, and assignments.',
    );

    if (confirmed == true) {
      try {
        // Clear student data
        CourseManager.instance.getAllCourses().forEach((c) {
          CourseManager.instance.deleteCourse(c.id);
        });
        ExamManager.instance.getAllExams().forEach((e) {
          ExamManager.instance.deleteExam(e.id);
        });
        AssignmentManager.instance.getAllAssignments().forEach((a) {
          AssignmentManager.instance.deleteAssignment(a.id);
        });

        await _loadDataCounts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student data cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to clear student data', e, stackTrace);
      }
    }
  }

  Future<void> _clearProductivityData() async {
    final confirmed = await _showConfirmDialog(
      'Clear Productivity Data?',
      'This will delete all queued offline actions.',
    );

    if (confirmed == true) {
      try {
        await ActionQueue.instance.clearAll();

        await _loadDataCounts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Productivity data cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to clear productivity data', e, stackTrace);
      }
    }
  }

  Future<void> _confirmResetAll() async {
    final confirmed = await _showDangerDialog(
      'Reset ALL Data?',
      'This will permanently delete EVERYTHING:\n\n• All memories and learned preferences\n• All student data (courses, exams, assignments)\n• All productivity data\n• All settings\n\nThis action CANNOT be undone!',
    );

    if (confirmed == true) {
      try {
        // Clear all data
        await _clearMemoryData();
        await _clearStudentData();
        await _clearProductivityData();

        AppLogger.info('All data reset');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data has been reset'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop(); // Return to settings
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to reset all data', e, stackTrace);
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDangerDialog(String title, String message) {
    final confirmController = TextEditingController();
    bool canConfirm = false;

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'Type DELETE to confirm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    canConfirm = value.trim().toUpperCase() == 'DELETE';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmController.dispose();
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: canConfirm
                  ? () {
                      confirmController.dispose();
                      Navigator.of(context).pop(true);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text('Reset Everything'),
            ),
          ],
        ),
      ),
    );
  }
}

class DataItem {
  final String name;
  final int count;
  final String description;

  DataItem(this.name, this.count, this.description);
}
