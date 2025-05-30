import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_app/models/user.dart';
import '../constants/api_constants.dart';

class LoginController {
  final _storage = const FlutterSecureStorage();

  Future<bool> login(User user, {Function(String)? onError}) async {
    return true;
    final url = Uri.parse(ApiConstants.loginEndpoint);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account': user.username,
          'password': user.password,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        if (token != null) {
          await _storage.write(key: 'token', value: token);
          await _storage.write(key: 'account', value: user.username);
          return true;
        }
      } else {
        if (onError != null) {
          onError('登入失敗，請檢查帳號密碼');
        }
      }
    } catch (e) {
      if (onError != null) {
        onError('無法連線到伺服器，請檢查網路');
      }
    }
    return false;
  }
}