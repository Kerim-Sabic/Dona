import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys.dart';

/// Team model
class Team {
  final String id;
  final String name;
  final String? shortName;
  final String? alternateName;
  final String? formedYear;
  final String? sport;
  final String? league;
  final String? stadium;
  final String? description;
  final String? badgeUrl;
  final String? jerseyUrl;

  Team({
    required this.id,
    required this.name,
    this.shortName,
    this.alternateName,
    this.formedYear,
    this.sport,
    this.league,
    this.stadium,
    this.description,
    this.badgeUrl,
    this.jerseyUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['idTeam'] ?? '',
      name: json['strTeam'] ?? '',
      shortName: json['strTeamShort'],
      alternateName: json['strAlternate'],
      formedYear: json['intFormedYear']?.toString(),
      sport: json['strSport'],
      league: json['strLeague'],
      stadium: json['strStadium'],
      description: json['strDescriptionEN'],
      badgeUrl: json['strTeamBadge'],
      jerseyUrl: json['strTeamJersey'],
    );
  }
}

/// Event/Match model
class SportEvent {
  final String id;
  final String name;
  final String? league;
  final String? season;
  final String? homeTeam;
  final String? awayTeam;
  final String? homeScore;
  final String? awayScore;
  final String? date;
  final String? time;
  final String? status;
  final String? venue;

  SportEvent({
    required this.id,
    required this.name,
    this.league,
    this.season,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.date,
    this.time,
    this.status,
    this.venue,
  });

  factory SportEvent.fromJson(Map<String, dynamic> json) {
    return SportEvent(
      id: json['idEvent'] ?? '',
      name: json['strEvent'] ?? '',
      league: json['strLeague'],
      season: json['strSeason'],
      homeTeam: json['strHomeTeam'],
      awayTeam: json['strAwayTeam'],
      homeScore: json['intHomeScore']?.toString(),
      awayScore: json['intAwayScore']?.toString(),
      date: json['dateEvent'],
      time: json['strTime'],
      status: json['strStatus'],
      venue: json['strVenue'],
    );
  }

  bool get isFinished => homeScore != null && awayScore != null;
}

/// League model
class League {
  final String id;
  final String name;
  final String? sport;
  final String? country;
  final String? description;
  final String? badgeUrl;

  League({
    required this.id,
    required this.name,
    this.sport,
    this.country,
    this.description,
    this.badgeUrl,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['idLeague'] ?? '',
      name: json['strLeague'] ?? '',
      sport: json['strSport'],
      country: json['strCountry'],
      description: json['strDescriptionEN'],
      badgeUrl: json['strBadge'],
    );
  }
}

/// TheSportsDB API Service
/// https://www.thesportsdb.com/ - FREE API with key!
/// 1,200+ leagues, live scores, teams, players, and more
class SportsService {
  static final SportsService _instance = SportsService._internal();
  static SportsService get instance => _instance;

  SportsService._internal();

  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json';
  static const Duration _timeout = Duration(seconds: 15);

  // Free API key for testing (users should get their own from thesportsdb.com)
  String get _apiKey => ApiKeys.sportsDbApiKey.isEmpty
      ? '3' // Free testing key (limited functionality)
      : ApiKeys.sportsDbApiKey;

  Future<void> init() async {
    AppLogger.info('SportsService initialized with TheSportsDB API');
  }

  /// Search for team by name
  Future<List<Team>> searchTeams(String teamName) async {
    try {
      AppLogger.debug('Searching teams: $teamName');

      final url = Uri.parse('$_baseUrl/$_apiKey/searchteams.php?t=${Uri.encodeComponent(teamName)}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final teams = data['teams'] as List<dynamic>?;
        if (teams != null) {
          return teams.map((t) => Team.fromJson(t)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search teams', e, stackTrace);
      return [];
    }
  }

  /// Get next 5 events for a team
  Future<List<SportEvent>> getNextEvents(String teamId) async {
    try {
      AppLogger.debug('Fetching next events for team: $teamId');

      final url = Uri.parse('$_baseUrl/$_apiKey/eventsnext.php?id=$teamId');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['events'] as List<dynamic>?;
        if (events != null) {
          return events.map((e) => SportEvent.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch next events', e, stackTrace);
      return [];
    }
  }

  /// Get last 5 events for a team
  Future<List<SportEvent>> getLastEvents(String teamId) async {
    try {
      AppLogger.debug('Fetching last events for team: $teamId');

      final url = Uri.parse('$_baseUrl/$_apiKey/eventslast.php?id=$teamId');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['results'] as List<dynamic>?;
        if (events != null) {
          return events.map((e) => SportEvent.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch last events', e, stackTrace);
      return [];
    }
  }

  /// Get events by date
  Future<List<SportEvent>> getEventsByDate(DateTime date, {String? sport, String? league}) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      AppLogger.debug('Fetching events for date: $dateStr');

      final url = Uri.parse('$_baseUrl/$_apiKey/eventsday.php?d=$dateStr${sport != null ? '&s=${Uri.encodeComponent(sport)}' : ''}${league != null ? '&l=${Uri.encodeComponent(league)}' : ''}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['events'] as List<dynamic>?;
        if (events != null) {
          return events.map((e) => SportEvent.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch events by date', e, stackTrace);
      return [];
    }
  }

  /// Get all leagues
  Future<List<League>> getAllLeagues() async {
    try {
      AppLogger.debug('Fetching all leagues...');

      final url = Uri.parse('$_baseUrl/$_apiKey/all_leagues.php');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leagues = data['leagues'] as List<dynamic>?;
        if (leagues != null) {
          return leagues.map((l) => League.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch leagues', e, stackTrace);
      return [];
    }
  }

  /// Search leagues by country
  Future<List<League>> searchLeaguesByCountry(String country) async {
    try {
      AppLogger.debug('Searching leagues in: $country');

      final url = Uri.parse('$_baseUrl/$_apiKey/search_all_leagues.php?c=${Uri.encodeComponent(country)}');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leagues = data['countrys'] as List<dynamic>?;
        if (leagues != null) {
          return leagues.map((l) => League.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search leagues', e, stackTrace);
      return [];
    }
  }

  /// Get today's sports events
  Future<String> getTodaysSports({String? sport}) async {
    try {
      final today = DateTime.now();
      final events = await getEventsByDate(today, sport: sport);

      if (events.isEmpty) {
        return sport != null
            ? 'No $sport events scheduled for today.'
            : 'No sports events scheduled for today.';
      }

      final buffer = StringBuffer('⚽ Today\'s Sports Events:\n\n');

      for (var i = 0; i < events.length && i < 10; i++) {
        final event = events[i];
        buffer.writeln('${i + 1}. ${event.name}');
        if (event.homeTeam != null && event.awayTeam != null) {
          buffer.writeln('   ${event.homeTeam} vs ${event.awayTeam}');
        }
        if (event.time != null) {
          buffer.writeln('   🕐 ${event.time}');
        }
        if (event.venue != null) {
          buffer.writeln('   📍 ${event.venue}');
        }
        buffer.writeln();
      }

      if (events.length > 10) {
        buffer.writeln('...and ${events.length - 10} more events');
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get today\'s sports', e, stackTrace);
      return 'Unable to fetch sports events.';
    }
  }

  /// Get team info and next match
  Future<String> getTeamSummary(String teamName) async {
    try {
      final teams = await searchTeams(teamName);

      if (teams.isEmpty) {
        return 'Team "$teamName" not found.';
      }

      final team = teams.first;
      final buffer = StringBuffer();

      buffer.writeln('🏆 ${team.name}');
      if (team.league != null) {
        buffer.writeln('🏅 League: ${team.league}');
      }
      if (team.stadium != null) {
        buffer.writeln('🏟️ Stadium: ${team.stadium}');
      }
      if (team.formedYear != null) {
        buffer.writeln('📅 Formed: ${team.formedYear}');
      }

      // Get next match
      final nextEvents = await getNextEvents(team.id);
      if (nextEvents.isNotEmpty) {
        buffer.writeln('\n⚽ Next Match:');
        final next = nextEvents.first;
        buffer.writeln('${next.homeTeam} vs ${next.awayTeam}');
        if (next.date != null) {
          buffer.writeln('📅 ${next.date}');
        }
        if (next.time != null) {
          buffer.writeln('🕐 ${next.time}');
        }
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get team summary', e, stackTrace);
      return 'Unable to fetch team information.';
    }
  }

  /// Get last results for a team
  Future<String> getTeamResults(String teamName) async {
    try {
      final teams = await searchTeams(teamName);

      if (teams.isEmpty) {
        return 'Team "$teamName" not found.';
      }

      final team = teams.first;
      final lastEvents = await getLastEvents(team.id);

      if (lastEvents.isEmpty) {
        return 'No recent results for ${team.name}.';
      }

      final buffer = StringBuffer('📊 ${team.name} - Recent Results:\n\n');

      for (var i = 0; i < lastEvents.length && i < 5; i++) {
        final event = lastEvents[i];
        if (event.isFinished) {
          buffer.writeln('${event.homeTeam} ${event.homeScore} - ${event.awayScore} ${event.awayTeam}');
          if (event.date != null) {
            buffer.writeln('📅 ${event.date}\n');
          }
        }
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get team results', e, stackTrace);
      return 'Unable to fetch team results.';
    }
  }
}
