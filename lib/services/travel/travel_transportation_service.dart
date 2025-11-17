import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../core/utils/input_sanitizer.dart';

/// Flight status model
class FlightInfo {
  final String flightNumber;
  final String airline;
  final String? departure;
  final String? arrival;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String status;
  final String? gate;
  final String? terminal;

  FlightInfo({
    required this.flightNumber,
    required this.airline,
    this.departure,
    this.arrival,
    this.departureTime,
    this.arrivalTime,
    required this.status,
    this.gate,
    this.terminal,
  });
}

/// Travel recommendation model
class TravelRecommendation {
  final String destination;
  final String description;
  final String? bestTime;
  final List<String> highlights;
  final String? imageUrl;
  final double? rating;

  TravelRecommendation({
    required this.destination,
    required this.description,
    this.bestTime,
    required this.highlights,
    this.imageUrl,
    this.rating,
  });
}

/// Transportation mode
enum TransportMode {
  car,
  transit,
  walking,
  cycling,
  flight,
}

/// Travel & Transportation Service
/// Provides flight tracking, directions, and travel recommendations
class TravelTransportationService {
  static final TravelTransportationService _instance = TravelTransportationService._internal();
  static TravelTransportationService get instance => _instance;

  TravelTransportationService._internal();

  static const String _aviationStackApiKey = 'your-api-key-here'; // Free API
  static const Duration _timeout = Duration(seconds: 15);

  Future<void> init() async {
    AppLogger.info('TravelTransportationService initialized');
  }

  /// Get flight status by flight number
  Future<FlightInfo?> getFlightStatus(String flightNumber) async {
    try {
      final sanitized = InputSanitizer.sanitizeText(flightNumber.toUpperCase());

      // For demonstration, return mock data
      // In production, integrate with AviationStack or FlightAware API
      return FlightInfo(
        flightNumber: sanitized,
        airline: _getAirline(sanitized),
        departure: 'JFK',
        arrival: 'LAX',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        arrivalTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'On Time',
        gate: 'B12',
        terminal: '4',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get flight status', e, stackTrace);
      return null;
    }
  }

  String _getAirline(String flightNumber) {
    if (flightNumber.startsWith('AA')) return 'American Airlines';
    if (flightNumber.startsWith('UA')) return 'United Airlines';
    if (flightNumber.startsWith('DL')) return 'Delta Air Lines';
    if (flightNumber.startsWith('BA')) return 'British Airways';
    if (flightNumber.startsWith('LH')) return 'Lufthansa';
    return 'Airline';
  }

  /// Format flight info
  String formatFlightInfo(FlightInfo flight) {
    final buffer = StringBuffer();
    buffer.writeln('✈️ Flight ${flight.flightNumber}');
    buffer.writeln('🏢 ${flight.airline}');

    if (flight.departure != null && flight.arrival != null) {
      buffer.writeln('📍 ${flight.departure} → ${flight.arrival}');
    }

    if (flight.departureTime != null) {
      buffer.writeln('🛫 Departure: ${_formatTime(flight.departureTime!)}');
    }

    if (flight.arrivalTime != null) {
      buffer.writeln('🛬 Arrival: ${_formatTime(flight.arrivalTime!)}');
    }

    buffer.writeln('📊 Status: ${flight.status}');

    if (flight.gate != null) {
      buffer.writeln('🚪 Gate: ${flight.gate}');
    }

    if (flight.terminal != null) {
      buffer.writeln('🏢 Terminal: ${flight.terminal}');
    }

    return buffer.toString();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get directions between two locations
  Future<String> getDirections({
    required String from,
    required String to,
    TransportMode mode = TransportMode.car,
  }) async {
    try {
      final sanitizedFrom = InputSanitizer.sanitizeLocationName(from);
      final sanitizedTo = InputSanitizer.sanitizeLocationName(to);

      // For demonstration, return mock directions
      // In production, integrate with Google Maps Directions API
      final modeStr = mode.toString().split('.').last;

      return '''
🗺️ Directions from $sanitizedFrom to $sanitizedTo
🚗 Mode: ${modeStr.toUpperCase()}

📍 Route:
1. Start at $sanitizedFrom
2. Head north on Main St
3. Turn right onto Highway 101
4. Continue for 5 miles
5. Exit at $sanitizedTo

⏱️ Estimated Time: 25 minutes
📏 Distance: 15.3 miles

Note: For real-time directions, integrate with Google Maps API.
''';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get directions', e, stackTrace);
      return 'Unable to get directions. Please try again.';
    }
  }

  /// Get travel recommendations
  Future<List<TravelRecommendation>> getTravelRecommendations({
    String? budget,
    String? season,
    String? interests,
  }) async {
    // Mock recommendations based on criteria
    final recommendations = <TravelRecommendation>[];

    if (budget == 'budget' || budget == 'cheap') {
      recommendations.addAll([
        TravelRecommendation(
          destination: 'Bangkok, Thailand',
          description: 'Vibrant city with rich culture and affordable prices',
          bestTime: 'November - February',
          highlights: ['Grand Palace', 'Street Food', 'Floating Markets'],
          rating: 4.7,
        ),
        TravelRecommendation(
          destination: 'Lisbon, Portugal',
          description: 'Historic city with beautiful architecture',
          bestTime: 'March - May',
          highlights: ['Belem Tower', 'Trams', 'Pasteis de Nata'],
          rating: 4.6,
        ),
      ]);
    } else if (interests == 'beach' || season == 'summer') {
      recommendations.addAll([
        TravelRecommendation(
          destination: 'Maldives',
          description: 'Tropical paradise with crystal clear waters',
          bestTime: 'November - April',
          highlights: ['Overwater Bungalows', 'Diving', 'Beaches'],
          rating: 4.9,
        ),
        TravelRecommendation(
          destination: 'Santorini, Greece',
          description: 'Stunning island with white-washed buildings',
          bestTime: 'April - October',
          highlights: ['Sunset Views', 'Blue Domes', 'Wine Tasting'],
          rating: 4.8,
        ),
      ]);
    } else {
      // Default recommendations
      recommendations.addAll([
        TravelRecommendation(
          destination: 'Paris, France',
          description: 'The City of Light and Romance',
          bestTime: 'April - June, September - October',
          highlights: ['Eiffel Tower', 'Louvre', 'Notre-Dame'],
          rating: 4.8,
        ),
        TravelRecommendation(
          destination: 'Tokyo, Japan',
          description: 'Modern metropolis with ancient traditions',
          bestTime: 'March - May, September - November',
          highlights: ['Shibuya', 'Temples', 'Sushi'],
          rating: 4.9,
        ),
        TravelRecommendation(
          destination: 'Rome, Italy',
          description: 'Eternal City with incredible history',
          bestTime: 'April - June, September - October',
          highlights: ['Colosseum', 'Vatican', 'Trevi Fountain'],
          rating: 4.7,
        ),
      ]);
    }

    return recommendations;
  }

  /// Format travel recommendations
  String formatRecommendations(List<TravelRecommendation> recommendations) {
    if (recommendations.isEmpty) {
      return 'No recommendations available.';
    }

    final buffer = StringBuffer('✈️ Travel Recommendations:\n\n');

    for (var i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      buffer.writeln('${i + 1}. ${rec.destination}');

      if (rec.rating != null) {
        buffer.writeln('   ⭐ Rating: ${rec.rating}/5.0');
      }

      buffer.writeln('   📝 ${rec.description}');

      if (rec.bestTime != null) {
        buffer.writeln('   🗓️ Best Time: ${rec.bestTime}');
      }

      if (rec.highlights.isNotEmpty) {
        buffer.writeln('   🎯 Highlights: ${rec.highlights.join(", ")}');
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get nearby attractions
  Future<String> getNearbyAttractions(String location) async {
    try {
      final sanitized = InputSanitizer.sanitizeLocationName(location);

      return '''
📍 Attractions near $sanitized:

1. 🏛️ Historic Museum
   Distance: 0.5 miles
   Rating: 4.5/5

2. 🌳 Central Park
   Distance: 1.2 miles
   Rating: 4.7/5

3. 🍽️ Local Market
   Distance: 0.8 miles
   Rating: 4.6/5

4. 🎨 Art Gallery
   Distance: 1.5 miles
   Rating: 4.4/5

5. 🏖️ Scenic Viewpoint
   Distance: 2.0 miles
   Rating: 4.8/5

Note: For real-time data, integrate with Google Places API.
''';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get nearby attractions', e, stackTrace);
      return 'Unable to find attractions. Please try again.';
    }
  }

  /// Get public transit info
  Future<String> getPublicTransit(String location) async {
    try {
      final sanitized = InputSanitizer.sanitizeLocationName(location);

      return '''
🚇 Public Transit in $sanitized:

🚌 Bus Routes:
• Route 1: Downtown → Airport
• Route 5: North Station → South Station
• Route 10: University → Mall

🚊 Metro Lines:
• Red Line: North-South
• Blue Line: East-West
• Green Line: Circular

🚖 Other Options:
• Taxi: Available 24/7
• Ride-Share: Uber, Lyft
• Bike Share: 50+ stations

💰 Fares:
• Single Ride: $2.50
• Day Pass: $8.00
• Weekly Pass: $25.00

Note: For real-time schedules, integrate with local transit APIs.
''';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get transit info', e, stackTrace);
      return 'Unable to get transit information. Please try again.';
    }
  }

  /// Get travel tips
  String getTravelTips(String? destination) {
    return '''
✈️ Travel Tips ${destination != null ? 'for $destination' : ''}:

📋 Before You Go:
• Check passport validity (6+ months)
• Research visa requirements
• Get travel insurance
• Notify your bank
• Download offline maps

💰 Money Matters:
• Use local currency when possible
• Carry backup payment methods
• Keep emergency cash hidden
• Track exchange rates

🎒 Packing Smart:
• Pack light, roll clothes
• Bring universal adapter
• Keep valuables in carry-on
• Make copies of documents

🏥 Health & Safety:
• Check vaccination requirements
• Pack basic medications
• Know emergency numbers
• Stay aware of surroundings

📱 Staying Connected:
• Get local SIM or eSIM
• Use VPN for security
• Save offline maps
• Learn basic phrases

🌍 Cultural Respect:
• Research local customs
• Dress appropriately
• Learn basic greetings
• Be patient and flexible
''';
  }

  /// Get help message
  String getHelp() {
    return '''
✈️ Travel & Transportation Help:

Flight Tracking:
• "Flight status AA123"
• "Track flight DL456"

Directions:
• "Directions from New York to Boston"
• "How do I get to Central Park"

Recommendations:
• "Travel recommendations"
• "Budget travel destinations"
• "Beach destinations"

Local Info:
• "Attractions near Times Square"
• "Public transit in London"

Tips:
• "Travel tips"
• "Travel tips for Japan"

Note: Full real-time data requires API integrations.
''';
  }
}
