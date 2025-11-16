import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys_secure.dart';

/// Direction route model
class DirectionRoute {
  final String summary;
  final List<DirectionLeg> legs;
  final String overviewPolyline;
  final List<String> warnings;
  final int distanceMeters;
  final int durationSeconds;

  DirectionRoute({
    required this.summary,
    required this.legs,
    required this.overviewPolyline,
    this.warnings = const [],
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory DirectionRoute.fromJson(Map<String, dynamic> json) {
    final legs = (json['legs'] as List<dynamic>?)
            ?.map((leg) => DirectionLeg.fromJson(leg))
            .toList() ??
        [];

    int totalDistance = 0;
    int totalDuration = 0;
    for (var leg in legs) {
      totalDistance += leg.distanceMeters;
      totalDuration += leg.durationSeconds;
    }

    return DirectionRoute(
      summary: json['summary'] as String? ?? '',
      legs: legs,
      overviewPolyline: json['overview_polyline']?['points'] as String? ?? '',
      warnings: (json['warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      distanceMeters: totalDistance,
      durationSeconds: totalDuration,
    );
  }

  String get distanceFormatted {
    if (distanceMeters < 1000) return '${distanceMeters}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  String get durationFormatted {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }
}

class DirectionLeg {
  final String startAddress;
  final String endAddress;
  final int distanceMeters;
  final int durationSeconds;
  final List<DirectionStep> steps;

  DirectionLeg({
    required this.startAddress,
    required this.endAddress,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  factory DirectionLeg.fromJson(Map<String, dynamic> json) {
    return DirectionLeg(
      startAddress: json['start_address'] as String? ?? '',
      endAddress: json['end_address'] as String? ?? '',
      distanceMeters: json['distance']?['value'] as int? ?? 0,
      durationSeconds: json['duration']?['value'] as int? ?? 0,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => DirectionStep.fromJson(step))
              .toList() ??
          [],
    );
  }
}

class DirectionStep {
  final String instructions;
  final int distanceMeters;
  final int durationSeconds;
  final String travelMode;

  DirectionStep({
    required this.instructions,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.travelMode,
  });

  factory DirectionStep.fromJson(Map<String, dynamic> json) {
    return DirectionStep(
      instructions: json['html_instructions'] as String? ?? '',
      distanceMeters: json['distance']?['value'] as int? ?? 0,
      durationSeconds: json['duration']?['value'] as int? ?? 0,
      travelMode: json['travel_mode'] as String? ?? 'DRIVING',
    );
  }
}

/// Place model
class Place {
  final String placeId;
  final String name;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final String? vicinity;
  final bool? openNow;
  final List<String>? types;
  final PlaceLocation? location;

  Place({
    required this.placeId,
    required this.name,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.vicinity,
    this.openNow,
    this.types,
    this.location,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeId: (json['place_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unknown Place',
      address: json['formatted_address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      vicinity: json['vicinity'] as String?,
      openNow: json['opening_hours']?['open_now'] as bool?,
      types: (json['types'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      location: json['geometry']?['location'] != null
          ? PlaceLocation.fromJson(json['geometry']['location'])
          : null,
    );
  }
}

class PlaceLocation {
  final double lat;
  final double lng;

  PlaceLocation({required this.lat, required this.lng});

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      lat: ((json['lat'] as num?) ?? 0.0).toDouble(),
      lng: ((json['lng'] as num?) ?? 0.0).toDouble(),
    );
  }
}

/// Air Quality data
class AirQuality {
  final int aqi;
  final String category;
  final String dominantPollutant;
  final DateTime timestamp;

  AirQuality({
    required this.aqi,
    required this.category,
    required this.dominantPollutant,
    required this.timestamp,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    return AirQuality(
      aqi: json['aqi'] as int? ?? 0,
      category: json['category'] as String? ?? 'Unknown',
      dominantPollutant: json['dominantPollutant'] as String? ?? 'Unknown',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Service for Google Maps APIs
class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  static GoogleMapsService get instance => _instance;

  GoogleMapsService._internal();

  Future<void> init() async {
    try {
      AppLogger.info('GoogleMapsService initialized with API key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize GoogleMapsService', e, stackTrace);
    }
  }

  /// Get directions between two locations
  /// Supports: Directions API
  Future<DirectionRoute?> getDirections({
    required String origin,
    required String destination,
    String travelMode = 'driving', // driving, walking, bicycling, transit
    List<String>? waypoints,
    bool alternatives = false,
  }) async {
    try {
      AppLogger.debug('Getting directions from $origin to $destination');

      final queryParams = {
        'origin': origin,
        'destination': destination,
        'mode': travelMode,
        'alternatives': alternatives.toString(),
        'key': ApiKeys.googleMapsApiKey,
      };

      if (waypoints != null && waypoints.isNotEmpty) {
        queryParams['waypoints'] = waypoints.join('|');
      }

      final url = Uri.parse(ApiConfig.directionsEndpoint).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List<dynamic>;
          if (routes.isNotEmpty) {
            final route = DirectionRoute.fromJson(routes[0]);
            AppLogger.info('Directions fetched: ${route.distanceFormatted}, ${route.durationFormatted}');
            return route;
          }
        } else {
          throw Exception('Directions API error: ${data['status']} - ${data['error_message'] ?? ''}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get directions', e, stackTrace);
    }
    return null;
  }

  /// Search for nearby places
  /// Supports: Places API (New)
  Future<List<Place>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String type, // restaurant, cafe, hospital, etc.
    int radius = 1500, // meters
    String? keyword,
  }) async {
    try {
      AppLogger.debug('Searching for $type near $latitude, $longitude');

      final queryParams = {
        'location': '$latitude,$longitude',
        'radius': radius.toString(),
        'type': type,
        'key': ApiKeys.googleMapsApiKey,
      };

      if (keyword != null) {
        queryParams['keyword'] = keyword;
      }

      final url = Uri.parse(ApiConfig.placesEndpoint).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          final places = results.map((place) => Place.fromJson(place)).toList();
          AppLogger.info('Found ${places.length} places');
          return places;
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search nearby places', e, stackTrace);
      return [];
    }
  }

  /// Geocode an address to coordinates
  Future<PlaceLocation?> geocodeAddress(String address) async {
    try {
      AppLogger.debug('Geocoding address: $address');

      final url = Uri.parse(ApiConfig.geocodingEndpoint).replace(
        queryParameters: {
          'address': address,
          'key': ApiKeys.googleMapsApiKey,
        },
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            final location = results[0]['geometry']['location'];
            return PlaceLocation.fromJson(location);
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to geocode address', e, stackTrace);
    }
    return null;
  }

  /// Reverse geocode coordinates to address
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      AppLogger.debug('Reverse geocoding: $latitude, $longitude');

      final url = Uri.parse(ApiConfig.geocodingEndpoint).replace(
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': ApiKeys.googleMapsApiKey,
        },
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            return results[0]['formatted_address'] as String;
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to reverse geocode', e, stackTrace);
    }
    return null;
  }

  /// Get air quality for a location
  /// Supports: Air Quality API
  /// Note: This is a placeholder - actual Air Quality API has different endpoint
  Future<AirQuality?> getAirQuality(double latitude, double longitude) async {
    try {
      AppLogger.debug('Getting air quality for: $latitude, $longitude');

      // Note: Air Quality API requires different authentication
      // This is a simplified example
      final url = Uri.parse('${ApiConfig.airQualityEndpoint}').replace(
        queryParameters: {
          'location': '$latitude,$longitude',
          'key': ApiKeys.googleMapsApiKey,
        },
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AirQuality.fromJson(data);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get air quality', e, stackTrace);
    }
    return null;
  }

  /// Calculate distance matrix between multiple origins and destinations
  /// Supports: Distance Matrix API (part of Routes API)
  Future<Map<String, dynamic>?> getDistanceMatrix({
    required List<String> origins,
    required List<String> destinations,
    String travelMode = 'driving',
  }) async {
    try {
      AppLogger.debug('Calculating distance matrix');

      final url = Uri.parse('${ApiConfig.googleMapsBaseUrl}/distancematrix/json').replace(
        queryParameters: {
          'origins': origins.join('|'),
          'destinations': destinations.join('|'),
          'mode': travelMode,
          'key': ApiKeys.googleMapsApiKey,
        },
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return data;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get distance matrix', e, stackTrace);
    }
    return null;
  }

  /// Snap coordinates to roads
  /// Supports: Roads API
  Future<List<PlaceLocation>?> snapToRoads(List<PlaceLocation> points) async {
    try {
      AppLogger.debug('Snapping ${points.length} points to roads');

      final path = points.map((p) => '${p.lat},${p.lng}').join('|');

      final url = Uri.parse('${ApiConfig.roadsEndpoint}/snapToRoads').replace(
        queryParameters: {
          'path': path,
          'interpolate': 'true',
          'key': ApiKeys.googleMapsApiKey,
        },
      );

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final snappedPoints = (data['snappedPoints'] as List<dynamic>?)
            ?.map((point) => PlaceLocation.fromJson(point['location']))
            .toList();
        return snappedPoints;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to snap to roads', e, stackTrace);
    }
    return null;
  }
}
