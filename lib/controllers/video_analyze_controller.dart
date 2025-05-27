import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../views/full_screen_select_screen.dart';
import '../constants/api_constants.dart';

/// 影片分析控制器，負責處理影片讀取和分析
class VideoAnalyzeController extends ChangeNotifier {
  int width = -1;
  int height = -1;
  double fps = -1;
  String backend = "unknown";
  String? src;
  cv.VideoCapture? vc;
  Uint8List? firstFrameBytes;
  Uint8List? firstFrameWithRectBytes;
  int firstFrameWidth = -1;
  int firstFrameHeight = -1;
  Uint8List? currentFrameBytes;
  cv.Rect? selectedRect;
  String rgbLog = "";
  double? progress;
  bool isAnalyzing = false;
  bool _disposed = false;

  static final _storage = const FlutterSecureStorage();

  /// 選擇影片檔案並擷取第一幀
  /// 選擇影片檔案並擷取第一幀
  Future<void> pickVideo() async {
    rgbLog = "";
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      final file = result.files.single;
      final path = file.path;
      if (path != null) {
        cv.VideoCapture? vc = cv.VideoCapture.empty();
        await vc.openAsync(path);
        if (!(vc.isOpened)) {
          rgbLog = "Error: Could not open video file $path";
          this.vc = null;
          safeNotifyListeners();
          return;
        }

        final (success, frame) = await vc.readAsync();
        if (success && !frame.isEmpty) {
          // 先取得原始 Mat
          cv.Mat firstFrameMat = frame.clone();
          // 如果寬大於高，旋轉90度
          if (firstFrameMat.cols > firstFrameMat.rows) {
            final rotatedMat = cv.rotate(firstFrameMat, cv.ROTATE_90_CLOCKWISE);
            firstFrameMat.dispose();
            firstFrameMat = rotatedMat;
          }
          firstFrameWidth = firstFrameMat.cols;
          firstFrameHeight = firstFrameMat.rows;
          // 重新編碼旋轉後的圖片
          this.firstFrameBytes = cv.imencode(".png", firstFrameMat).$2;
          firstFrameWithRectBytes = null;
          firstFrameMat.dispose();
          frame.dispose();
          await autoCrop(); // 這裡會用旋轉後的 firstFrameBytes
        } else {
          rgbLog += "無法擷取第一幀\n";
        }

        src = path;
        width = vc.get(cv.CAP_PROP_FRAME_WIDTH).toInt();
        height = vc.get(cv.CAP_PROP_FRAME_HEIGHT).toInt();
        fps = vc.get(cv.CAP_PROP_FPS);
        this.vc = vc;
        safeNotifyListeners();
      }
    }
  }

  /// 設定選取的矩形區域
  void setSelectedRect(cv.Rect rect) {
    selectedRect = rect;
    drawRectangleOnFirstFrame();
    safeNotifyListeners();
  }

  /// 在第一幀影像上畫出選取的矩形
  void drawRectangleOnFirstFrame() {
    if (firstFrameBytes != null && selectedRect != null) {
      final firstFrameMat = cv.imdecode(firstFrameBytes!, cv.IMREAD_COLOR);
      if (!firstFrameMat.isEmpty) {
        cv.rectangle(
          firstFrameMat,
          selectedRect!,
          cv.Scalar(0, 255, 0, 255),
          thickness: 2,
        );
        final encodedImage = cv.imencode(".png", firstFrameMat).$2;
        firstFrameWithRectBytes = encodedImage;
        firstFrameMat.dispose();
      }
    }
  }

  /// 分析整段影片的 RGB 平均值（每秒一幀）
  /// 分析整段影片的 RGB 平均值（每秒一幀）
  Future<void> startAnalysis() async {
    rgbLog = "";
    progress = 0.0;
    isAnalyzing = true;
    safeNotifyListeners();

    if (_disposed) return;

    if (vc == null || selectedRect == null) {
      rgbLog = "請先選擇影片並指定矩形區域\n";
      progress = null;
      isAnalyzing = false;
      safeNotifyListeners();
      return;
    }

    final rect = selectedRect!;
    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;
    List<Map<String, dynamic>> secondBySecondData = []; // 改為 Map 格式

    vc!.set(cv.CAP_PROP_POS_FRAMES, 0);
    final int totalFrames = vc!.get(cv.CAP_PROP_FRAME_COUNT).toInt();
    final double videoFps = vc!.get(cv.CAP_PROP_FPS);

    final int frameStep = videoFps.round();
    int currentFrame = 0;
    int secondCount = 0;

    while (currentFrame < totalFrames) {
      if (_disposed) return;
      vc!.set(cv.CAP_PROP_POS_FRAMES, currentFrame.toDouble());

      final (success, frame) = await vc!.readAsync();
      if (!success || frame.isEmpty) {
        frame.dispose();
        break;
      }

      cv.Mat processedFrame = frame.clone();
      if (processedFrame.cols > processedFrame.rows) {
        final rotatedMat = cv.rotate(processedFrame, cv.ROTATE_90_CLOCKWISE);
        processedFrame.dispose();
        processedFrame = rotatedMat;
      }

      if (processedFrame.cols < rect.x + rect.width ||
          processedFrame.rows < rect.y + rect.height) {
        processedFrame.dispose();
        frame.dispose();
        secondCount++;
        currentFrame += frameStep;
        progress = (totalFrames > 0)
            ? (currentFrame / totalFrames).clamp(0.0, 1.0)
            : 0.0;
        safeNotifyListeners();
        continue;
      }

      final roi = processedFrame.region(rect);
      final cv.Scalar m = cv.mean(roi);

      final currentR = m.val3.round();
      final currentG = m.val2.round();
      final currentB = m.val1.round();

      // 改為儲存 Map 格式
      secondBySecondData.add({
        "second": secondCount + 1,
        "r": currentR,
        "g": currentG,
        "b": currentB,
      });

      sumB += m.val1;
      sumG += m.val2;
      sumR += m.val3;
      count++;
      secondCount++;

      roi.dispose();
      processedFrame.dispose();
      frame.dispose();

      currentFrame += frameStep;
      progress = (totalFrames > 0)
          ? (currentFrame / totalFrames).clamp(0.0, 1.0)
          : 0.0;
      safeNotifyListeners();
    }

    progress = 1.0;
    safeNotifyListeners();

    // 顯示每秒的 RGB 值
    rgbLog += "=== 每秒 RGB 分析結果 ===\n";
    for (Map<String, dynamic> data in secondBySecondData) {
      rgbLog +=
          "第${data['second']}秒: R=${data['r']}, G=${data['g']}, B=${data['b']}\n";
    }
    rgbLog += "\n";

    if (count > 0) {
      final avgR = (sumR / count).round();
      final avgG = (sumG / count).round();
      final avgB = (sumB / count).round();
      rgbLog +=
          "=== 整段影片平均值 ===\n整段影片 ROI 平均 RGB: R=$avgR, G=$avgG, B=$avgB (共 $count 幀，每秒取樣)\n";

      // 分析完成後發送資料到後端
      final success = await _submitAnalysisData(
        secondBySecondData: secondBySecondData,
        averageR: avgR,
        averageG: avgG,
        averageB: avgB,
        totalFrames: count,
      );

      if (success) {
        rgbLog += "分析資料已成功上傳\n";
      } else {
        rgbLog += "分析資料上傳失敗\n";
      }
    } else {
      rgbLog += "無法分析任何幀，請確認選取區域正確。\n";
    }

    print(rgbLog);
    progress = null;
    isAnalyzing = false;
    safeNotifyListeners();
  }

  /// 將分析資料發送到後端
  static Future<bool> _submitAnalysisData({
    required List<Map<String, dynamic>> secondBySecondData,
    required int averageR,
    required int averageG,
    required int averageB,
    required int totalFrames,
  }) async {
    final url = Uri.parse(ApiConstants.analyzeHoneyEndpoint);
    final account = await _storage.read(key: 'account') ?? "";

    final body = {
      "account": account,
      "analysis_data": {
        "average_rgb": {
          "r": averageR,
          "g": averageG,
          "b": averageB,
        },
        "total_frames": totalFrames,
        "second_by_second": secondBySecondData,
      },
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("analyze_honey response: ${response.statusCode}");
      print("analyze_honey body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("analyze_honey error: $e");
      return false;
    }
  }

  /// 自動偵測矩形區域（以顏色範圍）
  Future<void> autoCrop() async {
    rgbLog = "";
    if (firstFrameBytes == null) {
      rgbLog = "請先選擇影片以擷取第一幀\n";
      safeNotifyListeners();
      return;
    }
    if (_disposed) return;
    cv.Mat? srcMat, hsvMat, mask, openedMask, kernel;
    try {
      srcMat = cv.imdecode(firstFrameBytes!, cv.IMREAD_COLOR);

      print("srcMat: ${srcMat.cols} x ${srcMat.rows}");
      if (srcMat.isEmpty) {
        rgbLog += "無法解析第一幀影像\n";
        safeNotifyListeners();
        return;
      }
      // print("srcMat: ${srcMat.cols} x ${srcMat.rows}");
      // if (srcMat.cols > srcMat.rows) {
      //   final rotated = cv.rotate(srcMat, cv.ROTATE_90_CLOCKWISE);
      //   srcMat.dispose();
      //   srcMat = rotated;
      //   print("rotated srcMat: ${srcMat.cols} x ${srcMat.rows}");
      // }

      hsvMat = cv.Mat.empty();
      cv.cvtColor(srcMat, cv.COLOR_BGR2HSV, dst: hsvMat);
      mask = cv.Mat.empty();
      cv.Scalar lowerScalar = cv.Scalar(80, 50, 50);
      cv.Scalar upperScalar = cv.Scalar(130, 255, 255);
      final lowerMat = cv.Mat.fromScalar(1, 3, cv.MatType.CV_8UC3, lowerScalar);
      final upperMat = cv.Mat.fromScalar(1, 3, cv.MatType.CV_8UC3, upperScalar);
      cv.inRange(hsvMat, lowerMat, upperMat, dst: mask);
      lowerMat.dispose();
      upperMat.dispose();
      final kernelSize = (5, 5);
      kernel = cv.getStructuringElement(cv.MORPH_RECT, kernelSize);
      openedMask = cv.Mat.empty();
      cv.morphologyEx(mask, cv.MORPH_OPEN, kernel, dst: openedMask);
      if (openedMask.isEmpty) {
        rgbLog += "遮罩處理後為空，無法繼續。\n";
        safeNotifyListeners();
        return;
      }
      final contoursResult =
          cv.findContours(openedMask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
      final contours = contoursResult.$1;
      double maxArea = 0;
      cv.Rect? largestRect;
      for (final contour in contours) {
        if (contour.isEmpty) continue;
        final area = cv.contourArea(contour);
        if (area > maxArea) {
          maxArea = area;
          final rect = cv.boundingRect(contour);
          const shrink = 20;
          final xNew = rect.x + shrink;
          final yNew = rect.y + shrink;
          final wNew = (rect.width - 2 * shrink).clamp(1, srcMat.cols - xNew);
          final hNew = (rect.height - 2 * shrink).clamp(1, srcMat.rows - yNew);
          if (wNew > 0 && hNew > 0) {
            largestRect = cv.Rect(xNew, yNew, wNew, hNew);
          }
        }
      }
      contours.dispose();
      if (largestRect != null) {
        selectedRect = largestRect;
        drawRectangleOnFirstFrame();
      } else {
        rgbLog += "未能找到符合顏色範圍的區域\n";
      }
      safeNotifyListeners();
    } catch (e) {
      rgbLog += "自動偵測矩形時發生錯誤: $e\n";
      safeNotifyListeners();
    } finally {
      srcMat?.dispose();
      hsvMat?.dispose();
      mask?.dispose();
      openedMask?.dispose();
      kernel?.dispose();
    }
  }

  /// 彈出裁剪頁面讓使用者手動調整選取框
  Future<void> adjustRect(BuildContext context) async {
    rgbLog = "";
    if (firstFrameBytes == null ||
        firstFrameWidth <= 0 ||
        firstFrameHeight <= 0) {
      rgbLog = "請先選擇影片以擷取第一幀";
      safeNotifyListeners();
      return;
    }
    if (_disposed) return;
    Rect? initialRect;
    if (selectedRect != null) {
      initialRect = Rect.fromLTWH(
        selectedRect!.x.toDouble(),
        selectedRect!.y.toDouble(),
        selectedRect!.width.toDouble(),
        selectedRect!.height.toDouble(),
      );
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenSelect(
          imageBytes: firstFrameBytes!,
          imageWidth: firstFrameWidth,
          imageHeight: firstFrameHeight,
          initialRect: initialRect,
        ),
      ),
    );
    if (_disposed) return;
    if (result is cv.Rect) {
      selectedRect = result;
      firstFrameWithRectBytes = null; // 強制刷新
      drawRectangleOnFirstFrame();
      safeNotifyListeners();
    }
  }

  /// 清除 RGB log
  void clearLog() {
    rgbLog = "";
    safeNotifyListeners();
  }

  static Future<bool> submitLabel({
    int? applyId,
    int? needLabel,
    String? honeyType,
    String? apirayName,
  }) async {
    final url = Uri.parse(ApiConstants.submitLabelEndpoint);
    // 從 secure storage 取得 account
    final account = await _storage.read(key: 'account') ?? "";
    final body = <String, dynamic>{
      "apply_id": applyId ?? 0,
      "need_label": needLabel ?? 0,
      "honey_type": honeyType ?? "",
      "account": account,
      "apiray_name": apirayName ?? "",
    };
    print("submit_label body: $body");
    // 若 apiray_name 有值，apply_id 必須為 0；若 apply_id 有值，apiray_name 必須為空
    if ((apirayName != null && apirayName.isNotEmpty)) {
      body["apply_id"] = 0;
    } else {
      body["apiray_name"] = "";
    }
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed && hasListeners) {
      notifyListeners();
    }
  }
}
