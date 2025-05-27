import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/video_analyze_controller.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/analyze_result_panel.dart';

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
  bool _dialogOpen = false;
  VoidCallback? _progressListener;

  void _showLogDialog(BuildContext context, String log, {bool isLoading = false}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.3 * 255).toInt()),
      builder: (context) => CustomDialog(
        title: "訊息",
        content: log.isEmpty ? "暫無紀錄" : log,
        onClose: () => Navigator.of(context).pop(),
        isLoading: isLoading, // 新增參數
      ),
    );
  }

  Future<void> _startAnalysisWithLoading(BuildContext context, VideoAnalyzeController controller) async {
    if (_dialogOpen) return;
    _dialogOpen = true;

    if (controller.vc == null || controller.firstFrameBytes == null) {
      _showLogDialog(context, "請先上傳影片");
      _dialogOpen = false;
      return;
    }

    _progressListener = () {
      if (mounted) setState(() {});
      // 分析結束自動關閉 dialog
      if (!controller.isAnalyzing && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };

    controller.addListener(_progressListener!);

    // 1. 先啟動分析（不要 await，讓它在 dialog 顯示時進行）
    controller.startAnalysis();

    // 2. 顯示進度條 dialog，直到分析結束
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha((0.3 * 255).toInt()),
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // 只在分析時顯示
            if (!controller.isAnalyzing) return const SizedBox.shrink();
            return CustomDialog(
              title: "分析中",
              content: "${((controller.progress ?? 0) * 100).toStringAsFixed(0)}%",
              showProgressBar: true,
              progress: controller.progress ?? 0,
            );
          },
        );
      },
    );

    controller.removeListener(_progressListener!);
    _dialogOpen = false;

    // 3. 顯示結果區塊
    setState(() {
      // 這裡以「80%」蜂蜜為範例，實際可根據 controller 分析結果設定
      _analyzeResult = "80% 蜂蜜";
    });
  }

  // 新增選項相關狀態
  final List<String> _honeyTypes = ['龍眼蜜'];
  String? _selectedHoneyType;
  final TextEditingController _kbrController = TextEditingController();

  // 新增：分析結果與檢測單編號
  String? _analyzeResult;
  final TextEditingController _orderIdController = TextEditingController();

  // 新增：選擇輸入模式
  String _inputMode = 'orderId'; // 'orderId' or 'farmName'
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _applyCountController = TextEditingController(); // 新增

  Future<void> _showVideoDialog(BuildContext context, VideoAnalyzeController controller) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.7 * 255).toInt()),
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(context).size;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: Column(
              children: [
                // 標題列
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  color: Colors.black.withOpacity(0.7),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "影片預覽",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 內容顯示區
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: Center(
                      
                      child: controller.firstFrameWithRectBytes != null
                          ? Image.memory(controller.firstFrameWithRectBytes!, fit: BoxFit.contain)
                          : (controller.firstFrameBytes != null
                              ? Image.memory(controller.firstFrameBytes!, fit: BoxFit.contain)
                              : const Text("請先上傳影片", style: TextStyle(color: Colors.white, fontSize: 24))),
                    ),
                  ),
                ),
                // 底部按鈕
                SafeArea(
                  top: false,
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // 調整選取框
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
                              setState(() {}); // 更新預覽
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 開始分析
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
                              Navigator.of(dialogContext).pop();
                              await _startAnalysisWithLoading(context, controller);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _kbrController.dispose();
    _orderIdController.dispose();
    _farmNameController.dispose();
    _applyCountController.dispose(); // 新增
    super.dispose();
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
                colors: [
                  Color.fromARGB(255, 255, 235, 180), // 更淺的米色
                  Color.fromARGB(255, 200, 150, 70),  // 更深的鵝黃色
                ],
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
                              color: Color.fromARGB(255, 238, 218, 145), // 鵝黃色陰影
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ===== 只保留上傳影片按鈕 =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: Colors.black),
                      label: const Text(
                        "上傳影片",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 245, 222, 149), // 鵝黃色
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await controller.pickVideo();
                        if (controller.firstFrameBytes != null) {
                          await _showVideoDialog(context, controller);
                        }
                      },
                    ),
                  ),
                ),
                // ===== 選項區塊（Card）=====
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: 4,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Color.fromARGB(255, 242, 241, 241), // 米色
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Column(
                        children: [
                          // 只保留蜂蜜種類
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("蜂蜜種類", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      value: _selectedHoneyType,
                                      items: _honeyTypes
                                          .map((type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(type),
                                              ))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedHoneyType = val),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      hint: const Text("請選擇"),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ===== 主內容區塊（避免 overflow）=====
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        if (_analyzeResult != null)
                          AnalyzeResultPanel(
                            analyzeResult: _analyzeResult!,
                            inputMode: _inputMode,
                            orderIdController: _orderIdController,
                            farmNameController: _farmNameController,
                            applyCountController: _applyCountController, // 新增
                            onInputModeChanged: (mode) => setState(() => _inputMode = mode),
                            controller: controller,
                            honeyType: _selectedHoneyType ?? '',
                          ),
                        if (_analyzeResult == null)
                          const SizedBox(
                            width: 500,
                            height: 200,
                            child: Center(
                              child: Text(
                                "請先上傳影片並分析",
                                style: TextStyle(fontSize: 32, color: Colors.black54),
                              ),
                            ),
                          ),
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
