import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HistoryController {
  static final _storage = const FlutterSecureStorage();

  static Future<List<dynamic>> fetchLabelRecords() async {
    final token = await _storage.read(key: 'token');
    print(token);
    if (token == null) {
      return [];
    }
    final url = Uri.parse('http://10.242.32.81:8000/get_label_for_inspector/$token');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        print('Response: $decoded');
        return jsonDecode(decoded) as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
