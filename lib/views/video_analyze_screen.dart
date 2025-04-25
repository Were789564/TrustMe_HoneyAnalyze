import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/video_analyze_controller.dart';
import '../widgets/custom_dialog.dart';

class VideoAnalyzeScreen extends StatelessWidget {
  const VideoAnalyzeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoAnalyzeController(),
      child: const _VideoAnalyzeView(),
    );
  }
}

class _VideoAnalyzeView extends StatefulWidget {
  const _VideoAnalyzeView();

  @override
  State<_VideoAnalyzeView> createState() => _VideoAnalyzeViewState();
}

class _VideoAnalyzeViewState extends State<_VideoAnalyzeView> {
  void _showLogDialog(BuildContext context, String log, {bool isLoading = false}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => CustomDialog(
        title: "訊息",
        content: log.isEmpty ? "暫無紀錄" : log,
        onClose: () => Navigator.of(context).pop(),
        isLoading: isLoading, // 新增參數
      ),
    );
  }

  Future<void> _startAnalysisWithLoading(BuildContext context, VideoAnalyzeController controller) async {
    // 1. 先顯示 loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => const CustomDialog(
        title: "分析中",
        content: "",
        isLoading: true,
      ),
    );
    // 2. 執行分析
    await controller.startAnalysis();
    // 3. 關閉 loading dialog
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // 4. 顯示結果 dialog
    if (controller.rgbLog.isNotEmpty) {
      _showLogDialog(context, controller.rgbLog);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VideoAnalyzeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 背景漸層
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF176), Color(0xFFFFF9C4)], // 黃色系
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar 樣式
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "影片分析",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: Colors.yellow,
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                // 三個按鈕
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file, color: Colors.black),
                          label: const Text(
                            "上傳影片",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await controller.pickVideo();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.crop_square, color: Colors.black),
                          label: const Text(
                            "調整選取框",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await controller.adjustRect(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow, color: Colors.black),
                          label: const Text(
                            "開始分析",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await _startAnalysisWithLoading(context, controller);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // 內容區塊避免 overflow
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 顯示第一幀
                        if (controller.firstFrameBytes != null)
                          Column(
                            children: [
                              controller.firstFrameWithRectBytes != null
                                  ? Image.memory(controller.firstFrameWithRectBytes!,
                                      width: 300, fit: BoxFit.contain)
                                  : Image.memory(controller.firstFrameBytes!,
                                      width: 300, fit: BoxFit.contain),
                              const SizedBox(height: 5),
                            ],
                          )
                        else
                          // 修改這裡：顯示提示文字
                          const SizedBox(
                            width: 500,
                            height: 200,
                            child: Center(
                              child: Text(
                                "請先上傳影片",
                                style: TextStyle(fontSize: 50, color: Colors.black54),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        // 顯示分析結果
                        controller.currentFrameBytes != null
                            ? Image.memory(controller.currentFrameBytes!,
                                width: 300, fit: BoxFit.contain)
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
