import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../data/models/calendar_event.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService.instance;
  List<CalendarEvent> _events = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadEvents();
  }

  Future<void> _checkAuthAndLoadEvents() async {
    setState(() {
      _isLoading = true;
      _isAuthenticated = _calendarService.isAuthenticated;
    });

    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _calendarService.getUpcomingEvents(maxResults: 20);
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    final success = await _calendarService.authenticate();
    if (success && mounted) {
      setState(() {
        _isAuthenticated = true;
      });
      _loadEvents();
    } else {
      if (mounted) {
        _showAuthInstructions();
      }
    }
  }

  void _showAuthInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Calendar Authentication'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To connect your Google Calendar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. A browser window will open'),
              SizedBox(height: 8),
              Text('2. Sign in with your Google account'),
              SizedBox(height: 8),
              Text('3. Grant calendar permissions'),
              SizedBox(height: 8),
              Text('4. You\'ll be redirected back to the app'),
              SizedBox(height: 16),
              Text(
                'Note: For testing, you can use mock events without signing in.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticate();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter event title')),
                );
                return;
              }

              final event = CalendarEvent(
                id: '',
                title: titleController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                location: locationController.text.trim().isEmpty
                    ? null
                    : locationController.text.trim(),
                startTime: selectedDate,
                endTime: selectedDate.add(const Duration(hours: 1)),
              );

              Navigator.pop(context);

              if (_isAuthenticated) {
                final created = await _calendarService.createEvent(event);
                if (created != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event created successfully!')),
                  );
                  _loadEvents();
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign in to create real events'),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          if (!_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _authenticate,
              tooltip: 'Sign in with Google',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _calendarService.signOut();
                setState(() {
                  _isAuthenticated = false;
                });
                _loadEvents();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Authentication status banner
                if (!_isAuthenticated)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppColors.warning.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Showing mock events. Sign in to see your real calendar.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _authenticate,
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),

                // Events list
                Expanded(
                  child: _events.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadEvents,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _events.length,
                            itemBuilder: (context, index) {
                              return _buildEventCard(_events[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    Color statusColor;
    String statusText;

    if (event.isNow) {
      statusColor = AppColors.success;
      statusText = 'NOW';
    } else if (event.isToday) {
      statusColor = AppColors.info;
      statusText = 'TODAY';
    } else if (event.isUpcoming) {
      statusColor = AppColors.secondary;
      statusText = 'UPCOMING';
    } else {
      statusColor = Colors.grey;
      statusText = 'PAST';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (event.isNow)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Event title
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Date and time
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    event.formattedDate,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    event.formattedTime,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Location
              if (event.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Description preview
              if (event.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.schedule, 'Date', event.formattedDate),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Time', event.formattedTime),
              if (event.location != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, 'Location', event.location!),
              ],
              if (event.description != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.description,
                  'Description',
                  event.description!,
                ),
              ],
              if (event.attendees.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.people,
                  'Attendees',
                  event.attendees.join(', '),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_isAuthenticated)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _calendarService.deleteEvent(event.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted')),
                  );
                  _loadEvents();
                }
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming events',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first event',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
          ),
        ],
      ),
    );
  }
}
