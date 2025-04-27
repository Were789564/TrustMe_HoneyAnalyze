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

    // 3. 顯示結果 dialog
    if (controller.rgbLog.isNotEmpty) {
      _showLogDialog(context, controller.rgbLog);
    }
  }

  // 新增選項相關狀態
  final List<String> _honeyTypes = ['龍眼蜜', '荔枝蜜', '百花蜜', '其他'];
  String? _selectedHoneyType;
  DateTime? _nanoSilverDate;
  final TextEditingController _kbrController = TextEditingController();

  // 日期選擇器
  Future<void> _pickNanoSilverDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nanoSilverDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'TW'),
    );
    if (picked != null) {
      setState(() {
        _nanoSilverDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _kbrController.dispose();
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
                // ===== 按鈕區塊 =====
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
                // ===== 新增選項區塊（Card）移到這裡 =====
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: 4,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.yellow[50],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // 蜂蜜種類
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // 奈米銀日期
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("奈米製備日期", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _pickNanoSilverDate(context),
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            hintText: "選擇日期",
                                            suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                          ),
                                          controller: TextEditingController(
                                            text: _nanoSilverDate == null
                                                ? ''
                                                : "${_nanoSilverDate!.year}-${_nanoSilverDate!.month.toString().padLeft(2, '0')}-${_nanoSilverDate!.day.toString().padLeft(2, '0')}",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // KBr濃度
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("KBr濃度", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _kbrController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        hintText: "mg/mL",
                                      ),
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
                // ===== 選項區塊結束 =====
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
                                      width: 200, fit: BoxFit.contain)
                                  : Image.memory(controller.firstFrameBytes!,
                                      width: 200, fit: BoxFit.contain),
                              const SizedBox(height: 5),
                            ],
                          )
                        else
                          // 顯示提示文字
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
