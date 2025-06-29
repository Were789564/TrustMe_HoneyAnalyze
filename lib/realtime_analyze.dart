import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'full_screen_crop.dart';

class RealtimeAnalyze extends StatefulWidget {
  const RealtimeAnalyze({super.key});

  @override
  State<RealtimeAnalyze> createState() => _RealtimeAnalyzeState();
}

class _RealtimeAnalyzeState extends State<RealtimeAnalyze> {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  Timer? _timer;
  Uint8List? _currentFrameBytes;
  Uint8List? _previousFrameBytes; // 新增：上一張圖
  cv.Rect? _selectedRect;
  Uint8List? _lastRawFrameBytes;
  List<int>? _lastRGB; // 新增：儲存RGB

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return;
      }
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
      _startRealtimeCapture();
    } catch (e) {
      // 忽略錯誤
    }
  }

  void _startRealtimeCapture() {
    _timer = Timer.periodic(
        const Duration(milliseconds: 10), (_) => _captureFrame());
  }

    Future<void> _captureFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      _lastRawFrameBytes = bytes;
      
      // 解碼影像
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      
      if (!mat.isEmpty) {
        if (_selectedRect != null) {
          // 在原始影像上繪製選取框
           cv.rectangle(mat, _selectedRect!, cv.Scalar(0, 255, 0, 255), thickness: 2);;
          
          // 獲取選取區域的平均顏色
          final roi = mat.region(_selectedRect!);
          final cv.Scalar mean = cv.mean(roi);
          final int b = mean.val1.round();
          final int g = mean.val2.round();
          final int r = mean.val3.round();
          roi.dispose();
          
          setState(() {
            _lastRGB = [r, g, b];
            _previousFrameBytes = _currentFrameBytes; // 先存舊圖
            _currentFrameBytes = cv.imencode(".jpg", mat).$2;
          });
        } else {
          setState(() {
            _lastRGB = null;
            _previousFrameBytes = _currentFrameBytes; // 先存舊圖
            _currentFrameBytes = cv.imencode(".jpg", mat).$2;
          });
        }
        mat.dispose();
      } else {
        setState(() {
          _lastRGB = null;
          _previousFrameBytes = _currentFrameBytes; // 先存舊圖
          _currentFrameBytes = bytes;
        });
      }
    } catch (e) {
      // 忽略錯誤
    }
  }

  Future<void> _manualSelectRect() async {
    if (_lastRawFrameBytes == null) return;
    final rect = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenCrop(imageBytes: _lastRawFrameBytes!),
      ),
    );
    if (rect is cv.Rect) {
      setState(() {
        _selectedRect = rect;
      });
      // 立即重畫一次
      _captureFrame();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("即時影像顯示")),
      body: SafeArea(
        child: Center(
          child: _controller == null || !_controller!.value.isInitialized
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _manualSelectRect,
                            child: const Text("手動選取"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 1280,
                        height: 720,
                        color: Colors.white,
                        child: Stack(
                          children: [
                            if (_previousFrameBytes != null)
                              Image.memory(
                                _previousFrameBytes!,
                                width: 1280,
                                height: 720,
                                fit: BoxFit.cover,
                              ),
                            if (_currentFrameBytes != null)
                              Image.memory(
                                _currentFrameBytes!,
                                width: 1280,
                                height: 720,
                                fit: BoxFit.cover,
                              ),
                            if (_currentFrameBytes == null &&
                                _previousFrameBytes == null)
                              const Center(
                                  child: Text("等待影像...",
                                      style: TextStyle(color: Colors.white))),
                            
                          ],
                        ),
                      ),
                      if (_selectedRect != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "選取區域: (${_selectedRect!.x}, ${_selectedRect!.y}, ${_selectedRect!.width}x${_selectedRect!.height})",
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      if (_lastRGB != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, _lastRGB![0],
                                      _lastRGB![1], _lastRGB![2]),
                                  border: Border.all(color: Colors.black26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "R: ${_lastRGB![0]}, G: ${_lastRGB![1]}, B: ${_lastRGB![2]}",
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
