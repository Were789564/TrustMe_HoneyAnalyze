import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  String? lastCCMTime;
  Matrix? lastCCM;

  /// 自動偵測矩形並取得每個色塊的平均顏色
  /// 
  /// 輸入：
  ///   [inputMat] : cv.Mat，輸入的彩色影像
  /// 輸出：
  ///   (cv.Mat 處理後影像, List<List<double>> 色塊平均顏色, String log)
  ///   - 處理後影像（已畫出偵測到的矩形）
  ///   - 色塊平均顏色（每個色塊的 [R, G, B]）
  ///   - 偵測過程的日誌字串
  // Future<(cv.Mat, List<List<double>>, String)> detectRectanglesAndColorsAsync(cv.Mat inputMat) async {
  //   final outputMat = inputMat.clone();
  //   final StringBuffer logBuffer = StringBuffer();
  //   final gray = await cv.cvtColorAsync(inputMat, cv.COLOR_BGR2GRAY);
  //   final blurred = await cv.gaussianBlurAsync(gray, (5, 5), 0, sigmaY: 0);
  //   final thresholded = await cv.cannyAsync(blurred, 70, 100);
  //   final contours = await cv.findContoursAsync(thresholded, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);

  //   int rectangleCount = 0;
  //   List<cv.Rect> rects = [];
  //   List<List<double>> colors = [];

  //   for (var i = 0; i < contours.$1.length; i++) {
  //     final contour = contours.$1.elementAt(i);
  //     final peri = cv.arcLength(contour, true);
  //     final approx = cv.approxPolyDP(contour, 0.03 * peri, true);

  //     if (approx.length == 4) {
  //       final area = cv.contourArea(contour);
  //       const minArea = 100.0;
  //       final isConvex = cv.isContourConvex(approx);

  //       if (area > minArea && isConvex) {
  //         final rect = cv.boundingRect(approx);
  //         // 過濾重複
  //         bool isDuplicate = rects.any((r) =>
  //           (rect.x - r.x).abs() < 5 &&
  //           (rect.y - r.y).abs() < 5 &&
  //           (rect.width - r.width).abs() < 10 &&
  //           (rect.height - r.height).abs() < 10
  //         );
  //         if (!isDuplicate) {
  //           rectangleCount++;
  //           rects.add(rect);
  //           cv.rectangle(outputMat, rect, cv.Scalar(0, 255, 0, 255), thickness: 2);
  //           // 取得色塊平均顏色 (R, G, B)
  //           final roi = inputMat.region(rect);
  //           final meanColor = cv.mean(roi);
  //           roi.dispose();
  //           colors.add([meanColor.val3, meanColor.val2, meanColor.val1]);
  //         }
  //       }
  //     }
  //     approx.dispose();
  //   }

  //   colors = colors.reversed.toList(); // 反轉順序
  //   logBuffer.writeln("偵測到 $rectangleCount 個矩形。");
  //   gray.dispose();
  //   blurred.dispose();
  //   thresholded.dispose();
  //   contours.$1.dispose();

  //   return (outputMat, colors, logBuffer.toString());
  // }

  /// 自動偵測矩形並取得每個色塊的平均顏色（參考 test_canny.py 流程與排序）
/// 輸入：cv.Mat 彩色影像
/// 輸出：(處理後影像, 色塊平均顏色, log)
  Future<(cv.Mat, List<List<double>>, String)> detectRectanglesAndColorsAsync(cv.Mat inputMat) async {
    final outputMat = inputMat.clone();
    final StringBuffer logBuffer = StringBuffer();

    // Step 1: 灰階
    final gray = await cv.cvtColorAsync(inputMat, cv.COLOR_BGR2GRAY);

    // Step 2: CLAHE 增強
    final clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
    final enhanced = await clahe.applyAsync(gray);

    // Step 2.5: 高斯模糊降噪
    final blurred = await cv.gaussianBlurAsync(enhanced, (5, 5), 0, sigmaY: 0);

    // Step 3: Canny 邊緣偵測
    final canny = await cv.cannyAsync(blurred, 50, 100);

    // Step 4: 閉運算
    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (9, 9));
    final closed = await cv.morphologyExAsync(canny, cv.MORPH_CLOSE, kernel);

    // Step 5: 找輪廓
    final contours = await cv.findContoursAsync(closed, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

    // Step 6: 過濾輪廓並找矩形
    List<cv.Rect> detectedRects = [];
    int rectangleCount = 0;
    List<String> logLines = [];
    const minArea = 1000.0;

    for (var i = 0; i < contours.$1.length; i++) {
      final contour = contours.$1.elementAt(i);
      final peri = cv.arcLength(contour, true);
      final approx = cv.approxPolyDP(contour, 0.04 * peri, true);
      if (approx.length >= 4 && approx.length <= 6) {
        final area = cv.contourArea(contour);
        final isConvex = cv.isContourConvex(approx);
        if (area > minArea && isConvex) {
          final rect = cv.boundingRect(approx);
          // 過濾重複
          bool isDuplicate = detectedRects.any((r) =>
            (rect.x - r.x).abs() < 15 &&
            (rect.y - r.y).abs() < 15 &&
            (rect.width - r.width).abs() < 20 &&
            (rect.height - r.height).abs() < 20
          );
          if (!isDuplicate) {
            rectangleCount++;
            detectedRects.add(rect);
            logLines.add("Detected Rectangle #$rectangleCount: [x:${rect.x}, y:${rect.y}, w:${rect.width}, h:${rect.height}], Area:$area");
          }
        }
      }
      approx.dispose();
    }

    // Step 7: 依 y,x 排序並分群（行），縮框
    detectedRects.sort((a, b) {
      int dy = a.y.compareTo(b.y);
      return dy != 0 ? dy : a.x.compareTo(b.x);
    });

    // 分群組（行）：把 y 差異在 verticalThresh 的視為同一行
    const verticalThresh = 20;
    const shrinkRatio = 0.85;
    List<List<cv.Rect>> rows = [];
    List<cv.Rect> currentRow = [];
    for (final rect in detectedRects) {
      if (currentRow.isEmpty) {
        currentRow.add(rect);
      } else {
        if ((rect.y - currentRow[0].y).abs() < verticalThresh) {
          currentRow.add(rect);
        } else {
          rows.add(List.from(currentRow)..sort((a, b) => a.x.compareTo(b.x)));
          currentRow = [rect];
        }
      }
    }
    if (currentRow.isNotEmpty) {
      rows.add(List.from(currentRow)..sort((a, b) => a.x.compareTo(b.x)));
    }

    // 依序重新編號、縮框、計算平均顏色
    List<List<double>> colors = [];
    int newCount = 1;
    for (final row in rows) {
      for (final rect in row) {
        // 框框往內縮
        int shrinkW = (rect.width * shrinkRatio).toInt();
        int shrinkH = (rect.height * shrinkRatio).toInt();
        int offsetX = ((rect.width - shrinkW) / 2).round();
        int offsetY = ((rect.height - shrinkH) / 2).round();
        int xNew = rect.x + offsetX;
        int yNew = rect.y + offsetY;
        int wNew = shrinkW;
        int hNew = shrinkH;

        // 防呆邊界
        xNew = xNew.clamp(0, inputMat.cols - 1);
        yNew = yNew.clamp(0, inputMat.rows - 1);
        wNew = (xNew + wNew > inputMat.cols) ? (inputMat.cols - xNew) : wNew;
        hNew = (yNew + hNew > inputMat.rows) ? (inputMat.rows - yNew) : hNew;

        final roi = inputMat.region(cv.Rect(xNew, yNew, wNew, hNew));
        final meanColor = cv.mean(roi);
        roi.dispose();
        // OpenCV: BGR, 這裡轉成 [R, G, B]
        colors.add([meanColor.val3, meanColor.val2, meanColor.val1]);
        logBuffer.writeln(
          "Sorted Rectangle #$newCount: [x:$xNew, y:$yNew, w:$wNew, h:$hNew], AvgColor(RGB): [${meanColor.val3.toStringAsFixed(2)}, ${meanColor.val2.toStringAsFixed(2)}, ${meanColor.val1.toStringAsFixed(2)}]"
        );
        // 畫框與編號
        cv.rectangle(outputMat, cv.Rect(xNew, yNew, wNew, hNew), cv.Scalar(255, 0, 0, 255), thickness: 2);
        // 若有 putText 可用，可加上編號
        newCount++;
      }
    }

    logBuffer.writeln("共偵測到 ${colors.length} 個色塊。");

    // 資源釋放
    gray.dispose();
    enhanced.dispose();
    blurred.dispose();
    canny.dispose();
    closed.dispose();
    contours.$1.dispose();
    kernel.dispose();

    return (outputMat, colors, logBuffer.toString());
  }

  /// 載入圖片並自動偵測色塊
  /// 
  /// 輸入：
  ///   [path]: String，圖片檔案路徑
  /// 輸出：
  ///   無（直接更新畫面狀態，包括原圖、處理後圖、色塊顏色、log）
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
  /// 
  /// 輸入：無（直接取用 detectedColors 狀態）
  /// 輸出：無（結果顯示於 processingLog 狀態）
  /// 流程：
  ///   1. 若色塊數不足18，顯示提示
  ///   2. 計算 OLS CCM 與誤差
  ///   3. 將 CCM 與誤差格式化後寫入 processingLog
  void buildCCM() {
    if (detectedColors.length != 18) {
      setState(() {
        processingLog += "\n請先偵測並取得18個色塊顏色！";
      });
      return;
    }

    // 標準色卡的RGB值
    List<List<double>> standardColors = [
      [115, 82, 68],   // 1. dark skin    
      [194, 150, 130], // 2. light skin
      [98, 122, 157],  // 3. blue sky
      [87, 108, 67],   // 4. foliage
      [133, 128, 177], // 5. blue flower
      [103, 189, 170], // 6. bluish green
      [214, 126, 44],  // 7. orange
      [80, 91, 166],   // 8. purplish blue
      [193, 90, 99],   // 9. moderate red
      [94, 60, 108],   // 10. purple
      [157, 188, 64],  // 11. yellow green
      [224, 163, 46],  // 12. orange yellow
      [56, 61, 150],   // 13. blue
      [70, 148, 73],   // 14. green
      [175, 54, 60],   // 15. red
      [231, 199, 31],  // 16. yellow
      [187, 86, 149],  // 17. magenta
      [8, 133, 161],   // 18. cyan
    ];

    final controller = CCMCalculator();
    final deviceRGB = Matrix.fromList(detectedColors);
    final targetRGB = Matrix.fromList(standardColors);

    final results = controller.calculateCCMs(deviceRGB, targetRGB);
    final olsCCM = results['olsCCM'];
    final olsError = results['olsError'];

    setState(() {
      processingLog += "\n=== OLS CCM ===\n${formatMatrix(olsCCM)}";
      processingLog += "\n=== OLS Error ===\n${formatMatrix(olsError)}";
    });
    // 新增：儲存 CCM
    if (olsCCM != null) {
      saveCCMToJson(olsCCM);
    }
  }

  /// 將矩陣格式化為字串
  /// 
  /// 輸入：[matrix]：Matrix?，要格式化的矩陣
  /// 輸出：String，格式化後的多行字串
  String formatMatrix(Matrix? matrix) {
    if (matrix == null) return 'N/A';
    return matrix.rows
        .map((row) => row.map((e) => e.toStringAsFixed(4)).join(', '))
        .join('\n');
  }

  // 儲存 CCM 到 JSON
  Future<void> saveCCMToJson(Matrix ccm) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // 確保資料夾存在
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File('${directory.path}/ccm_result.json');
      final now = DateTime.now();
      final data = {
        'time': now.toIso8601String(),
        'ccm': ccm.rows.map((row) => row.toList()).toList(), // 這裡做轉換
      };
      await file.writeAsString(jsonEncode(data));
      setState(() {
        lastCCMTime = now.toString();
        lastCCM = ccm;
        processingLog += "\nCCM 已儲存於 ${file.path}";
      });
    } catch (e) {
      setState(() {
        print("儲存 CCM 失敗: $e");
        processingLog += "\nCCM 儲存失敗: $e";
      });
    }
  }
  // 讀取 CCM 從 JSON
  Future<void> loadCCMFromJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ccm_result.json');
      if (!await file.exists()) {
        setState(() {
          processingLog += "\n找不到 CCM 檔案";
        });
        return;
      }
      final content = await file.readAsString();
      final data = jsonDecode(content);
      final ccmRows = (data['ccm'] as List).map<List<double>>((row) => (row as List).map((e) => (e as num).toDouble()).toList()).toList();
      final ccmMatrix = Matrix.fromList(ccmRows);
      setState(() {
        lastCCMTime = data['time'];
        lastCCM = ccmMatrix;
        processingLog += "\n已讀取 CCM（時間：${lastCCMTime ?? ''}）\n${formatMatrix(ccmMatrix)}";
      });
    } catch (e) {
      setState(() {
        processingLog += "\n讀取 CCM 失敗: $e";
      });
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: loadCCMFromJson,
                    child: const Text("讀取CCM"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        originalImageBytes = null;
                        processedImageBytes = null;
                        detectedColors.clear();
                        processingLog = "";
                      });
                    },
                    child: const Text("清除"),
                  ),
                ],

              ),
              if (lastCCMTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("上次CCM時間: $lastCCMTime", style: const TextStyle(color: Colors.green)),
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