import 'package:flutter/material.dart';
import 'dart:convert';

/// Course model for academic courses
class Course {
  final String id;
  final String name;
  final String code;
  final String? professor;
  final List<ClassSchedule> meetingTimes;
  final String? location;
  final int credits;
  final Color color;
  final String semester;
  final GradingScale gradingScale;
  final String? officeHours;
  final String? syllabus;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  Course({
    required this.id,
    required this.name,
    required this.code,
    this.professor,
    required this.meetingTimes,
    this.location,
    this.credits = 3,
    required this.color,
    required this.semester,
    this.gradingScale = GradingScale.standard,
    this.officeHours,
    this.syllabus,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      professor: json['professor'] as String?,
      meetingTimes: (json['meetingTimes'] as List<dynamic>? ?? [])
          .map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
      location: json['location'] as String?,
      credits: json['credits'] as int? ?? 3,
      color: Color(json['color'] as int? ?? 0xFF2196F3),
      semester: json['semester'] as String,
      gradingScale: GradingScale.values.firstWhere(
        (e) => e.toString() == json['gradingScale'],
        orElse: () => GradingScale.standard,
      ),
      officeHours: json['officeHours'] as String?,
      syllabus: json['syllabus'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      if (professor != null) 'professor': professor,
      'meetingTimes': meetingTimes.map((e) => e.toJson()).toList(),
      if (location != null) 'location': location,
      'credits': credits,
      'color': color.value,
      'semester': semester,
      'gradingScale': gradingScale.toString(),
      if (officeHours != null) 'officeHours': officeHours,
      if (syllabus != null) 'syllabus': syllabus,
      'isActive': isActive,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }

  Course copyWith({
    String? name,
    String? code,
    String? professor,
    List<ClassSchedule>? meetingTimes,
    String? location,
    int? credits,
    Color? color,
    String? semester,
    GradingScale? gradingScale,
    String? officeHours,
    String? syllabus,
    bool? isActive,
  }) {
    return Course(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      professor: professor ?? this.professor,
      meetingTimes: meetingTimes ?? this.meetingTimes,
      location: location ?? this.location,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      semester: semester ?? this.semester,
      gradingScale: gradingScale ?? this.gradingScale,
      officeHours: officeHours ?? this.officeHours,
      syllabus: syllabus ?? this.syllabus,
      isActive: isActive ?? this.isActive,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// Class schedule for course meetings
class ClassSchedule {
  final List<int> days; // 1=Monday, 7=Sunday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final RecurrencePattern pattern;
  final String? room;

  ClassSchedule({
    required this.days,
    required this.startTime,
    required this.endTime,
    this.pattern = RecurrencePattern.weekly,
    this.room,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      days: (json['days'] as List<dynamic>).map((e) => e as int).toList(),
      startTime: TimeOfDay(
        hour: json['startHour'] as int,
        minute: json['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int,
        minute: json['endMinute'] as int,
      ),
      pattern: RecurrencePattern.values.firstWhere(
        (e) => e.toString() == json['pattern'],
        orElse: () => RecurrencePattern.weekly,
      ),
      room: json['room'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'pattern': pattern.toString(),
      if (room != null) 'room': room,
    };
  }

  String get daysString {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  String get timeString {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start - $end';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Recurrence patterns for class schedules
enum RecurrencePattern {
  weekly,      // Same days every week
  rotating,    // Rotating schedule (e.g., A/B weeks)
  biweekly,    // Every other week
}

/// Grading scale types
enum GradingScale {
  standard,    // A, B, C, D, F
  plus_minus,  // A+, A, A-, etc.
  percentage,  // 0-100%
  pass_fail,   // Pass/Fail
  gpa_4,       // 4.0 scale
  gpa_5,       // 5.0 scale (weighted)
}
