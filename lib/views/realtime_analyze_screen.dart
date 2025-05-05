import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/realtime_analyze_controller.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import '../views/full_screen_select_screen.dart';
import '../widgets/analyze_result_panel.dart';

/// 即時分析畫面入口元件
class RealtimeAnalyzeScreen extends StatelessWidget {
  const RealtimeAnalyzeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RealtimeAnalyzeController(),
      child: const _RealtimeAnalyzeView(),
    );
  }
}

class _RealtimeAnalyzeView extends StatefulWidget {
  const _RealtimeAnalyzeView();

  @override
  State<_RealtimeAnalyzeView> createState() => _RealtimeAnalyzeViewState();
}

class _RealtimeAnalyzeViewState extends State<_RealtimeAnalyzeView> {
  final List<String> _intervalOptions = ['0.1', '0.2', '0.5', '1', '2', '5'];
  String _selectedInterval = '1';

  final List<String> _honeyTypes = ['龍眼蜜', '荔枝蜜', '百花蜜', '其他'];
  String? _selectedHoneyType;
  DateTime? _nanoSilverDate;
  final TextEditingController _kbrController = TextEditingController();

  // 新增：分析結果與檢測單編號/蜂場名稱
  String? _analyzeResult;
  String _inputMode = 'orderId'; // 'orderId' or 'farmName'
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();

  /// 選擇奈米銀製備日期
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
    _orderIdController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  // 新增：分析完成後呼叫此方法
  void _onAnalyzeFinished() {
    setState(() {
      _analyzeResult = "80% 蜂蜜"; // 範例
    });
  }

  /// 顯示全屏拍攝預覽對話框
  void _showCapturePreview(BuildContext context, RealtimeAnalyzeController controller) {
    final screenSize = MediaQuery.of(context).size;

    // 先顯示 Dialog，再初始化相機
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (dialogContext) {
        // 啟動相機初始化（只會執行一次）
        controller.initCamera();

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: Column(
              children: [
                // 頂部控制欄
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
                          "拍攝視窗",
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        // RGB 顯示區域
                        if (controller.lastRGB != null)
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, controller.lastRGB![0],
                                      controller.lastRGB![1], controller.lastRGB![2]),
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "R: ${controller.lastRGB![0]}, G: ${controller.lastRGB![1]}, B: ${controller.lastRGB![2]}",
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () {
                            controller.stopCamera(); // 關閉對話框時停止相機
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 影像顯示區域，使用 AnimatedBuilder 監聽控制器變化
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        // 若尚未初始化相機，顯示 loading
                        if (!controller.isCameraInitialized) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // 顯示前一幀作為背景
                            if (controller.previousFrameBytes != null && !controller.isAnalyzing)
                              Image.memory(
                                controller.previousFrameBytes!,
                                fit: BoxFit.contain,
                              ),
                            // 顯示當前幀
                            if (controller.currentFrameBytes != null)
                              Image.memory(
                                controller.currentFrameBytes!,
                                fit: BoxFit.contain,
                              ),
                            // 沒有幀可顯示時的提示
                            if (controller.currentFrameBytes == null && controller.previousFrameBytes == null)
                              const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // 底部按鈕區域
                SafeArea(
                  top: false,
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // 自動選取按鈕
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.auto_fix_high, color: Colors.black),
                            label: const Text(
                              "自動選取",
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
                              await controller.autoSelectRect();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 調整選取框按鈕 - 修改為使用 FullScreenSelect
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
                              // 暫停預覽
                              bool wasAnalyzing = controller.isAnalyzing;
                              if (wasAnalyzing) controller.stopAnalyze();
                              
                              if (controller.lastRawFrameBytes == null) return;
                              
                              // 轉換 cv.Rect 為 Flutter 的 Rect 用於初始選取框
                              Rect? initialRect;
                              if (controller.selectedRect != null) {
                                initialRect = Rect.fromLTWH(
                                  controller.selectedRect!.x.toDouble(),
                                  controller.selectedRect!.y.toDouble(),
                                  controller.selectedRect!.width.toDouble(),
                                  controller.selectedRect!.height.toDouble(),
                                );
                              }
                              
                              // 獲取原始影像尺寸用於比例計算
                              final rawImage = cv.imdecode(controller.lastRawFrameBytes!, cv.IMREAD_COLOR);
                              int imageWidth = rawImage.cols;
                              int imageHeight = rawImage.rows;
                              rawImage.dispose();
                              
                              final rect = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenSelect(
                                    imageBytes: controller.lastRawFrameBytes!,
                                    initialRect: initialRect,
                                    imageWidth: imageWidth,
                                    imageHeight: imageHeight,
                                  ),
                                ),
                              );
                              
                              if (rect is cv.Rect) {
                                controller.setSelectedRect(rect);
                              }
                              
                              // 如果之前在分析，恢復分析
                              if (wasAnalyzing) controller.startAnalyze();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 開始/停止分析按鈕
                        Expanded(
                          child: AnimatedBuilder(
                            animation: controller,
                            builder: (context, _) {
                              return ElevatedButton.icon(
                                icon: controller.isAnalyzing
                                    ? const Icon(Icons.stop, color: Colors.black)
                                    : const Icon(Icons.play_arrow, color: Colors.black),
                                label: Text(
                                  controller.isAnalyzing ? "停止分析" : "開始分析",
                                  style: const TextStyle(color: Colors.black, fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow[700],
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (controller.isAnalyzing) {
                                    controller.stopAnalyze();
                                    _onAnalyzeFinished(); // 停止分析時顯示結果
                                    Navigator.of(dialogContext).pop();
                                  } else {
                                    controller.startAnalyze();
                                  }
                                },
                              );
                            }
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
  Widget build(BuildContext context) {
    final controller = context.watch<RealtimeAnalyzeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 背景漸層
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF176), Color(0xFFFFF9C4)],
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
                        "即時影像分析",
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
                const SizedBox(height: 8),
                // ===== 新增：顯示拍攝視窗按鈕 =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
                  child: SizedBox(
                    width: double.infinity, // 設置按鈕寬度與上方按鈕等寬
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, color: Colors.black),
                      label: const Text(
                        "顯示拍攝視窗",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[600],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showCapturePreview(context, controller),
                    ),
                  ),
                ),
                // ===== 蜂蜜種類等選項區塊（含拍攝間隔） =====
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
                          const SizedBox(height: 12),
                          // 拍攝間隔
                          Row(
                            children: [
                              const Text("拍攝間隔", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                value: _selectedInterval,
                                items: _intervalOptions
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text("$s 秒"),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedInterval = val;
                                    });
                                    controller.setIntervalMs((double.parse(val) * 1000).toInt());
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ===== 分析結果與輸入區塊 =====
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ===== 新增：分析結果顯示區塊 =====
                        if (_analyzeResult != null)
                          AnalyzeResultPanel(
                            analyzeResult: _analyzeResult!,
                            inputMode: _inputMode,
                            orderIdController: _orderIdController,
                            farmNameController: _farmNameController,
                            onInputModeChanged: (mode) => setState(() => _inputMode = mode),
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

/// 選取框繪製器
class SelectRectPainter extends CustomPainter {
  final cv.Rect rect;
  final Size imageSize;

  SelectRectPainter({required this.rect, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    canvas.drawRect(
      Rect.fromLTWH(
        rect.x.toDouble(), 
        rect.y.toDouble(), 
        rect.width.toDouble(), 
        rect.height.toDouble()
      ),
      paint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
