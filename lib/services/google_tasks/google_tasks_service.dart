import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/logger.dart';
import '../../config/api_keys.dart';
import '../storage/local_storage_service.dart';

/// Google Task model
class GoogleTask {
  final String? id;
  final String? taskListId;
  final String title;
  final String? notes;
  final DateTime? due;
  final String? status; // 'needsAction' or 'completed'
  final DateTime? completed;
  final String? parent;
  final int? position;
  final List<GoogleTask>? subtasks;

  GoogleTask({
    this.id,
    this.taskListId,
    required this.title,
    this.notes,
    this.due,
    this.status,
    this.completed,
    this.parent,
    this.position,
    this.subtasks,
  });

  factory GoogleTask.fromJson(Map<String, dynamic> json) {
    return GoogleTask(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled Task',
      notes: json['notes'] as String?,
      due: json['due'] != null ? DateTime.parse(json['due']) : null,
      status: json['status'] as String?,
      completed: json['completed'] != null ? DateTime.parse(json['completed']) : null,
      parent: json['parent'] as String?,
      position: json['position'] != null ? int.tryParse(json['position']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (notes != null) 'notes': notes,
      if (due != null) 'due': due!.toIso8601String(),
      if (status != null) 'status': status,
      if (completed != null) 'completed': completed!.toIso8601String(),
      if (parent != null) 'parent': parent,
      if (position != null) 'position': position.toString(),
    };
  }

  bool get isCompleted => status == 'completed';
}

/// Task List model
class TaskList {
  final String id;
  final String title;
  final DateTime? updated;

  TaskList({
    required this.id,
    required this.title,
    this.updated,
  });

  factory TaskList.fromJson(Map<String, dynamic> json) {
    return TaskList(
      id: json['id'] as String,
      title: json['title'] as String,
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
    );
  }
}

/// Service for Google Tasks API integration
class GoogleTasksService {
  static final GoogleTasksService _instance = GoogleTasksService._internal();
  static GoogleTasksService get instance => _instance;

  GoogleTasksService._internal();

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> init() async {
    try {
      // Try to load saved access token
      _accessToken = LocalStorageService.instance.getString('google_tasks_access_token');
      final expiryStr = LocalStorageService.instance.getString('google_tasks_token_expiry');
      if (expiryStr != null) {
        _tokenExpiry = DateTime.parse(expiryStr);
      }

      AppLogger.info('GoogleTasksService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize GoogleTasksService', e, stackTrace);
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    if (_accessToken == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Authenticate user with Google OAuth 2.0
  Future<bool> authenticate() async {
    try {
      AppLogger.info('Starting Google Tasks OAuth authentication...');

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': ApiKeys.gmailClientId,
        'redirect_uri': ApiKeys.googleCalendarRedirectUri,
        'response_type': 'token',
        'scope': ApiKeys.googleTasksScopes.join(' '),
        'include_granted_scopes': 'true',
        'state': 'dona_ai_tasks',
      });

      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        AppLogger.info('OAuth browser opened');
        return false;
      } else {
        throw Exception('Could not launch OAuth URL');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to authenticate', e, stackTrace);
      return false;
    }
  }

  /// Manually set access token
  Future<void> setAccessToken(String token, {int expiresInSeconds = 3600}) async {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));

    await LocalStorageService.instance.setString('google_tasks_access_token', token);
    await LocalStorageService.instance.setString(
      'google_tasks_token_expiry',
      _tokenExpiry!.toIso8601String(),
    );

    AppLogger.info('Google Tasks access token set successfully');
  }

  /// Get all task lists
  Future<List<TaskList>> getTaskLists() async {
    try {
      if (!isAuthenticated) {
        AppLogger.warning('Not authenticated');
        return [];
      }

      final url = Uri.https('tasks.googleapis.com', '/tasks/v1/users/@me/lists');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final taskLists = items.map((item) => TaskList.fromJson(item)).toList();

        AppLogger.info('Fetched ${taskLists.length} task lists');
        return taskLists;
      } else if (response.statusCode == 401) {
        AppLogger.warning('Access token expired or invalid');
        _accessToken = null;
        return [];
      } else {
        throw Exception('Tasks API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch task lists', e, stackTrace);
      return [];
    }
  }

  /// Get tasks from a task list
  Future<List<GoogleTask>> getTasks(String taskListId, {bool showCompleted = false}) async {
    try {
      if (!isAuthenticated) {
        AppLogger.warning('Not authenticated');
        return _getMockTasks();
      }

      AppLogger.debug('Fetching tasks from list: $taskListId');

      final url = Uri.https(
        'tasks.googleapis.com',
        '/tasks/v1/lists/$taskListId/tasks',
        {
          'showCompleted': showCompleted.toString(),
          'showHidden': 'false',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final tasks = items.map((item) => GoogleTask.fromJson(item)).toList();

        AppLogger.info('Fetched ${tasks.length} tasks');
        return tasks;
      } else {
        throw Exception('Tasks API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch tasks', e, stackTrace);
      return _getMockTasks();
    }
  }

  /// Create a new task
  Future<GoogleTask?> createTask(String taskListId, GoogleTask task) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated. Please sign in first.');
      }

      AppLogger.debug('Creating task: ${task.title}');

      final url = Uri.https(
        'tasks.googleapis.com',
        '/tasks/v1/lists/$taskListId/tasks',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(task.toJson()),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final createdTask = GoogleTask.fromJson(data);
        AppLogger.info('Task created successfully: ${createdTask.id}');
        return createdTask;
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create task', e, stackTrace);
      return null;
    }
  }

  /// Update a task
  Future<GoogleTask?> updateTask(String taskListId, GoogleTask task) async {
    try {
      if (!isAuthenticated || task.id == null) {
        throw Exception('Not authenticated or invalid task ID');
      }

      AppLogger.debug('Updating task: ${task.id}');

      final url = Uri.https(
        'tasks.googleapis.com',
        '/tasks/v1/lists/$taskListId/tasks/${task.id}',
      );

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(task.toJson()),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GoogleTask.fromJson(data);
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update task', e, stackTrace);
      return null;
    }
  }

  /// Complete a task
  Future<bool> completeTask(String taskListId, String taskId) async {
    final task = GoogleTask(
      id: taskId,
      title: '',
      status: 'completed',
      completed: DateTime.now(),
    );
    final result = await updateTask(taskListId, task);
    return result != null;
  }

  /// Delete a task
  Future<bool> deleteTask(String taskListId, String taskId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated');
      }

      AppLogger.debug('Deleting task: $taskId');

      final url = Uri.https(
        'tasks.googleapis.com',
        '/tasks/v1/lists/$taskListId/tasks/$taskId',
      );

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 204) {
        AppLogger.info('Task deleted successfully');
        return true;
      } else {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete task', e, stackTrace);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _accessToken = null;
    _tokenExpiry = null;
    await LocalStorageService.instance.remove('google_tasks_access_token');
    await LocalStorageService.instance.remove('google_tasks_token_expiry');
    AppLogger.info('Signed out from Google Tasks');
  }

  /// Get mock tasks for testing
  List<GoogleTask> _getMockTasks() {
    final now = DateTime.now();
    return [
      GoogleTask(
        id: '1',
        title: 'Review project proposal',
        notes: 'Check the new client proposal and provide feedback',
        due: now.add(const Duration(days: 1)),
        status: 'needsAction',
      ),
      GoogleTask(
        id: '2',
        title: 'Buy groceries',
        notes: 'Milk, bread, eggs, vegetables',
        due: now.add(const Duration(hours: 5)),
        status: 'needsAction',
      ),
      GoogleTask(
        id: '3',
        title: 'Call dentist',
        notes: 'Schedule annual checkup',
        status: 'needsAction',
      ),
    ];
  }
}
