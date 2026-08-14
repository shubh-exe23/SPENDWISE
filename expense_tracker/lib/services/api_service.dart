import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  // ── TOKEN MANAGEMENT ──
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> get _headers async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ════════════════════════════
  //  AUTH
  // ════════════════════════════

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  static Future<void> logout() async {
    await clearToken();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ════════════════════════════
  //  TRANSACTIONS
  // ════════════════════════════
  
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/transactions'), headers: headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) { return []; }
  }

  static Future<bool> addTransaction(Map<String, dynamic> transactionMap) async {
    try {
      final headers = await _headers;
      final response = await http.post(Uri.parse('$baseUrl/transactions'), headers: headers, body: jsonEncode(transactionMap));
      if (response.statusCode == 401) await clearToken();
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> clearTransactions(String period) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/transactions/clear?period=$period'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════
  //  GOALS
  // ════════════════════════════

  static Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/goals'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching goals: $e');
      return [];
    }
  }

  static Future<bool> addGoal(Map<String, dynamic> goalMap) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/goals'),
        headers: headers,
        body: jsonEncode(goalMap),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding goal: $e');
      return false;
    }
  }

  static Future<bool> updateGoal(int id, Map<String, dynamic> goalMap) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/goals/$id'),
        headers: headers,
        body: jsonEncode(goalMap),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating goal: $e');
      return false;
    }
  }

  static Future<bool> deleteGoal(int id) async {
    try {
      final token = await getToken();
      final url = '$baseUrl/goals/$id'; // Fixed path without /api/
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Delete Goal Error: $e');
      return false;
    }
  }

  // ════════════════════════════
  //  NOTIFICATIONS
  // ════════════════════════════

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) { return []; }
  }

  static Future<bool> addNotification(Map<String, dynamic> notifMap) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'), 
        headers: headers, 
        body: jsonEncode(notifMap)
      );
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> markAllNotificationsRead() async {
    try {
      final headers = await _headers;
      final response = await http.put(Uri.parse('$baseUrl/notifications/mark-all-read'), headers: headers);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // ════════════════════════════
  //  USER PROFILE / SETTINGS
  // ════════════════════════════
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final headers = await _headers;
      final response = await http.get(Uri.parse('$baseUrl/auth/profile'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
         try {
           return jsonDecode(response.body);
         } catch (_) {
           return {'success': false, 'message': 'Server error: ${response.statusCode}'};
         }
      }
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Forgot Password Error: $e'); 
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'new_password': newPassword}),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
         try {
           return jsonDecode(response.body);
         } catch (_) {
           return {'success': false, 'message': 'Server error: ${response.statusCode}'};
         }
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Reset Password Error: $e');
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }
}