import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Random User model
class RandomUser {
  final String gender;
  final String title;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String cell;
  final String? picture;
  final String street;
  final String city;
  final String state;
  final String country;
  final String postcode;
  final DateTime dateOfBirth;
  final int age;
  final String nationality;

  RandomUser({
    required this.gender,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.cell,
    this.picture,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.postcode,
    required this.dateOfBirth,
    required this.age,
    required this.nationality,
  });

  factory RandomUser.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final location = json['location'];
    final dob = json['dob'];
    final picture = json['picture'];

    return RandomUser(
      gender: json['gender'] ?? 'unknown',
      title: name['title'] ?? '',
      firstName: name['first'] ?? '',
      lastName: name['last'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      cell: json['cell'] ?? '',
      picture: picture?['large'],
      street: '${location['street']['number']} ${location['street']['name']}',
      city: location['city'] ?? '',
      state: location['state'] ?? '',
      country: location['country'] ?? '',
      postcode: location['postcode']?.toString() ?? '',
      dateOfBirth: DateTime.parse(dob['date']),
      age: dob['age'] ?? 0,
      nationality: json['nat'] ?? '',
    );
  }

  String get fullName => '$title $firstName $lastName';

  String get address => '$street, $city, $state, $country $postcode';
}

/// Random User Service
/// Generates random user data for testing and demonstrations
/// FREE API - No API key required!
/// API: https://randomuser.me/
class RandomUserService {
  static final RandomUserService _instance = RandomUserService._internal();
  static RandomUserService get instance => _instance;

  RandomUserService._internal();

  static const String _baseUrl = 'https://randomuser.me/api';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Cache
  final List<RandomUser> _cachedUsers = [];

  Future<void> init() async {
    try {
      AppLogger.info('Initializing Random User Service...');

      // Pre-fetch some users
      await _fetchUsers();

      _isInitialized = true;
      AppLogger.info('Random User Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Random User Service', e, stackTrace);
    }
  }

  /// Get a single random user
  Future<RandomUser?> getRandomUser({String? gender, String? nationality}) async {
    try {
      var url = _baseUrl;
      final queryParams = <String>[];

      if (gender != null) {
        queryParams.add('gender=$gender');
      }

      if (nationality != null) {
        queryParams.add('nat=$nationality');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final user = RandomUser.fromJson(results[0]);
          _cacheUser(user);
          return user;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random user', e, stackTrace);

      // Return cached user if available
      if (_cachedUsers.isNotEmpty) {
        _cachedUsers.shuffle();
        return _cachedUsers.first;
      }
    }
    return null;
  }

  /// Get multiple random users
  Future<List<RandomUser>> getRandomUsers({
    int count = 10,
    String? gender,
    String? nationality,
  }) async {
    try {
      var url = '$_baseUrl?results=$count';

      if (gender != null) {
        url += '&gender=$gender';
      }

      if (nationality != null) {
        url += '&nat=$nationality';
      }

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        final users = results.map((json) => RandomUser.fromJson(json)).toList();
        users.forEach(_cacheUser);
        return users;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch random users', e, stackTrace);
    }

    return [];
  }

  /// Fetch and cache users
  Future<void> _fetchUsers() async {
    final users = await getRandomUsers(count: 5);
    // Users are already cached in getRandomUsers
  }

  /// Cache user
  void _cacheUser(RandomUser user) {
    if (!_cachedUsers.any((u) => u.email == user.email)) {
      _cachedUsers.add(user);
      if (_cachedUsers.length > 50) {
        _cachedUsers.removeAt(0);
      }
    }
  }

  /// Get formatted user summary
  Future<String> getUserSummary() async {
    final user = await getRandomUser();

    if (user != null) {
      final buffer = StringBuffer('👤 Random User Profile\n\n');
      buffer.writeln('📝 Name: ${user.fullName}');
      buffer.writeln('🎂 Age: ${user.age}');
      buffer.writeln('⚧️ Gender: ${user.gender.toUpperCase()}');
      buffer.writeln('📧 Email: ${user.email}');
      buffer.writeln('📱 Phone: ${user.phone}');
      buffer.writeln('📍 Address: ${user.address}');
      buffer.writeln('🌍 Nationality: ${user.nationality}');

      return buffer.toString();
    }

    return '👤 Unable to generate random user at the moment.';
  }

  /// Get formatted user list
  Future<String> getUserList({int count = 5}) async {
    final users = await getRandomUsers(count: count);

    if (users.isNotEmpty) {
      final buffer = StringBuffer('👥 Random Users (${users.length}):\n\n');

      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        buffer.writeln('${i + 1}. ${user.fullName}');
        buffer.writeln('   📧 ${user.email}');
        buffer.writeln('   📍 ${user.city}, ${user.country}');
        buffer.writeln('');
      }

      return buffer.toString();
    }

    return '👥 Unable to generate random users at the moment.';
  }

  /// Get help message
  String getHelp() {
    return '''
👤 Random User Generator Help:

Generate realistic random user data for testing and demos!

Commands:
• "Generate random user"
• "Random user profile"
• "Create test user"
• "Random person"

Examples:
• "Generate a random user"
• "Show me a random profile"
• "Create 5 test users"

Use Cases:
• Testing contact forms
• Demo applications
• UI prototyping
• Data visualization examples
''';
  }
}
