import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SportsDbService {
  static const String fallbackKey = '1';

  Future<String?> _getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('sportsdb_key');
    if (key == null || key.isEmpty) {
      return fallbackKey;
    }
    return key;
  }

  Future<Map<String, dynamic>?> getLiveMatches() async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse('https://www.thesportsdb.com/api/v1/json/$apiKey/eventsday.php?d=2026-06-06');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Hiba történt: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hálózati hiba: $e');
    }
  }
}
