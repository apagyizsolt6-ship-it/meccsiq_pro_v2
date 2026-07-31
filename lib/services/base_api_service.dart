/*
===========================================
MeccsIQ Pro v2.0
Build: #007
Version: v2.0.0
File: base_api_service.dart
===========================================
*/

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_result.dart';

abstract class BaseApiService {
  const BaseApiService();

  /// API alap URL
  String get baseUrl;

  /// API kulcs
  Future<String?> getApiKey();

  /// Közös GET kérés
  Future<ApiResult<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final apiKey = await getApiKey();

      if (apiKey == null || apiKey.isEmpty) {
        return ApiResult.error(
          'Nincs beállított API kulcs.',
        );
      }

      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': apiKey,
          ...?headers,
        },
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return ApiResult.success(
          jsonDecode(response.body)
              as Map<String, dynamic>,
        );
      }

      return ApiResult.error(
        'HTTP ${response.statusCode}',
      );
    } catch (e) {
      return ApiResult.error(
        e.toString(),
      );
    }
  }
}
