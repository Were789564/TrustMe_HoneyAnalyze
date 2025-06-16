import 'package:flutter/material.dart';
import '../controllers/video_analyze_controller.dart';
import 'custom_dialog.dart';

class AnalyzeResultPanel extends StatelessWidget {
  final String analyzeResult;
  final String inputMode;
  final TextEditingController orderIdController;
  final TextEditingController farmNameController;
  final ValueChanged<String> onInputModeChanged;
  final TextEditingController applyCountController; // 改為參數
  final VideoAnalyzeController controller;
  final String honeyType;
  final Map<String, dynamic>? apiResponse; // 新增：API 回應資料

  const AnalyzeResultPanel({
    super.key,
    required this.analyzeResult,
    required this.inputMode,
    required this.orderIdController,
    required this.farmNameController,
    required this.onInputModeChanged,
    required this.applyCountController, // 改為必要參數
    required this.controller,
    required this.honeyType,
    this.apiResponse,
  });

  void _showErrorDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: "錯誤",
        content: msg,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 直接用與外層一致的 EdgeInsets.symmetric(horizontal: screenWidth * 0.04)
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardHorizontalPadding = screenWidth * 0.04;

    // 從 API 回應中解析 prediction 和 confidence
    String displayResult = "100% 蜂蜜"; // 預設值
    double? confidence;
    
    if (apiResponse != null && apiResponse!['result'] != null) {
      final result = apiResponse!['result'];
      final prediction = result['prediction'] ?? 100;
      displayResult = "$prediction% 蜂蜜";
      confidence = result['confidence'] as double?;
    }

    return Column(
      children: [
        // 分析結果卡片
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: cardHorizontalPadding, vertical: 16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.yellow[100],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 100),
              child: Column(
                children: [
                  const Text(
                    "分析結果",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayResult,
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange,
                      shadows: [
                        Shadow(
                          color: Colors.yellow,
                          offset: Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  // 顯示信心度
                  if (confidence != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "信心度 : ${(confidence * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // 原有的輸入區塊
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: cardHorizontalPadding, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("檢測單編號"),
                      value: 'orderId',
                      groupValue: inputMode,
                      onChanged: (val) => onInputModeChanged(val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("蜂場名稱"),
                      value: 'farmName',
                      groupValue: inputMode,
                      onChanged: (val) => onInputModeChanged(val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 將輸入欄位與按鈕改為直向排列
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inputMode == 'orderId'
                      ? TextFormField(
                          controller: orderIdController,
                          decoration: InputDecoration(
                            labelText: "檢測單編號",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.yellow[50],
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        )
                      : TextFormField(
                          controller: farmNameController,
                          decoration: InputDecoration(
                            labelText: "蜂場名稱",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.yellow[50],
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: applyCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "申請張數",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.yellow[50],
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload, color: Colors.black),
                    label: const Text(
                      "上傳結果",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final inputValue = inputMode == 'orderId'
                          ? orderIdController.text
                          : farmNameController.text;
                      final applyCountValue = applyCountController.text;
                      if (inputValue.trim().isEmpty) {
                        _showErrorDialog(
                          context,
                          inputMode == 'orderId' ? "請輸入檢測單編號" : "請輸入蜂場名稱",
                        );
                        return;
                      }
                      if (applyCountValue.trim().isEmpty) {
                        _showErrorDialog(
                          context,
                          "請輸入申請張數",
                        );
                        return;
                      }
                      final applyId = int.tryParse(inputValue) ?? 0;
                      final needLabel = int.tryParse(applyCountValue) ?? 0;
                      final apirayName =
                          inputMode == 'farmName' ? inputValue : null;

                      // 從 API 回應中取得 prediction 和 confidence
                      int prediction = 100; // 預設值
                      double confidence = 0.0; // 預設值
                      if (apiResponse != null && apiResponse!['result'] != null) {
                        final result = apiResponse!['result'];
                        prediction = result['prediction'] ?? 100;
                        confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
                      }

                      final success = await VideoAnalyzeController.submitLabel(
                        applyId: inputMode == 'orderId' ? applyId : 0,
                        needLabel: needLabel,
                        honeyType: honeyType,
                        apirayName: apirayName,
                        prediction: prediction, // 新增 prediction 參數
                        confidence: confidence, // 新增 confidence 參數
                      );
                      showDialog(
                        context: context,
                        builder: (context) => CustomDialog(
                          title: success ? "成功" : "失敗",
                          content: success
                              ? "• ${inputMode == 'orderId' ? '檢測單編號' : '蜂場名稱'}: $inputValue\n• 申請張數: $applyCountValue\n• 預測結果: $prediction% 蜂蜜\n• 信心度: ${(confidence * 100).toStringAsFixed(1)}%"
                              : "上傳失敗，請稍後再試",
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}