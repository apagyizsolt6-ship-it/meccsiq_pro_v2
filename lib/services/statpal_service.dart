import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatpalService {
  static const String baseUrl = 'https://statpal.io/api';
  static const String fallbackKey = 'b5b07a3f-b019-4a18-8969-6045169feda9';

  /// Prioritásos ligák (ID → megjelenő név)
  static const Map<String, String> priorityLeagues = {
    '2838': 'Bajnokok Ligája',
    '2840': 'Európa Liga',
    '20686': 'Konferencia Liga',
    '3037': 'Premier League',
    '3038': 'Championship',
    '3062': 'Bundesliga',
    '3058': '2. Bundesliga',
    '3054': 'Ligue 1',
    '3050': 'Ligue 2',
    '3102': 'Serie A',
    '3098': 'Serie B',
    '3232': 'La Liga',
    '3231': 'La Liga 2',
    '3081': 'NB I',
    '3078': 'NB II',
  };

  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 2);

  Future<String?> _getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('statpal_key');
    if (key == null || key.isEmpty) return fallbackKey;
    return key;
  }

  Future<Map<String, dynamic>?> getLiveMatches({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _cachedData = null;
      _lastFetchTime = null;
    }

    if (!forceRefresh &&
        _cachedData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedData;
    }

    final apiKey = await _getAccessKey();
    final url =
        Uri.parse('$baseUrl/v2/soccer/matches/live?access_key=$apiKey');

    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedData = data;
        _lastFetchTime = DateTime.now();
        return data;
      }
    } catch (_) {}
    return _cachedData;
  }

  Future<Map<String, dynamic>?> getDailyMatches(int offset) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/matches/daily?offset=$offset&access_key=$apiKey');

    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMatchesByLeague(String leagueId) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/leagues/$leagueId/matches?access_key=$apiKey');

    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Prioritásos ligák – opcionális dátumszűréssel (yyyy-mm-dd vagy dd.mm.yyyy)
  Future<List<Map<String, dynamic>>> getPriorityLeagueMatches({
    DateTime? filterDate,
  }) async {
    final List<Map<String, dynamic>> result = [];

    String? filterKey;
    if (filterDate != null) {
      // StatPal formátum: "03.08.2026"
      final dd = filterDate.day.toString().padLeft(2, '0');
      final mm = filterDate.month.toString().padLeft(2, '0');
      final yyyy = filterDate.year.toString();
      filterKey = '$dd.$mm.$yyyy';
    }

    for (final entry in priorityLeagues.entries) {
      final leagueId = entry.key;
      final leagueName = entry.value;

      try {
        final data = await getMatchesByLeague(leagueId);
        if (data == null) continue;

        var matches = _extractMatchesFromLeagueResponse(data);

        // Dátumszűrés
        if (filterKey != null) {
          matches = matches.where((m) {
            final d = m['date']?.toString() ?? '';
            return d == filterKey;
          }).toList();
        }

        if (matches.isEmpty) continue;

        result.add({
          'name': leagueName,
          'id': leagueId,
          'matches': matches,
        });
      } catch (_) {}
    }

    return result;
  }

  List<Map<String, dynamic>> _extractMatchesFromLeagueResponse(
      Map<String, dynamic> data) {
    final List<Map<String, dynamic>> allMatches = [];

    final matchesRoot = data['matches'];
    if (matchesRoot is! Map) return allMatches;

    final tournament = matchesRoot['tournament'];
    if (tournament is! Map) return allMatches;

    // week alapú
    final weeks = tournament['week'];
    if (weeks is List) {
      for (final week in weeks) {
        if (week is! Map) continue;
        _collectMatchList(week['match'], allMatches);
      }
    }

    // stage alapú
    final stages = tournament['stage'];
    if (stages is List) {
      for (final stage in stages) {
        if (stage is! Map) continue;
        _collectMatchList(stage['match'], allMatches);

        final innerWeeks = stage['week'];
        if (innerWeeks is List) {
          for (final week in innerWeeks) {
            if (week is! Map) continue;
            _collectMatchList(week['match'], allMatches);
          }
        }
      }
    }

    for (final m in allMatches) {
      final home = m['home'];
      final away = m['away'];
      if (home is Map) {
        home['goals'] = home['goals'] ?? home['score'] ?? '';
        home['name'] = home['name']?.toString() ?? 'Hazai';
      }
      if (away is Map) {
        away['goals'] = away['goals'] ?? away['score'] ?? '';
        away['name'] = away['name']?.toString() ?? 'Vendég';
      }
      m['status'] = m['status']?.toString() ?? '';
      m['time'] = m['time']?.toString() ?? '';
      m['date'] = m['date']?.toString() ?? '';
    }

    return allMatches;
  }

  void _collectMatchList(dynamic raw, List<Map<String, dynamic>> out) {
    if (raw is List) {
      for (final m in raw) {
        if (m is Map) out.add(Map<String, dynamic>.from(m));
      }
    } else if (raw is Map) {
      out.add(Map<String, dynamic>.from(raw));
    }
  }

  Future<Map<String, dynamic>?> getLeagues() async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse('$baseUrl/v2/soccer/leagues?access_key=$apiKey');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getHeadToHeadStats(
      String team1Id, String team2Id) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/head-to-head?access_key=$apiKey&team1_id=$team1Id&team2_id=$team2Id');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getStandings(String leagueId) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/leagues/$leagueId/standings?access_key=$apiKey');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getLeagueMatchStats(String leagueId,
      {String? date}) async {
    final apiKey = await _getAccessKey();
    String urlStr =
        '$baseUrl/v2/soccer/leagues/$leagueId/matches/stats?access_key=$apiKey';
    if (date != null && date.isNotEmpty) urlStr += '&date=$date';
    try {
      final response = await http
          .get(Uri.parse(urlStr), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
