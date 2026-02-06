import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/excerpt.dart';
import '../models/check_in.dart';
import '../models/user_streak.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.4.23:3000/api';

  static Map<String, String> get _headers {
    final token = AuthService.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Extract data from API response, handling both { result: { data } } and { data } formats
  static dynamic _extractData(Map<String, dynamic> json) {
    if (json.containsKey('result')) {
      final result = json['result'];
      if (result is Map && result.containsKey('data')) {
        return result['data'];
      }
      return result;
    }
    return json['data'];
  }

  // ============ EXCERPTS ============

  static Future<List<Excerpt>> getRandomExcerpts({
    int count = 3,
    List<dynamic>? exclude,
  }) async {
    String url = '$baseUrl/excerpts/random?count=$count';
    if (exclude != null && exclude.isNotEmpty) {
      url += '&exclude=${exclude.join(",")}';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = _extractData(json) as List? ?? [];
      return list.map((e) => Excerpt.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch random excerpts');
  }

  static Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/excerpts/categories'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<String>.from(_extractData(json) ?? []);
    }
    throw Exception('Failed to fetch categories');
  }

  // ============ USERS ============

  static Future<void> createUser(String id) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode({'id': id}),
      );
      // Ignore response - user may already exist, which is fine
    } catch (e) {
      // Silently ignore - user creation is best-effort
    }
  }

  // ============ ACTIVE EXCERPTS ============

  static Future<List<Excerpt>> getActiveExcerpts(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/active-excerpts'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = _extractData(json) as List? ?? [];
      return list.map((e) => Excerpt.fromJson(e['excerpts'])).toList();
    }
    throw Exception('Failed to fetch active excerpts');
  }

  static Future<void> setActiveExcerptsBulk(
    String userId,
    List<Map<String, dynamic>> excerpts,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/active-excerpts/bulk'),
      headers: _headers,
      body: jsonEncode({'excerpts': excerpts}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set active excerpts');
    }
  }

  static Future<void> setActiveExcerpt(
    String userId,
    int slotIndex,
    dynamic excerptId,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/active-excerpts'),
      headers: _headers,
      body: jsonEncode({'slotIndex': slotIndex, 'excerptId': excerptId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set active excerpt');
    }
  }

  // ============ RETIRED EXCERPTS ============

  static Future<List<dynamic>> getRetiredExcerptIds(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/retired-excerpts'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = _extractData(json) as List? ?? [];
      return list.map((e) => e['excerpt_id']).toList();
    }
    throw Exception('Failed to fetch retired excerpts');
  }

  static Future<void> retireExcerpt(String userId, dynamic excerptId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/retired-excerpts'),
      headers: _headers,
      body: jsonEncode({'excerptId': excerptId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to retire excerpt');
    }
  }

  // ============ CHECK-INS ============

  static Future<List<CheckIn>> getCheckIns(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/check-ins'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = _extractData(json) as List? ?? [];
      return list.map((e) => CheckIn.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch check-ins');
  }

  static Future<List<CheckIn>> getCheckInsByDate(
    String userId,
    String date,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/check-ins/by-date?date=$date'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = _extractData(json) as List? ?? [];
      return list.map((e) => CheckIn.fromJson(e)).toList();
    }
    // Try to extract error message from response
    String errorMsg = 'Failed to fetch check-ins by date';
    try {
      final json = jsonDecode(response.body);
      if (json['message'] != null && json['message'].toString().isNotEmpty) {
        errorMsg = json['message'];
      } else {
        errorMsg = response.body;
      }
    } catch (_) {
      errorMsg = response.body;
    }
    throw Exception('$errorMsg (status: ${response.statusCode})');
  }

  static Future<CheckIn> createCheckIn(
    String userId,
    dynamic excerptId,
    String checkInDate, {
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/check-ins'),
      headers: _headers,
      body: jsonEncode({
        'excerptId': excerptId,
        'checkInDate': checkInDate,
        if (notes != null) 'notes': notes,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return CheckIn.fromJson(_extractData(json));
    }
    throw Exception('Failed to create check-in');
  }

  static Future<void> updateCheckInNotes(String checkInId, String notes) async {
    final response = await http.put(
      Uri.parse('$baseUrl/check-ins/$checkInId'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update check-in notes');
    }
  }

  static Future<void> deleteCheckIn(String checkInId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/check-ins/$checkInId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete check-in');
    }
  }

  // ============ STREAKS ============

  static Future<UserStreak> getStreak(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/streak'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserStreak.fromJson(_extractData(json));
    }
    throw Exception('Failed to fetch streak');
  }

  static Future<void> recordActivity(String userId, String activityDate) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/streak/activity'),
      headers: _headers,
      body: jsonEncode({'activityDate': activityDate}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to record activity');
    }
  }

  // ============ INTERESTS ============

  static Future<List<String>> getInterests(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/interests'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = _extractData(json);
      // Handle both { data: [...] } and direct list responses
      final list = data is Map ? (data['data'] ?? []) : (data ?? []);
      return List<String>.from(list);
    }
    throw Exception('Failed to fetch interests');
  }

  static Future<void> setInterests(String userId, List<String> categories) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/interests'),
      headers: _headers,
      body: jsonEncode({'categories': categories}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set interests');
    }
  }

  // ============ SETTINGS ============

  static Future<Map<String, dynamic>> getSettings(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/settings'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return _extractData(json) ?? {};
    }
    throw Exception('Failed to fetch settings');
  }

  static Future<void> setReminder(String userId, int hour, int minute) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/settings/reminder'),
      headers: _headers,
      body: jsonEncode({'hour': hour, 'minute': minute}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set reminder');
    }
  }

  static Future<void> clearReminder(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/settings/reminder'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to clear reminder');
    }
  }

  // ============ GOAL ============

  static Future<String?> getGoal(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/goal'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = _extractData(json);
      return data?['goal'];
    }
    return null;
  }

  static Future<void> setGoal(String userId, String goal) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/goal'),
      headers: _headers,
      body: jsonEncode({'goal': goal}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set goal');
    }
  }

  // ============ ACCOUNT ============

  static Future<void> deleteAccount(String userId, String reason) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    }
  }
}
