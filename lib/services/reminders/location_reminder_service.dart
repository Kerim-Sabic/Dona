import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/logger.dart';
import '../google_maps/google_maps_service.dart';
import '../storage/local_storage_service.dart';
import 'dart:convert';

/// Context-Aware Location Reminder Service
///
/// Reminds users when they're near specific locations.
/// Examples:
/// - "Remind me to buy milk when I'm near the grocery store"
/// - "Remind me to call John when I leave work"
/// - "Remind me to pick up dry cleaning when I'm downtown"
class LocationReminderService {
  static final LocationReminderService _instance = LocationReminderService._internal();
  static LocationReminderService get instance => _instance;

  LocationReminderService._internal();

  List<LocationReminder> _reminders = [];
  Timer? _monitoringTimer;
  Position? _lastKnownPosition;
  final Set<String> _triggeredReminders = {}; // Track triggered reminders to avoid repeats

  // Callbacks
  Function(LocationReminder)? onReminderTriggered;

  /// Initialize service
  Future<void> init() async {
    try {
      await _loadReminders();
      await _requestLocationPermission();
      AppLogger.info('LocationReminderService initialized with ${_reminders.length} reminders');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize LocationReminderService', e, stackTrace);
    }
  }

  /// Request location permission
  Future<bool> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission denied forever');
        return false;
      }

      AppLogger.info('Location permission granted');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error requesting location permission', e, stackTrace);
      return false;
    }
  }

  /// Start monitoring location
  Future<void> startMonitoring() async {
    if (_monitoringTimer != null) {
      AppLogger.debug('Location monitoring already active');
      return;
    }

    final hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      AppLogger.warning('Cannot start monitoring without location permission');
      return;
    }

    // Check location every 2 minutes
    _monitoringTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _checkReminders();
    });

    // Initial check
    await _checkReminders();

    AppLogger.info('Location monitoring started');
  }

  /// Stop monitoring location
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    AppLogger.info('Location monitoring stopped');
  }

  /// Check all reminders against current location
  Future<void> _checkReminders() async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _lastKnownPosition = position;
      AppLogger.debug('Current location: ${position.latitude}, ${position.longitude}');

      // Check each active reminder
      for (final reminder in _reminders) {
        if (!reminder.isActive) continue;
        if (_triggeredReminders.contains(reminder.id)) continue;

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          reminder.location.latitude,
          reminder.location.longitude,
        );

        AppLogger.debug('Distance to "${reminder.task}": ${distance.toStringAsFixed(0)}m');

        // Check if within trigger radius
        if (distance <= reminder.radiusMeters) {
          await _triggerReminder(reminder);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error checking reminders', e, stackTrace);
    }
  }

  /// Trigger a reminder
  Future<void> _triggerReminder(LocationReminder reminder) async {
    try {
      AppLogger.info('Triggering reminder: ${reminder.task}');

      // Mark as triggered
      _triggeredReminders.add(reminder.id);

      // Call callback
      if (onReminderTriggered != null) {
        onReminderTriggered!(reminder);
      }

      // Auto-deactivate if one-time reminder
      if (!reminder.isRecurring) {
        reminder.isActive = false;
        await _saveReminders();
      } else {
        // For recurring reminders, wait 1 hour before triggering again
        Future.delayed(const Duration(hours: 1), () {
          _triggeredReminders.remove(reminder.id);
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error triggering reminder', e, stackTrace);
    }
  }

  /// Add a new location reminder
  Future<LocationReminder> addReminder({
    required String task,
    required String locationName,
    required double latitude,
    required double longitude,
    double radiusMeters = 200,
    bool isRecurring = false,
    LocationTriggerType triggerType = LocationTriggerType.onEnter,
  }) async {
    try {
      final reminder = LocationReminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        task: task,
        location: PlaceLocation(
          name: locationName,
          latitude: latitude,
          longitude: longitude,
        ),
        radiusMeters: radiusMeters,
        isRecurring: isRecurring,
        triggerType: triggerType,
        createdAt: DateTime.now(),
      );

      _reminders.add(reminder);
      await _saveReminders();

      AppLogger.info('Added reminder: $task at $locationName');
      return reminder;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding reminder', e, stackTrace);
      rethrow;
    }
  }

  /// Add reminder by searching for location
  Future<LocationReminder?> addReminderBySearch({
    required String task,
    required String searchQuery,
    double radiusMeters = 200,
    bool isRecurring = false,
    LocationTriggerType triggerType = LocationTriggerType.onEnter,
  }) async {
    try {
      AppLogger.info('Searching for location: $searchQuery');

      // Use Google Maps to find the location
      final places = await GoogleMapsService.instance.searchNearbyPlaces(
        latitude: _lastKnownPosition?.latitude ?? 0,
        longitude: _lastKnownPosition?.longitude ?? 0,
        type: 'establishment',
        radius: 5000, // Search within 5km
      );

      // Filter by search query
      final matchingPlaces = places.where((place) =>
        place.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        place.address?.toLowerCase().contains(searchQuery.toLowerCase()) == true
      ).toList();

      if (matchingPlaces.isEmpty) {
        AppLogger.warning('No locations found for: $searchQuery');
        return null;
      }

      // Use first match
      final location = matchingPlaces.first;

      return await addReminder(
        task: task,
        locationName: location.name,
        latitude: location.latitude,
        longitude: location.longitude,
        radiusMeters: radiusMeters,
        isRecurring: isRecurring,
        triggerType: triggerType,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error adding reminder by search', e, stackTrace);
      return null;
    }
  }

  /// Remove a reminder
  Future<bool> removeReminder(String reminderId) async {
    try {
      final removed = _reminders.removeWhere((r) => r.id == reminderId);
      if (removed > 0) {
        await _saveReminders();
        _triggeredReminders.remove(reminderId);
        AppLogger.info('Removed reminder: $reminderId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error removing reminder', e, stackTrace);
      return false;
    }
  }

  /// Toggle reminder active state
  Future<void> toggleReminder(String reminderId) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == reminderId);
      reminder.isActive = !reminder.isActive;

      if (!reminder.isActive) {
        _triggeredReminders.remove(reminderId);
      }

      await _saveReminders();
      AppLogger.info('Toggled reminder: $reminderId -> ${reminder.isActive}');
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling reminder', e, stackTrace);
    }
  }

  /// Get all reminders
  List<LocationReminder> get reminders => List.unmodifiable(_reminders);

  /// Get active reminders
  List<LocationReminder> get activeReminders =>
      _reminders.where((r) => r.isActive).toList();

  /// Get current location
  Position? get currentLocation => _lastKnownPosition;

  /// Load reminders from storage
  Future<void> _loadReminders() async {
    try {
      final json = LocalStorageService.instance.getString('location_reminders');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _reminders = data.map((item) => LocationReminder.fromJson(item)).toList();
        AppLogger.info('Loaded ${_reminders.length} location reminders');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading reminders', e, stackTrace);
    }
  }

  /// Save reminders to storage
  Future<void> _saveReminders() async {
    try {
      final json = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      await LocalStorageService.instance.setString('location_reminders', json);
      AppLogger.debug('Saved ${_reminders.length} location reminders');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving reminders', e, stackTrace);
    }
  }
}

/// Location reminder model
class LocationReminder {
  final String id;
  final String task;
  final PlaceLocation location;
  final double radiusMeters;
  final bool isRecurring;
  final LocationTriggerType triggerType;
  final DateTime createdAt;
  bool isActive;

  LocationReminder({
    required this.id,
    required this.task,
    required this.location,
    this.radiusMeters = 200,
    this.isRecurring = false,
    this.triggerType = LocationTriggerType.onEnter,
    required this.createdAt,
    this.isActive = true,
  });

  factory LocationReminder.fromJson(Map<String, dynamic> json) {
    return LocationReminder(
      id: json['id'] as String,
      task: json['task'] as String,
      location: PlaceLocation.fromJson(json['location']),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200,
      isRecurring: json['isRecurring'] as bool? ?? false,
      triggerType: LocationTriggerType.values.firstWhere(
        (e) => e.toString() == json['triggerType'],
        orElse: () => LocationTriggerType.onEnter,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task': task,
      'location': location.toJson(),
      'radiusMeters': radiusMeters,
      'isRecurring': isRecurring,
      'triggerType': triggerType.toString(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return '$task (${location.name}, ${radiusMeters.toStringAsFixed(0)}m)';
  }
}

/// Place location model
class PlaceLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  PlaceLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
    };
  }

  @override
  String toString() => name;
}

/// Location trigger type
enum LocationTriggerType {
  onEnter,  // Trigger when entering the area
  onExit,   // Trigger when leaving the area
  both,     // Trigger both on enter and exit
}
