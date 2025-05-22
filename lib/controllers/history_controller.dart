import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HistoryController {
  static final _storage = const FlutterSecureStorage();

  // 根據 applyId 查詢（API 回傳單一物件或 404）
  static Future<Map<String, dynamic>?> fetchLabelByApplyId(int applyId) async {
    final token = await _storage.read(key: 'token');
    if (token == null) return null;
    final url = Uri.parse('http://10.242.32.81:8000/get_label_for_app_by_apply_id/$applyId?token=$token');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        print("debug:: $decoded");
        return jsonDecode(decoded) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // 找不到標章
        return null;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 根據蜂場名稱查詢（API 回傳陣列或 404）
  static Future<List<Map<String, dynamic>>> fetchLabelByApirayName(String apirayName) async {
    final token = await _storage.read(key: 'token');
    if (token == null) return [];
    final url = Uri.parse('http://10.242.32.81:8000/get_label_for_app_by_apiray_name/$apirayName?token=$token');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);
        print(data);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      } else if (response.statusCode == 404) {
        // 找不到標章
        return [];
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}
