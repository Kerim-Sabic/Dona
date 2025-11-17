import 'dart:async';
import 'package:hive/hive.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/input_sanitizer.dart';
import '../google_tasks/google_tasks_service.dart';

/// Unified Task model
class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final TaskPriority priority;
  final TaskStatus status;
  final List<String> tags;
  final DateTime created;
  final DateTime? completed;
  final String? listId;
  final bool isRecurring;
  final RecurrencePattern? recurrence;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.reminderTime,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.tags = const [],
    required this.created,
    this.completed,
    this.listId,
    this.isRecurring = false,
    this.recurrence,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Task',
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      reminderTime: json['reminderTime'] != null ? DateTime.parse(json['reminderTime']) : null,
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      created: DateTime.parse(json['created']),
      completed: json['completed'] != null ? DateTime.parse(json['completed']) : null,
      listId: json['listId'],
      isRecurring: json['isRecurring'] ?? false,
      recurrence: json['recurrence'] != null
          ? RecurrencePattern.fromJson(json['recurrence'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'priority': priority.toString(),
      'status': status.toString(),
      'tags': tags,
      'created': created.toIso8601String(),
      'completed': completed?.toIso8601String(),
      'listId': listId,
      'isRecurring': isRecurring,
      'recurrence': recurrence?.toJson(),
    };
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    DateTime? completed,
    String? listId,
    bool? isRecurring,
    RecurrencePattern? recurrence,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      created: created,
      completed: completed ?? this.completed,
      listId: listId ?? this.listId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }
}

/// Task priority levels
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

/// Task status
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

/// Recurrence pattern for recurring tasks
class RecurrencePattern {
  final RecurrenceType type;
  final int interval;
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday
  final int? dayOfMonth;
  final DateTime? endDate;

  RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
  });

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      type: RecurrenceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RecurrenceType.none,
      ),
      interval: json['interval'] ?? 1,
      daysOfWeek: json['daysOfWeek'] != null ? List<int>.from(json['daysOfWeek']) : null,
      dayOfMonth: json['dayOfMonth'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate?.toIso8601String(),
    };
  }
}

/// Recurrence types
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

/// Task List model
class TaskListModel {
  final String id;
  final String name;
  final String? description;
  final int taskCount;
  final DateTime created;

  TaskListModel({
    required this.id,
    required this.name,
    this.description,
    required this.taskCount,
    required this.created,
  });

  factory TaskListModel.fromJson(Map<String, dynamic> json) {
    return TaskListModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      taskCount: json['taskCount'] ?? 0,
      created: DateTime.parse(json['created']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'taskCount': taskCount,
      'created': created.toIso8601String(),
    };
  }
}

/// Unified Tasks & Reminders Service
/// Integrates with Google Tasks and provides local storage fallback
class TasksRemindersService {
  static final TasksRemindersService _instance = TasksRemindersService._internal();
  static TasksRemindersService get instance => _instance;

  TasksRemindersService._internal();

  Box? _tasksBox;
  Box? _listsBox;
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      // Initialize Hive boxes
      _tasksBox = await Hive.openBox('tasks');
      _listsBox = await Hive.openBox('task_lists');

      // Initialize Google Tasks service
      await GoogleTasksService.instance.init();

      _isInitialized = true;
      AppLogger.info('TasksRemindersService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize TasksRemindersService', e, stackTrace);
    }
  }

  /// Create a new task
  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
    String? listId,
    bool isRecurring = false,
    RecurrencePattern? recurrence,
  }) async {
    try {
      // Sanitize inputs
      final sanitizedTitle = InputSanitizer.sanitizeText(title, maxLength: 200);
      final sanitizedDescription = description != null
          ? InputSanitizer.sanitizeText(description, maxLength: 1000)
          : null;

      if (sanitizedTitle.isEmpty) {
        throw ArgumentError('Task title cannot be empty');
      }

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: sanitizedTitle,
        description: sanitizedDescription,
        dueDate: dueDate,
        reminderTime: reminderTime,
        priority: priority,
        status: TaskStatus.pending,
        tags: tags,
        created: DateTime.now(),
        listId: listId,
        isRecurring: isRecurring,
        recurrence: recurrence,
      );

      // Save locally
      await _tasksBox?.put(task.id, task.toJson());

      // Try to sync with Google Tasks
      try {
        await _syncToGoogleTasks(task);
      } catch (e) {
        AppLogger.warning('Failed to sync task to Google Tasks: $e');
      }

      AppLogger.info('Task created: ${task.title}');
      return task;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create task', e, stackTrace);
      rethrow;
    }
  }

  /// Get all tasks
  Future<List<Task>> getAllTasks({
    TaskStatus? status,
    String? listId,
    List<String>? tags,
  }) async {
    try {
      if (_tasksBox == null) return [];

      final tasks = <Task>[];

      for (var key in _tasksBox!.keys) {
        final taskJson = _tasksBox!.get(key);
        if (taskJson != null) {
          final task = Task.fromJson(Map<String, dynamic>.from(taskJson));

          // Apply filters
          if (status != null && task.status != status) continue;
          if (listId != null && task.listId != listId) continue;
          if (tags != null && tags.isNotEmpty) {
            if (!tags.any((tag) => task.tags.contains(tag))) continue;
          }

          tasks.add(task);
        }
      }

      // Sort by due date (upcoming first)
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      return tasks;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get tasks', e, stackTrace);
      return [];
    }
  }

  /// Get tasks due today
  Future<List<Task>> getTasksDueToday() async {
    final allTasks = await getAllTasks(status: TaskStatus.pending);
    return allTasks.where((task) => task.isDueToday).toList();
  }

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    final allTasks = await getAllTasks(status: TaskStatus.pending);
    return allTasks.where((task) => task.isOverdue).toList();
  }

  /// Get upcoming tasks (next 7 days)
  Future<List<Task>> getUpcomingTasks({int days = 7}) async {
    final allTasks = await getAllTasks(status: TaskStatus.pending);
    final upcoming = DateTime.now().add(Duration(days: days));

    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isBefore(upcoming) && !task.isOverdue;
    }).toList();
  }

  /// Update task
  Future<Task> updateTask(Task task) async {
    try {
      await _tasksBox?.put(task.id, task.toJson());
      AppLogger.info('Task updated: ${task.title}');
      return task;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update task', e, stackTrace);
      rethrow;
    }
  }

  /// Complete task
  Future<Task> completeTask(String taskId) async {
    try {
      final taskJson = _tasksBox?.get(taskId);
      if (taskJson == null) {
        throw Exception('Task not found');
      }

      final task = Task.fromJson(Map<String, dynamic>.from(taskJson));
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        completed: DateTime.now(),
      );

      await updateTask(updatedTask);

      // Handle recurring tasks
      if (task.isRecurring && task.recurrence != null) {
        await _createNextRecurrence(task);
      }

      return updatedTask;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to complete task', e, stackTrace);
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksBox?.delete(taskId);
      AppLogger.info('Task deleted: $taskId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete task', e, stackTrace);
      rethrow;
    }
  }

  /// Create task list
  Future<TaskListModel> createTaskList(String name, {String? description}) async {
    try {
      final sanitizedName = InputSanitizer.sanitizeText(name, maxLength: 100);

      final list = TaskListModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: sanitizedName,
        description: description,
        taskCount: 0,
        created: DateTime.now(),
      );

      await _listsBox?.put(list.id, list.toJson());
      AppLogger.info('Task list created: ${list.name}');
      return list;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create task list', e, stackTrace);
      rethrow;
    }
  }

  /// Get all task lists
  Future<List<TaskListModel>> getAllTaskLists() async {
    try {
      if (_listsBox == null) return [];

      final lists = <TaskListModel>[];
      for (var key in _listsBox!.keys) {
        final listJson = _listsBox!.get(key);
        if (listJson != null) {
          lists.add(TaskListModel.fromJson(Map<String, dynamic>.from(listJson)));
        }
      }

      return lists;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get task lists', e, stackTrace);
      return [];
    }
  }

  /// Sync task to Google Tasks
  Future<void> _syncToGoogleTasks(Task task) async {
    final googleTask = GoogleTask(
      title: task.title,
      notes: task.description,
      due: task.dueDate,
      status: task.status == TaskStatus.completed ? 'completed' : 'needsAction',
    );

    // Try to create in Google Tasks
    // This will be handled by GoogleTasksService
    await GoogleTasksService.instance.createTask(googleTask);
  }

  /// Create next occurrence for recurring task
  Future<void> _createNextRecurrence(Task task) async {
    if (task.recurrence == null || task.dueDate == null) return;

    DateTime nextDueDate;

    switch (task.recurrence!.type) {
      case RecurrenceType.daily:
        nextDueDate = task.dueDate!.add(Duration(days: task.recurrence!.interval));
        break;
      case RecurrenceType.weekly:
        nextDueDate = task.dueDate!.add(Duration(days: 7 * task.recurrence!.interval));
        break;
      case RecurrenceType.monthly:
        nextDueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month + task.recurrence!.interval,
          task.dueDate!.day,
        );
        break;
      case RecurrenceType.yearly:
        nextDueDate = DateTime(
          task.dueDate!.year + task.recurrence!.interval,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        break;
      default:
        return;
    }

    // Check if we've passed the end date
    if (task.recurrence!.endDate != null &&
        nextDueDate.isAfter(task.recurrence!.endDate!)) {
      return;
    }

    // Create next occurrence
    await createTask(
      title: task.title,
      description: task.description,
      dueDate: nextDueDate,
      reminderTime: task.reminderTime != null
          ? nextDueDate.subtract(task.dueDate!.difference(task.reminderTime!))
          : null,
      priority: task.priority,
      tags: task.tags,
      listId: task.listId,
      isRecurring: true,
      recurrence: task.recurrence,
    );
  }

  /// Get task summary
  Future<String> getTaskSummary() async {
    try {
      final today = await getTasksDueToday();
      final overdue = await getOverdueTasks();
      final upcoming = await getUpcomingTasks();

      final buffer = StringBuffer();
      buffer.writeln('📋 Tasks Summary:\n');

      if (overdue.isNotEmpty) {
        buffer.writeln('⚠️ Overdue Tasks: ${overdue.length}');
        for (var task in overdue.take(3)) {
          buffer.writeln('   • ${task.title}');
        }
        if (overdue.length > 3) {
          buffer.writeln('   ... and ${overdue.length - 3} more');
        }
        buffer.writeln();
      }

      if (today.isNotEmpty) {
        buffer.writeln('📅 Due Today: ${today.length}');
        for (var task in today) {
          buffer.writeln('   • ${task.title}');
        }
        buffer.writeln();
      }

      if (upcoming.isNotEmpty) {
        buffer.writeln('🔜 Upcoming (next 7 days): ${upcoming.length}');
        for (var task in upcoming.take(5)) {
          final daysUntil = task.dueDate!.difference(DateTime.now()).inDays;
          buffer.writeln('   • ${task.title} (in $daysUntil days)');
        }
        if (upcoming.length > 5) {
          buffer.writeln('   ... and ${upcoming.length - 5} more');
        }
      }

      if (overdue.isEmpty && today.isEmpty && upcoming.isEmpty) {
        buffer.writeln('✅ All caught up! No pending tasks.');
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get task summary', e, stackTrace);
      return 'Unable to load task summary.';
    }
  }

  /// Format task for display
  String formatTask(Task task) {
    final buffer = StringBuffer();

    // Priority emoji
    String priorityEmoji;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityEmoji = '🔴';
        break;
      case TaskPriority.high:
        priorityEmoji = '🟠';
        break;
      case TaskPriority.medium:
        priorityEmoji = '🟡';
        break;
      case TaskPriority.low:
        priorityEmoji = '🟢';
        break;
    }

    buffer.write('$priorityEmoji ${task.title}');

    if (task.dueDate != null) {
      if (task.isOverdue) {
        buffer.write(' ⚠️ OVERDUE');
      } else if (task.isDueToday) {
        buffer.write(' 📅 Today');
      } else if (task.isDueTomorrow) {
        buffer.write(' 📅 Tomorrow');
      }
    }

    if (task.description != null && task.description!.isNotEmpty) {
      buffer.write('\n   ${task.description}');
    }

    if (task.tags.isNotEmpty) {
      buffer.write('\n   Tags: ${task.tags.join(", ")}');
    }

    return buffer.toString();
  }
}
