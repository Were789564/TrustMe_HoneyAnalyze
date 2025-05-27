class ApiConstants {
  // API 基礎網域
  static const String baseUrl = 'http://10.242.32.81:8000';
  
  // API 端點
  static const String loginEndpoint = '$baseUrl/login';
  static const String submitLabelEndpoint = '$baseUrl/submit_label';
  static const String getLabelByApplyIdEndpoint = '$baseUrl/get_label_for_app_by_apply_id';
  static const String getLabelByApirayNameEndpoint = '$baseUrl/get_label_for_app_by_apiray_name';
  static const String analyzeHoneyEndpoint =  '$baseUrl/analyze_honey';
}
