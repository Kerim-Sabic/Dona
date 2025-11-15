class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? calendarId;
  final List<String> attendees;
  final String? colorId;
  final bool isAllDay;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.calendarId,
    this.attendees = const [],
    this.colorId,
    this.isAllDay = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final start = json['start'] as Map<String, dynamic>?;
    final end = json['end'] as Map<String, dynamic>?;

    DateTime startTime;
    DateTime endTime;
    bool isAllDay = false;

    if (start?['dateTime'] != null) {
      startTime = DateTime.parse(start!['dateTime']);
    } else if (start?['date'] != null) {
      startTime = DateTime.parse(start!['date']);
      isAllDay = true;
    } else {
      startTime = DateTime.now();
    }

    if (end?['dateTime'] != null) {
      endTime = DateTime.parse(end!['dateTime']);
    } else if (end?['date'] != null) {
      endTime = DateTime.parse(end!['date']);
    } else {
      endTime = startTime.add(const Duration(hours: 1));
    }

    final attendeesList = (json['attendees'] as List<dynamic>?)
            ?.map((a) => a['email'] as String)
            .toList() ??
        [];

    return CalendarEvent(
      id: json['id'] ?? '',
      title: json['summary'] ?? 'Untitled Event',
      description: json['description'],
      startTime: startTime,
      endTime: endTime,
      location: json['location'],
      calendarId: json['calendarId'],
      attendees: attendeesList,
      colorId: json['colorId'],
      isAllDay: isAllDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': title,
      'description': description,
      'location': location,
      'start': isAllDay
          ? {'date': _formatDate(startTime)}
          : {'dateTime': startTime.toIso8601String()},
      'end': isAllDay
          ? {'date': _formatDate(endTime)}
          : {'dateTime': endTime.toIso8601String()},
      'attendees': attendees.map((email) => {'email': email}).toList(),
      'colorId': colorId,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted date string
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[startTime.month - 1]} ${startTime.day}, ${startTime.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    if (isAllDay) return 'All day';
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMin = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMin = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
  }

  /// Get duration in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// Check if event is upcoming (future)
  bool get isUpcoming {
    return startTime.isAfter(DateTime.now());
  }

  /// Check if event is past
  bool get isPast {
    return endTime.isBefore(DateTime.now());
  }

  /// Check if event is currently happening
  bool get isNow {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }
}
