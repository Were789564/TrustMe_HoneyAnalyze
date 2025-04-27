import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:file_picker/file_picker.dart';
import '../views/full_screen_select_screen.dart';

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
          notifyListeners();
          return;
        }

        final (success, frame) = await vc.readAsync();
        if (success && !frame.isEmpty) {
          final firstFrameBytes = cv.imencode(".png", frame).$2;
          this.firstFrameBytes = firstFrameBytes;
          firstFrameWithRectBytes = null;

          final firstFrameMat = cv.imdecode(firstFrameBytes, cv.IMREAD_COLOR);
          if (!firstFrameMat.isEmpty) {
            firstFrameWidth = firstFrameMat.cols;
            firstFrameHeight = firstFrameMat.rows;
            firstFrameMat.dispose();
          } else {
            rgbLog += "無法解碼第一幀以獲取解析度\n";
          }
          frame.dispose();
          await autoCrop();
        } else {
          rgbLog += "無法擷取第一幀\n";
        }

        src = path;
        width = vc.get(cv.CAP_PROP_FRAME_WIDTH).toInt();
        height = vc.get(cv.CAP_PROP_FRAME_HEIGHT).toInt();
        fps = vc.get(cv.CAP_PROP_FPS);
        this.vc = vc;
        notifyListeners();
      }
    }
  }

  /// 設定選取的矩形區域
  void setSelectedRect(cv.Rect rect) {
    selectedRect = rect;
    drawRectangleOnFirstFrame();
    notifyListeners();
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

  /// 分析整段影片的 RGB 平均值
  Future<void> startAnalysis() async {
    rgbLog = "";
    progress = 0.0;
    isAnalyzing = true;
    notifyListeners();
    if (vc == null || selectedRect == null) {
      rgbLog = "請先選擇影片並指定矩形區域\n";
      progress = null;
      isAnalyzing = false;
      notifyListeners();
      return;
    }

    final rect = selectedRect!;
    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;

    vc!.set(cv.CAP_PROP_POS_FRAMES, 0);
    final int totalFrames = vc!.get(cv.CAP_PROP_FRAME_COUNT).toInt();
    int currentFrame = 0;

    while (true) {
      final (success, frame) = await vc!.readAsync();
      if (!success || frame.isEmpty) {
        frame.dispose();
        break;
      }
      if (frame.cols < rect.x + rect.width || frame.rows < rect.y + rect.height) {
        frame.dispose();
        currentFrame++;
        progress = (totalFrames > 0)
            ? (currentFrame / totalFrames).clamp(0.0, 1.0)
            : 0.0;
        notifyListeners();
        continue;
      }
      final roi = frame.region(rect);
      final cv.Scalar m = cv.mean(roi);
      sumB += m.val1;
      sumG += m.val2;
      sumR += m.val3;
      count++;
      roi.dispose();
      frame.dispose();

      currentFrame++;
      progress = (totalFrames > 0)
          ? (currentFrame / totalFrames).clamp(0.0, 1.0)
          : 0.0;
      notifyListeners();
    }
    progress = 1.0;
    notifyListeners();

    if (count > 0) {
      final avgR = (sumR / count).round();
      final avgG = (sumG / count).round();
      final avgB = (sumB / count).round();
      rgbLog +=
          "整段影片 ROI 平均 RGB: R=$avgR, G=$avgG, B=$avgB (共 $count 幀)\n";
    } else {
      rgbLog += "無法分析任何幀，請確認選取區域正確。\n";
    }
    progress = null;
    isAnalyzing = false;
    notifyListeners();
  }

  /// 自動偵測矩形區域（以顏色範圍）
  Future<void> autoCrop() async {
    rgbLog = "";
    if (firstFrameBytes == null) {
      rgbLog = "請先選擇影片以擷取第一幀\n";
      notifyListeners();
      return;
    }
    cv.Mat? srcMat, hsvMat, mask, openedMask, kernel;
    try {
      srcMat = cv.imdecode(firstFrameBytes!, cv.IMREAD_COLOR);
      if (srcMat.isEmpty) {
        rgbLog += "無法解析第一幀影像\n";
        notifyListeners();
        return;
      }
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
        notifyListeners();
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
      notifyListeners();
    } catch (e) {
      rgbLog += "自動偵測矩形時發生錯誤: $e\n";
      notifyListeners();
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
    if (firstFrameBytes == null) {
      rgbLog = "請先選擇影片以擷取第一幀";
      notifyListeners();
      return;
    }
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
    if (result is cv.Rect) {
      setSelectedRect(result);
    }
  }

  /// 清除 RGB log
  void clearLog() {
    rgbLog = "";
    notifyListeners();
  }
}
