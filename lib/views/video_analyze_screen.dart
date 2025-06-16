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

  void _showLogDialog(BuildContext context, String log,
      {bool isLoading = false}) {
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

  Future<void> _startAnalysisWithLoading(
      BuildContext context, VideoAnalyzeController controller) async {
    if (_dialogOpen) return;
    _dialogOpen = true;

    if (controller.vc == null || controller.firstFrameBytes == null) {
      _showLogDialog(context, "請先上傳影片");
      _dialogOpen = false;
      return;
    }

    // 同步蜂蜜種類到控制器
    controller.setHoneyType(_selectedHoneyType);

    _progressListener = () {
      if (mounted) setState(() {});
      // 分析結束自動關閉 dialog
      if (!controller.isAnalyzing && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };

    controller.addListener(_progressListener!);

    // 1. 先啟動分析（傳入 context 參數）
    controller.startAnalysis(context);

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
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 16,
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "分析中",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.yellowAccent,
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      minHeight: 8,
                      backgroundColor: const Color(0xFFFFF9C4), // 淺黃色背景
                      color: Colors.yellow[700], // 黃色進度條
                      value: controller.progress ?? 0,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${((controller.progress ?? 0) * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF444444),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700]
                              ?.withAlpha((0.9 * 255).toInt()),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            controller.requestCancelAnalysis(context),
                        child: const Text(
                          "取消",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.removeListener(_progressListener!);
    _dialogOpen = false;

    // 3. 檢查分析是否正常完成並更新結果
    if (!controller.isCancelled && !controller.isAnalyzing) {
      // 使用延遲確保 API 回應已經處理完成
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        setState(() {
          // 只設定分析完成狀態，具體的 prediction 由 AnalyzeResultPanel 處理
          _analyzeResult = "分析完成";
        });
      }
    } else if (controller.isCancelled) {
      if (mounted) {
        setState(() {
          _analyzeResult = null;
        });
      }
    }
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
  final TextEditingController _applyCountController =
      TextEditingController(); // 新增

  // 新增：影片建立時間
  DateTime? _videoCreatedDate;

  Future<void> _showVideoDialog(
      BuildContext context, VideoAnalyzeController controller) async {
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
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
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 28),
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
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) {
                            return controller.firstFrameWithRectBytes != null
                                ? Image.memory(
                                    controller.firstFrameWithRectBytes!,
                                    fit: BoxFit.contain)
                                : (controller.firstFrameBytes != null
                                    ? Image.memory(controller.firstFrameBytes!,
                                        fit: BoxFit.contain)
                                    : const Text("請先上傳影片",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24)));
                          },
                        ),
                      ),
                    ),
                  ),
                  // 底部按鈕
                  SafeArea(
                    top: false,
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // 調整選取框
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.crop_square,
                                  color: Colors.black),
                              label: const Text(
                                "調整選取框",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 245, 222, 149), // 鵝黃色
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                await controller.adjustRect(context);
                                // 不需要手動 setState，因為使用了 AnimatedBuilder
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 開始分析
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow,
                                  color: Colors.black),
                              label: const Text(
                                "開始分析",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 245, 222, 149), // 鵝黃色
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                await _startAnalysisWithLoading(
                                    context, controller);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }

  // 新增：選擇日期時間的方法
  Future<void> _selectDateTime(
      BuildContext context, VideoAnalyzeController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _videoCreatedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'TW'),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_videoCreatedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _videoCreatedDate = finalDateTime;
        });
        controller.setVideoCreatedDate(finalDateTime);
      }
    }
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
                  Color.fromARGB(255, 200, 150, 70), // 更深的鵝黃色
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
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
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
                              color:
                                  Color.fromARGB(255, 238, 218, 145), // 鵝黃色陰影
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
                // ===== 上傳影片按鈕（固定在上方）=====
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: Colors.black),
                      label: const Text(
                        "上傳影片",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Color.fromARGB(255, 245, 222, 149), // 鵝黃色
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // 檢查是否選擇了蜂蜜種類
                        if (_selectedHoneyType == null ||
                            _selectedHoneyType!.isEmpty) {
                          _showLogDialog(context, "請選擇蜂蜜種類");
                          return;
                        }

                        // 檢查是否選擇了影片建立時間
                        if (_videoCreatedDate == null) {
                          _showLogDialog(context, "請選擇影片建立時間");
                          return;
                        }

                        // 重置分析結果
                        setState(() {
                          _analyzeResult = null;
                        });

                        // 同步蜂蜜種類和影片建立時間到控制器
                        controller.setHoneyType(_selectedHoneyType);
                        controller.setVideoCreatedDate(_videoCreatedDate);

                        await controller.pickVideo();
                        if (controller.firstFrameBytes != null) {
                          await _showVideoDialog(context, controller);
                        }
                      },
                    ),
                  ),
                ),
                // ===== 可滾動的主內容區塊 =====
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ===== 選項區塊（Card）移到可滾動區域 =====
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 12),
                              child: Column(
                                children: [
                                  // 蜂蜜種類
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("蜂蜜種類",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            DropdownButtonFormField<String>(
                                              value: _selectedHoneyType,
                                              items: _honeyTypes
                                                  .map((type) =>
                                                      DropdownMenuItem(
                                                        value: type,
                                                        child: Text(type),
                                                      ))
                                                  .toList(),
                                              onChanged: (val) {
                                                setState(() =>
                                                    _selectedHoneyType = val);
                                                // 立即同步到控制器
                                                controller.setHoneyType(val);
                                              },
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8),
                                              ),
                                              hint: const Text("請選擇"),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // 影片建立時間選擇
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("影片建立時間",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () => _selectDateTime(
                                            context, controller),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 16),
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _videoCreatedDate != null
                                                    ? "${_videoCreatedDate!.year}/${_videoCreatedDate!.month.toString().padLeft(2, '0')}/${_videoCreatedDate!.day.toString().padLeft(2, '0')} ${_videoCreatedDate!.hour.toString().padLeft(2, '0')}:${_videoCreatedDate!.minute.toString().padLeft(2, '0')}"
                                                    : "請選擇影片建立時間",
                                                style: TextStyle(
                                                  color:
                                                      _videoCreatedDate != null
                                                          ? Colors.black
                                                          : Colors.grey[600],
                                                ),
                                              ),
                                              Icon(Icons.calendar_today,
                                                  color: Colors.grey[600]),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 分析結果區塊
                        if (_analyzeResult != null)
                          AnalyzeResultPanel(
                            analyzeResult: _analyzeResult!,
                            inputMode: _inputMode,
                            orderIdController: _orderIdController,
                            farmNameController: _farmNameController,
                            applyCountController: _applyCountController,
                            onInputModeChanged: (mode) =>
                                setState(() => _inputMode = mode),
                            controller: controller,
                            honeyType: _selectedHoneyType ?? '',
                            apiResponse:
                                controller.analysisResult, // 新增：傳遞 API 回應
                          ),
                        if (_analyzeResult == null)
                          const SizedBox(
                            width: 500,
                            height: 200,
                            child: Center(
                              child: Text(
                                "請先上傳影片並分析",
                                style: TextStyle(
                                    fontSize: 32, color: Colors.black54),
                              ),
                            ),
                          ),
                        // 底部留白
                        const SizedBox(height: 24),
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
