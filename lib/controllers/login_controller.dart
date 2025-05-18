import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_app/models/user.dart';

class LoginController {
  final _storage = const FlutterSecureStorage();

  Future<bool> login(User user) async {
    // return true ; // 改: 這裡是測試用的，實際上應該是 false
    final url = Uri.parse('http://10.242.32.81:8000/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'account': user.username,
        'password': user.password,
      }),
    );
    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      if (token != null) {
        await _storage.write(key: 'token', value: token); // 儲存 JWT token
        // 新增：儲存 account
        await _storage.write(key: 'account', value: user.username);
        return true;
      }
    }
    return false;
  }
}