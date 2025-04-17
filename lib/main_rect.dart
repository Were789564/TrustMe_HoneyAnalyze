import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:image_picker/image_picker.dart';
import 'package:ml_linalg/linalg.dart';
import 'ccm_screen.dart'; // 匯入CCMController

class MainRectPage extends StatefulWidget {
  const MainRectPage({super.key});

  @override
  State<MainRectPage> createState() => _MyAppState();
}

class _MyAppState extends State<MainRectPage> {
  Uint8List? originalImageBytes;
  Uint8List? processedImageBytes;
  String processingLog = "";
  List<List<double>> detectedColors = []; // 存放自動偵測到的色塊平均顏色

  /// 自動偵測矩形並取得每個色塊的平均顏色
  /// [inputMat] : cv.Mat 輸入影像
  /// return: (cv.Mat 處理後影像, List<List<double>> 色塊平均顏色, String log)
  Future<(cv.Mat, List<List<double>>, String)> detectRectanglesAndColorsAsync(cv.Mat inputMat) async {
    final outputMat = inputMat.clone();
    final StringBuffer logBuffer = StringBuffer();
    final gray = await cv.cvtColorAsync(inputMat, cv.COLOR_BGR2GRAY);
    final blurred = await cv.gaussianBlurAsync(gray, (5, 5), 0, sigmaY: 0);
    final thresholded = await cv.cannyAsync(blurred, 70, 100);
    final contours = await cv.findContoursAsync(thresholded, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);

    int rectangleCount = 0;
    List<cv.Rect> rects = [];
    List<List<double>> colors = [];

    for (var i = 0; i < contours.$1.length; i++) {
      final contour = contours.$1.elementAt(i);
      final peri = cv.arcLength(contour, true);
      final approx = cv.approxPolyDP(contour, 0.03 * peri, true);

      if (approx.length == 4) {
        final area = cv.contourArea(contour);
        const minArea = 100.0;
        final isConvex = cv.isContourConvex(approx);

        if (area > minArea && isConvex) {
          final rect = cv.boundingRect(approx);
          // 過濾重複
          bool isDuplicate = rects.any((r) =>
            (rect.x - r.x).abs() < 5 &&
            (rect.y - r.y).abs() < 5 &&
            (rect.width - r.width).abs() < 10 &&
            (rect.height - r.height).abs() < 10
          );
          if (!isDuplicate) {
            rectangleCount++;
            rects.add(rect);
            cv.rectangle(outputMat, rect, cv.Scalar(0, 255, 0, 255), thickness: 2);
            // 取得色塊平均顏色 (R, G, B)
            final roi = inputMat.region(rect);
            final meanColor = cv.mean(roi);
            roi.dispose();
            colors.add([meanColor.val3, meanColor.val2, meanColor.val1]);
          }
        }
      }
      approx.dispose();
    }

    colors = colors.reversed.toList(); // 反轉順序
    logBuffer.writeln("偵測到 $rectangleCount 個矩形。");
    gray.dispose();
    blurred.dispose();
    thresholded.dispose();
    contours.$1.dispose();

    return (outputMat, colors, logBuffer.toString());
  }

  /// 載入圖片並自動偵測色塊
  /// [path]: String 圖片路徑
  /// 無回傳值，會更新狀態
  Future<void> processImageFromPath(String path) async {
    setState(() {
      processingLog = "Loading image...";
      originalImageBytes = null;
      processedImageBytes = null;
      detectedColors.clear();
    });

    try {
      final mat = cv.imread(path, flags: cv.IMREAD_COLOR);
      if (mat.isEmpty) {
        setState(() => processingLog = "Error: Could not read image from path: $path");
        return;
      }
      final originalBytes = cv.imencode(".png", mat).$2;
      final (resultMat, colors, log) = await detectRectanglesAndColorsAsync(mat);
      final selectedColors = colors.length > 18 ? colors.sublist(0, 18) : colors;

      setState(() {
        originalImageBytes = originalBytes;
        processedImageBytes = cv.imencode(".png", resultMat).$2;
        processingLog = log + "\n已自動取得色塊顏色";
        detectedColors = selectedColors;
      });

      mat.dispose();
      resultMat.dispose();
    } catch (e) {
      setState(() => processingLog = "Error processing image: $e");
    }
  }

  /// 建立CCM，直接用 detectedColors 陣列與標準色卡值，並顯示在log
  /// 無輸入，無回傳，結果顯示於 processingLog
  void buildCCM() {
    if (detectedColors.length != 18) {
      setState(() {
        processingLog += "\n請先偵測並取得18個色塊顏色！";
      });
      return;
    }

    // 標準色卡的RGB值（請依實際色卡順序填寫）
    List<List<double>> standardColors = [
      [115, 82, 68], [194, 150, 130], [98, 122, 157], [87, 108, 67], [133, 128, 177], [103, 189, 170],
      [214, 126, 44], [80, 91, 166], [193, 90, 99], [94, 60, 108], [157, 188, 64], [224, 163, 46],
      [56, 61, 150], [70, 148, 73], [175, 54, 60], [231, 199, 31], [187, 86, 149], [8, 133, 161]
    ];

    final controller = CCMCalculator();
    final deviceRGB = Matrix.fromList(detectedColors);
    final targetRGB = Matrix.fromList(standardColors);

    final results = controller.calculateCCMs(deviceRGB, targetRGB);
    final olsCCM = results['olsCCM'];
    final olsError = results['olsError'];

    // 格式化矩陣
    String formatMatrix(Matrix? matrix) {
      if (matrix == null) return 'N/A';
      return matrix.rows
          .map((row) => row.map((e) => e.toStringAsFixed(4)).join(', '))
          .join('\n');
    }

    setState(() {
      processingLog += "\n=== OLS CCM ===\n${formatMatrix(olsCCM)}";
      processingLog += "\n=== OLS Error ===\n${formatMatrix(olsError)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Rectangle Detection Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        await processImageFromPath(img.path);
                      }
                    },
                    child: const Text("Pick & Process Image"),
                  ),
                  ElevatedButton(
                    onPressed: buildCCM,
                    child: const Text("建立CCM"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 原圖
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Original", style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          if (originalImageBytes != null)
                            Image.memory(originalImageBytes!, fit: BoxFit.contain)
                          else
                            const Center(child: Text("No image loaded")),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 10, thickness: 1),
                    // 處理後圖
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Processed", style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          if (processedImageBytes != null)
                            Image.memory(processedImageBytes!, fit: BoxFit.contain)
                          else
                            const Center(child: Text("No image processed")),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 10, thickness: 1),
              const Text("Processing Log / Results", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Text(processingLog.isEmpty ? "Logs will appear here..." : processingLog),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}