import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import '../../../assistant/memory/memory_engine.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../domain/autopilot/autopilot_engine.dart';

/// Diagnostics Screen (Debug-Only)
///
/// Shows system status, recent logs, and service health
/// Only accessible in debug builds for developers
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  Map<String, dynamic>? _serviceStatus;
  List<LogEntry> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);

    try {
      // Get service status
      final memoryStats = await MemoryEngine.instance.getMemoryStatistics();

      final status = {
        'memory_engine': {
          'reachable': true,
          'total_memories': memoryStats['totalMemories'] ?? 0,
          'total_preferences': memoryStats['totalPreferences'] ?? 0,
          'total_routines': memoryStats['totalRoutines'] ?? 0,
        },
        'context_engine': {
          'reachable': true,
          'cache_valid': true, // Would check actual cache timestamp
        },
        'autopilot_engine': {
          'reachable': true,
          'active_plans': AutopilotEngine.instance.getActivePlans().length,
          'completed_results': AutopilotEngine.instance.getCompletedResults().length,
        },
      };

      // Get recent logs
      final logs = AppLogger.getRecentLogs(limit: 50);

      setState(() {
        _serviceStatus = status;
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load diagnostics', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard: only show in debug mode
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagnostics')),
        body: const Center(
          child: Text('Diagnostics only available in debug builds'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              AppLogger.clearBuffer();
              _loadDiagnostics();
            },
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDiagnostics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Build info
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  // Service status
                  _buildServiceStatusCard(),
                  const SizedBox(height: 16),

                  // Log buffer
                  _buildLogsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Build Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Mode', kDebugMode ? 'Debug' : 'Release'),
            _buildInfoRow('Platform', defaultTargetPlatform.toString().split('.').last),
            _buildInfoRow('Log Buffer Size', '${AppLogger.bufferSize}/100'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    if (_serviceStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Service status unavailable'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Service Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),

            // Memory Engine
            _buildServiceSection(
              'Memory Engine',
              _serviceStatus!['memory_engine'] as Map<String, dynamic>,
              [
                'Total Memories',
                'Total Preferences',
                'Total Routines',
              ],
            ),

            const SizedBox(height: 12),

            // Context Engine
            _buildServiceSection(
              'Context Engine',
              _serviceStatus!['context_engine'] as Map<String, dynamic>,
              ['Cache Valid'],
            ),

            const SizedBox(height: 12),

            // Autopilot Engine
            _buildServiceSection(
              'Autopilot Engine',
              _serviceStatus!['autopilot_engine'] as Map<String, dynamic>,
              ['Active Plans', 'Completed Results'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection(
    String serviceName,
    Map<String, dynamic> status,
    List<String> metrics,
  ) {
    final isReachable = status['reachable'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isReachable ? Icons.check_circle : Icons.error,
              color: isReachable ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              serviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...status.entries
            .where((e) => e.key != 'reachable')
            .map((e) => Padding(
                  padding: const EdgeInsets.only(left: 24, top: 2),
                  child: Text(
                    '${_formatKey(e.key)}: ${e.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
      ],
    );
  }

  Widget _buildLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recent Logs (${_logs.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),

            if (_logs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No logs yet')),
              )
            else
              ..._logs.reversed.take(30).map((log) => _buildLogEntry(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    Color levelColor;
    switch (log.level) {
      case LogLevel.debug:
        levelColor = Colors.grey;
        break;
      case LogLevel.info:
        levelColor = Colors.blue;
        break;
      case LogLevel.warning:
        levelColor = Colors.orange;
        break;
      case LogLevel.error:
        levelColor = Colors.red;
        break;
      case LogLevel.fatal:
        levelColor = Colors.red.shade900;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.formattedTime,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Text(log.levelIcon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                fontSize: 12,
                color: levelColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
