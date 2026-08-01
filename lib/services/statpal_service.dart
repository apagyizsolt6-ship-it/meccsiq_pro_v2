import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatpalService {
  static const String baseUrl = 'https://statpal.io/api';
  static const String fallbackKey = 'b5b07a3f-b019-4a18-8969-6045169feda9';

  // Cache változók a túl gyakori lekérések elkerülésére
  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 2); // 2 perc cache

  Future<String?> _getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('statpal_key');
    if (key == null || key.isEmpty) {
      return fallbackKey;
    }
    return key;
  }

  Future<Map<String, dynamic>?> getLiveMatches({bool forceRefresh = false}) async {
    // Ha van cache-elt adat és még nem telt el a 2 perc, adjuk vissza azt (késleltetés / rate-limit védelem)
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        return _cachedData;
      }
    }

    final apiKey = await _getAccessKey();
    final url = Uri.parse('$baseUrl/v2/soccer/matches/live?access_key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedData = data;
        _lastFetchTime = DateTime.now();
        return data;
      } else {
        throw Exception('Hiba történt a lekérés során: ${response.statusCode}');
      }
    } catch (e) {
      // Ha hálózati hiba van, de van régi cache, adjuk azt vissza vészhelyzetben
      if (_cachedData != null) return _cachedData;
      throw Exception('Hálózati hiba: $e');
    }
  }
}
