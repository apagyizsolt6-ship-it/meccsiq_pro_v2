import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatpalService {
  static const String baseUrl = 'https://statpal.io/api';
  static const String fallbackKey = 'b5b07a3f-b019-4a18-8969-6045169feda9';

  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 2);

  Future<String?> _getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('statpal_key');
    if (key == null || key.isEmpty) {
      return fallbackKey;
    }
    return key;
  }

  // 1. Élő meccsek lekérése a Statpal-ból
  Future<Map<String, dynamic>?> getLiveMatches({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        return _cachedData;
      }
    }

    final apiKey = await _getAccessKey();
    final url = Uri.parse('$baseUrl/v2/soccer/matches/live?access_key=$apiKey');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedData = data;
        _lastFetchTime = DateTime.now();
        return data;
      }
    } catch (_) {}
    return _cachedData;
  }

  // 2. Napi / közelgő meccsek lekérése offset alapján (pl. -7 és 7 nap között)
  Future<Map<String, dynamic>?> getDailyMatches(int offset) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse('$baseUrl/v2/soccer/matches/daily?offset=$offset&access_key=$apiKey');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 3. Ligák listájának lekérése
  Future<Map<String, dynamic>?> getLeagues() async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse('$baseUrl/v2/soccer/leagues?access_key=$apiKey');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 4. Egymás elleni múlt (H2H) lekérése a két csapat ID-ja alapján
  Future<Map<String, dynamic>?> getHeadToHeadStats(String team1Id, String team2Id) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse('$baseUrl/v2/soccer/head-to-head?access_key=$apiKey&team1_id=$team1Id&team2_id=$team2Id');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 5. Részletes meccs statisztikák ligánként
  Future<Map<String, dynamic>?> getLeagueMatchStats(String leagueId, {String? date}) async {
    final apiKey = await _getAccessKey();
    String urlStr = '$baseUrl/v2/soccer/leagues/$leagueId/matches/stats?access_key=$apiKey';
    if (date != null && date.isNotEmpty) {
      urlStr += '&date=$date';
    }
    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
