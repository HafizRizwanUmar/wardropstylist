import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Use 127.0.0.1 for Web to avoid IPv6 resolution issues
final String baseUrl = kIsWeb ? 'http://127.0.0.1:9000/api' : 'http://10.0.2.2:9000/api';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<String?> signUp(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['msg'] ?? 'Sign up failed';
      }
    } catch (e) {
      return 'Error connecting to server: $e';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['msg'] ?? 'Sign in failed';
      }
    } catch (e) {
      return 'Error connecting to server: $e';
    }
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}

final authServiceProvider = Provider((ref) => AuthService());
