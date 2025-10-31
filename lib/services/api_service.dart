import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // === BASE CONFIG ===
  final String _baseUrl = 'https://api.mytravaly.com/public/v1/';
  final String _authToken = '71523fdd8d26f585315b4233e39d9263';
  String? _visitorToken;

  // === SINGLETON ===
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // === STATE ===
  bool get isReady => _visitorToken != null && _visitorToken!.isNotEmpty;

  void updateVisitorToken(String token) {
    _visitorToken = token;
    debugPrint(
      '[ApiService] Visitor token updated: ${token.substring(0, 15)}...',
    );
  }

  // === CORE CALL METHOD ===
  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> body, {
    bool requiresVisitorToken = true,
    int retryCount = 0,
  }) async {
    final url = Uri.parse(_baseUrl);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'authtoken': _authToken,
      if (requiresVisitorToken && _visitorToken != null)
        'visitortoken': _visitorToken!,
    };

    // ✅ API expects action + its body merged at top level
    final requestBody = jsonEncode({'action': action, ...body});

    debugPrint('\n[ApiService] ---> CALL [$action]');
    debugPrint('[ApiService] URL: $url');
    debugPrint('[ApiService] Headers: $headers');
    debugPrint('[ApiService] Body: $requestBody\n');

    try {
      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(const Duration(seconds: 20));

      debugPrint('[ApiService] <--- Response Code: ${response.statusCode}');
      debugPrint('[ApiService] <--- Response Body: ${response.body}');

      if (response.statusCode == 429 && retryCount < 2) {
        debugPrint('[ApiService] Rate limited. Retrying...');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return _call(
          action,
          body,
          requiresVisitorToken: requiresVisitorToken,
          retryCount: retryCount + 1,
        );
      }

      final Map<String, dynamic> json = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          json['status'] == true) {
        return json;
      } else {
        return {
          'status': false,
          'message': json['message'] ?? 'Unknown API error',
          'data': json['data'],
          'httpStatus': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('[ApiService] ❌ Error: $e');
      return {'status': false, 'message': 'Network error: $e', 'data': null};
    }
  }

  // === DEVICE REGISTER ===
  Future<Map<String, dynamic>> registerDevice() async {
    const action = "deviceRegister";

    final deviceId = 'mock_device_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      action: {
        "deviceModel": "GenericModel",
        "deviceFingerprint":
            "fingerprint_${DateTime.now().millisecondsSinceEpoch}",
        "deviceBrand": "GenericBrand",
        "deviceId": deviceId,
        "deviceName": "GenericDevice",
        "deviceManufacturer": "GenericManufacturer",
        "deviceProduct": "GenericProduct",
        "deviceSerialNumber": "unknown",
      },
    };

    debugPrint('[ApiService] Registering device...');
    return _call(action, body, requiresVisitorToken: false);
  }

  // === POPULAR STAY (GetPropertyList) ===
  Future<Map<String, dynamic>> getPropertyList({
    required String query,
    int limit = 10,
    int page = 1,
    String entityType = "Any",
    String currency = "INR",
  }) async {
    const action = "popularStay";

    // First, try searching by property name
    debugPrint(
      '[ApiService] Attempting search by property name for query: "$query"',
    );
    final propertyNameBody = {
      action: {
        "limit": limit,
        "page": page,
        "entityType": entityType,
        "filter": {
          "searchType": "byPropertyName",
          "searchTypeInfo": {"propertyName": query},
        },
        "currency": currency,
      },
    };

    var response = await _call(action, propertyNameBody);

    // Check if the property name search returned any results
    final data = response['data'];
    bool hasResults = false;
    if (response['status'] == true && data is Map) {
      final list = data['popularStay']?['list'] ?? data['list'];
      if (list is List && list.isNotEmpty) {
        hasResults = true;
      }
    }

    // If no results from property name search, fall back to searching by city
    if (!hasResults) {
      debugPrint(
        '[ApiService] No results for property name. Falling back to search by city for query: "$query"',
      );
      final List<String> parts = query.split(',').map((e) => e.trim()).toList();
      final String city = parts.isNotEmpty ? parts[0] : "";
      final String state = parts.length > 1 ? parts[1] : city;
      final String country = parts.length > 2 ? parts[2] : "India";

      final cityBody = {
        action: {
          "limit": limit,
          "page": page,
          "entityType": entityType,
          "filter": {
            "searchType": "byCity",
            "searchTypeInfo": {
              "country": country,
              "state": state,
              "city": city,
            },
          },
          "currency": currency,
        },
      };
      response = await _call(action, cityBody);
    }

    // Log the full response for debugging
    debugPrint('[ApiService] Full response structure: $response');

    return response;
  }
}
