import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// 即時分析控制器，負責相機控制和即時影像分析
class RealtimeAnalyzeController extends ChangeNotifier {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  Timer? _timer;
  Timer? _previewTimer;
  Uint8List? _currentFrameBytes;
  Uint8List? _previousFrameBytes;
  cv.Rect? _selectedRect;
  Uint8List? _lastRawFrameBytes;
  List<int>? _lastRGB;
  bool _isAnalyzing = false;
  int _intervalMs = 1000;
  bool _isCameraInitialized = false;

  CameraController? get cameraController => _controller;
  Uint8List? get currentFrameBytes => _currentFrameBytes;
  Uint8List? get previousFrameBytes => _previousFrameBytes;
  cv.Rect? get selectedRect => _selectedRect;
  List<int>? get lastRGB => _lastRGB;
  bool get isAnalyzing => _isAnalyzing;
  int get intervalMs => _intervalMs;
  bool get isCameraInitialized => _isCameraInitialized;

  /// 初始化相機並開始預覽
  Future<void> initCamera() async {
    if (_isCameraInitialized) return;
    
    final status = await Permission.camera.request();
    if (!status.isGranted) return;
    
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;
    
    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    try {
      await _controller!.initialize();
      _isCameraInitialized = true;
      notifyListeners();
      
      // 使用選定間隔進行預覽
      _previewTimer = Timer.periodic(Duration(milliseconds: _intervalMs), (_) => _capturePreviewFrame());
      // 立即顯示第一張
      await _capturePreviewFrame();
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  /// 停止相機及相關Timer
  void stopCamera() {
    _previewTimer?.cancel();
    _timer?.cancel();
    _isAnalyzing = false;
    _isCameraInitialized = false;
    _controller?.dispose();
    _controller = null;
    notifyListeners();
  }

  /// 擷取預覽幀，不分析RGB
  Future<void> _capturePreviewFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      _lastRawFrameBytes = bytes;
      
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      if (!mat.isEmpty) {
        if (_selectedRect != null) {
          cv.rectangle(mat, _selectedRect!, cv.Scalar(0, 255, 0, 255), thickness: 2);
        }
        
        _previousFrameBytes = _currentFrameBytes;
        _currentFrameBytes = cv.imencode(".jpg", mat).$2;
        mat.dispose();
        notifyListeners();
      } else {
        _previousFrameBytes = _currentFrameBytes;
        _currentFrameBytes = bytes;
        notifyListeners();
      }
    } catch (e) {
      // ignore errors
    }
  }

  /// 設置拍攝間隔時間(毫秒)
  void setIntervalMs(int ms) {
    _intervalMs = ms;
    if (_isAnalyzing) {
      stopAnalyze();
      startAnalyze();
    }
    notifyListeners();
  }

  /// 開始分析，切換到更高頻率擷取並計算RGB
  void startAnalyze() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    _previewTimer?.cancel();
    
    _isAnalyzing = true;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _intervalMs), (_) => _captureAnalyzeFrame());
    notifyListeners();
  }

  /// 停止分析，恢復預覽模式
  void stopAnalyze() {
    _timer?.cancel();
    _isAnalyzing = false;
    
    // 使用選定間隔進行預覽
    _previewTimer = Timer.periodic(Duration(milliseconds: _intervalMs), (_) => _capturePreviewFrame());
    
    notifyListeners();
  }

  /// 分析模式下擷取並計算RGB
  Future<void> _captureAnalyzeFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      _lastRawFrameBytes = bytes;
      
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      if (!mat.isEmpty) {
        if (_selectedRect != null) {
          cv.rectangle(mat, _selectedRect!, cv.Scalar(0, 255, 0, 255), thickness: 2);
          
          final roi = mat.region(_selectedRect!);
          final cv.Scalar mean = cv.mean(roi);
          final int b = mean.val1.round();
          final int g = mean.val2.round();
          final int r = mean.val3.round();
          roi.dispose();
          _lastRGB = [r, g, b];
        } else {
          _lastRGB = null;
        }
        
        _previousFrameBytes = _currentFrameBytes;
        _currentFrameBytes = cv.imencode(".jpg", mat).$2;
        
        mat.dispose();
      } else {
        _lastRGB = null;
        _previousFrameBytes = _currentFrameBytes;
        _currentFrameBytes = bytes;
      }
      
      notifyListeners();
    } catch (e) {
      // ignore errors
    }
  }

  /// 以目前相機畫面自動選取ROI
  Future<void> autoSelectRect() async {
    if (_lastRawFrameBytes == null) return;
    
    final rect = await _detectAutoRect(_lastRawFrameBytes!);
    if (rect != null) {
      setSelectedRect(rect);
    }
  }

  /// 手動設定ROI框
  void setSelectedRect(cv.Rect rect) {
    _selectedRect = rect;
    notifyListeners();
    
    _capturePreviewFrame();
  }

  /// 依據當前frame自動偵測ROI
  Future<cv.Rect?> _detectAutoRect(Uint8List frameBytes) async {
    cv.Mat? srcMat, hsvMat, mask, openedMask, kernel;
    try {
      srcMat = cv.imdecode(frameBytes, cv.IMREAD_COLOR);
      if (srcMat.isEmpty) return null;
      
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
      
      if (openedMask.isEmpty) return null;
      
      final contoursResult = cv.findContours(openedMask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
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
      return largestRect;
    } catch (_) {
      return null;
    } finally {
      srcMat?.dispose();
      hsvMat?.dispose();
      mask?.dispose();
      openedMask?.dispose();
      kernel?.dispose();
    }
  }

  Uint8List? get lastRawFrameBytes => _lastRawFrameBytes;

  @override
  void dispose() {
    _timer?.cancel();
    _previewTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
