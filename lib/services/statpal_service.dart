import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatpalService {
  static const String baseUrl = 'https://statpal.io/api';

  // Segédfüggvény a mentett kulcs lekéréséhez
  Future<String?> _getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('statpal_key');
  }

  // Élő meccsek lekérése (v2 soccer)
  Future<Map<String, dynamic>?> getLiveMatches() async {
    final apiKey = await _getAccessKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('StatPal API kulcs nincs beállítva a profilban.');
    }

    final url = Uri.parse('$baseUrl/v2/soccer/matches/live?access_key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Hiba történt a lekérés során: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hálózati hiba: $e');
    }
  }

  // Felhasználói kvóta / kérések számának ellenőrzése
  Future<Map<String, dynamic>?> getRequestCount() async {
    final apiKey = await _getAccessKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final url = Uri.parse('$baseUrl/user-request-count?access_key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    
    return null;
  }
}
