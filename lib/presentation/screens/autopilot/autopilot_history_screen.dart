import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/autopilot/history/autopilot_history_entry.dart';
import '../../../domain/autopilot/history/autopilot_history_service.dart';
import '../../../core/utils/logger.dart';

/// Autopilot History Screen
///
/// Shows list of autopilot executions with filtering and statistics
class AutopilotHistoryScreen extends StatefulWidget {
  const AutopilotHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AutopilotHistoryScreen> createState() => _AutopilotHistoryScreenState();
}

class _AutopilotHistoryScreenState extends State<AutopilotHistoryScreen> {
  AutopilotType? _filterType;
  String _filterPeriod = 'all'; // 'all', '7days', '30days'
  List<AutopilotHistoryEntry> _filteredHistory = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      await AutopilotHistoryService.instance.init();

      setState(() {
        _applyFilters();
        _updateStatistics();
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load autopilot history', e, stackTrace);
    }
  }

  void _applyFilters() {
    var history = AutopilotHistoryService.instance.getAllHistory();

    // Filter by type
    if (_filterType != null) {
      history = history.where((e) => e.type == _filterType).toList();
    }

    // Filter by period
    if (_filterPeriod != 'all') {
      final now = DateTime.now();
      DateTime startDate;

      if (_filterPeriod == '7days') {
        startDate = now.subtract(const Duration(days: 7));
      } else {
        startDate = now.subtract(const Duration(days: 30));
      }

      history = history.where((e) => e.timestamp.isAfter(startDate)).toList();
    }

    _filteredHistory = history;
  }

  void _updateStatistics() {
    DateTime? startDate;

    if (_filterPeriod == '7days') {
      startDate = DateTime.now().subtract(const Duration(days: 7));
    } else if (_filterPeriod == '30days') {
      startDate = DateTime.now().subtract(const Duration(days: 30));
    }

    _statistics = AutopilotHistoryService.instance.getStatistics(
      startDate: startDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autopilot History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClearHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear History'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(),

          // Filters
          _buildFilters(),

          // History List
          Expanded(
            child: _filteredHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredHistory[index];
                      return _buildHistoryTile(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _statistics['totalExecutions']?.toString() ?? '0',
                  Icons.auto_awesome,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Success',
                  _statistics['successfulExecutions']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Failed',
                  (_statistics['failedExecutions'] ?? 0 +
                      _statistics['partialExecutions'] ?? 0).toString(),
                  Icons.error,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Rate',
                  '${((_statistics['successRate'] ?? 0) * 100).toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Type filter
          Expanded(
            child: DropdownButtonFormField<AutopilotType?>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...AutopilotType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text('${type.icon} ${type.displayName}'),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterType = value;
                  _applyFilters();
                  _updateStatistics();
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Period filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterPeriod,
              decoration: const InputDecoration(
                labelText: 'Period',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Time')),
                DropdownMenuItem(value: '7days', child: Text('Last 7 Days')),
                DropdownMenuItem(value: '30days', child: Text('Last 30 Days')),
              ],
              onChanged: (value) {
                setState(() {
                  _filterPeriod = value!;
                  _applyFilters();
                  _updateStatistics();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(AutopilotHistoryEntry entry) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(entry.status).withOpacity(0.2),
          child: Text(
            entry.type.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          entry.type.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  dateFormat.format(entry.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${entry.status.icon} ${entry.status.displayName}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${entry.executedActions}/${entry.totalActions}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _showEntryDetails(entry),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No autopilot history',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run an autopilot to see it here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AutopilotHistoryStatus status) {
    switch (status) {
      case AutopilotHistoryStatus.success:
        return Colors.green;
      case AutopilotHistoryStatus.partial:
        return Colors.orange;
      case AutopilotHistoryStatus.failed:
        return Colors.red;
      case AutopilotHistoryStatus.cancelled:
        return Colors.grey;
    }
  }

  void _showEntryDetails(AutopilotHistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.type.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.type.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Summary', entry.summary),
            _buildDetailRow('Status', '${entry.status.icon} ${entry.status.displayName}'),
            _buildDetailRow('Actions', '${entry.executedActions} / ${entry.totalActions}'),
            _buildDetailRow(
              'Success Rate',
              '${(entry.successRate * 100).toStringAsFixed(0)}%',
            ),
            _buildDetailRow(
              'Time',
              DateFormat('MMM d, y • h:mm a').format(entry.timestamp),
            ),
            if (entry.errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Error', entry.errorMessage!),
            ],
            if (entry.createdItemIds != null && entry.createdItemIds!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Created Items',
                '${entry.createdItemIds!.length} items',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all autopilot history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AutopilotHistoryService.instance.clearHistory();
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }
}
