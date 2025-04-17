import 'dart:async';
import 'dart:isolate';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:file_picker/file_picker.dart';
import 'full_screen_crop.dart';
import 'main_rect.dart';
import 'realtime_analyze.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video RGB Analysis',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Video RGB Analysis'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int width = -1;
  int height = -1;
  double fps = -1;
  String backend = "unknown";
  String? src;
  cv.VideoCapture? vc;
  Uint8List? _firstFrameBytes;
  Uint8List? _firstFrameWithRectBytes;
  int _firstFrameWidth = -1;
  int _firstFrameHeight = -1;
  Uint8List? _currentFrameBytes;
  cv.Rect? _selectedRect;
  String rgbLog = "";
  late ReceivePort _receivePort;
  Timer? _frameTimer;

  @override
  void initState() {
    super.initState();
    _receivePort = ReceivePort();
    _receivePort.listen((message) {
      if (message is (Uint8List, String)) {
        setState(() {
          _currentFrameBytes = message.$1;
          rgbLog += "${message.$2}\n";
        });
      } else if (message is cv.Rect) {
        setState(() {
          _selectedRect = message;
          rgbLog += "已選取矩形: ${_selectedRect!.x}, ${_selectedRect!.y}, ${_selectedRect!.width}x${_selectedRect!.height}\n";
          _drawRectangleOnFirstFrame();
        });
      }
    });
  }

  @override
  void dispose() {
    vc?.release();
    _frameTimer?.cancel();
    _receivePort.close();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      final file = result.files.single;
      final path = file.path;
      if (path != null) {
        debugPrint("selected file: $path");
        cv.VideoCapture? vc = cv.VideoCapture.empty();
        await vc.openAsync(path);
        if (!(vc.isOpened)) {
          setState(() => rgbLog = "Error: Could not open video file $path");
          vc = null;
          return;
        }

        final (success, frame) = await vc.readAsync();
        if (success && !frame.isEmpty) {
          final firstFrameBytes = cv.imencode(".png", frame).$2;
          setState(() {
            _firstFrameBytes = firstFrameBytes;
            _firstFrameWithRectBytes = null;
          });

          final firstFrameMat = cv.imdecode(firstFrameBytes, cv.IMREAD_COLOR);
          if (!firstFrameMat.isEmpty) {
            setState(() {
              _firstFrameWidth = firstFrameMat.cols;
              _firstFrameHeight = firstFrameMat.rows;
            });
            firstFrameMat.dispose();
          } else {
            setState(() => rgbLog += "無法解碼第一幀以獲取解析度\n");
          }
          frame.dispose();
        } else {
          setState(() => rgbLog += "無法擷取第一幀\n");
        }

        setState(() {
          src = path;
          width = vc!.get(cv.CAP_PROP_FRAME_WIDTH).toInt();
          height = vc.get(cv.CAP_PROP_FRAME_HEIGHT).toInt();
          fps = vc.get(cv.CAP_PROP_FPS);
          this.vc = vc;
          _selectedRect = null;
        });
      }
    }
  }

  void _navigateToCropScreen(BuildContext context) async {
    if (_firstFrameBytes != null) {
      final selectedRect = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenCrop(imageBytes: _firstFrameBytes!),
        ),
      );
      if (selectedRect is cv.Rect) {
        setState(() {
          _selectedRect = selectedRect;
          rgbLog += "已選取矩形: ${_selectedRect!.x}, ${_selectedRect!.y}, ${_selectedRect!.width}x${_selectedRect!.height}\n";
          _drawRectangleOnFirstFrame();
        });
      }
    } else {
      setState(() => rgbLog = "請先選擇影片以擷取第一幀");
    }
  }

  void _drawRectangleOnFirstFrame() {
    if (_firstFrameBytes != null && _selectedRect != null) {
      final firstFrameMat = cv.imdecode(_firstFrameBytes!, cv.IMREAD_COLOR);
      if (!firstFrameMat.isEmpty) {
        cv.rectangle(
          firstFrameMat,
          _selectedRect!,
          cv.Scalar(0, 255, 0, 255),
          thickness: 2,
        );
        final encodedImage = cv.imencode(".png", firstFrameMat).$2;
        setState(() {
          _firstFrameWithRectBytes = encodedImage;
        });
        firstFrameMat.dispose();
      }
    }
  }

  void _startAnalysis() async {
    if (vc == null || _selectedRect == null) {
      setState(() => rgbLog = "請先選擇影片並指定矩形區域\n");
      return;
    }

    if (_firstFrameBytes == null) {
      setState(() => rgbLog = "尚未擷取到第一幀\n");
      return;
    }

    final rectData = (
      _selectedRect!.x,
      _selectedRect!.y,
      _selectedRect!.width,
      _selectedRect!.height,
    );

    final result = await compute(
      _analyzeFrameInIsolate,
      (_firstFrameBytes!, rectData, _receivePort.sendPort),
    );

    setState(() {
      _currentFrameBytes = result.$1;
      rgbLog += "${result.$2}\n";
    });
  }

  static Future<(Uint8List, String)> _analyzeFrameInIsolate(
      (Uint8List, (int, int, int, int), SendPort) data) async {
    final frameBytes = data.$1;
    final rectData = data.$2;
    //final sendPort = data.$3;

    final rect = cv.Rect(rectData.$1, rectData.$2, rectData.$3, rectData.$4);
    final mat = cv.imdecode(frameBytes, cv.IMREAD_COLOR);
    if (mat.isEmpty) return (frameBytes, "錯誤：無法解碼幀");

    final roi = mat.region(rect);
    final cv.Scalar m = cv.mean(roi);
    final int b = m.val1.round();
    final int g = m.val2.round();
    final int r = m.val3.round();

    final rgbMessage =
        "第一幀 RGB at [${rect.x}, ${rect.y}, ${rect.width}x${rect.height}]: R=$r, G=$g, B=$b";

    cv.rectangle(mat, rect, cv.Scalar(0, 255, 0, 255), thickness: 2);
    final outputBytes = cv.imencode(".png", mat).$2;

    roi.dispose();
    mat.dispose();

    return (outputBytes, rgbMessage);
  }

  void _analyzeVideoEverySecond() async {
    if (vc == null || _selectedRect == null) {
      setState(() => rgbLog = "請先選擇影片並指定矩形區域\n");
      return;
    }

    setState(() {
      rgbLog += "\n🔍 開始每秒分析影片...\n";
      _currentFrameBytes = null;
    });

    final fps = vc!.get(cv.CAP_PROP_FPS);
    final totalFrames = vc!.get(cv.CAP_PROP_FRAME_COUNT).toInt();
    final durationSeconds = (totalFrames / fps).floor();

    for (int sec = 0; sec < durationSeconds; sec++) {
      vc!.set(cv.CAP_PROP_POS_MSEC, sec * 1000.0);
      final (success, frame) = await vc!.readAsync();

      if (!success || frame.isEmpty) {
        rgbLog += "⚠️ 無法讀取第 $sec 秒的幀\n";
        continue;
      }

      final roi = frame.region(_selectedRect!);
      final cv.Scalar m = cv.mean(roi);
      final int b = m.val1.round();
      final int g = m.val2.round();
      final int r = m.val3.round();
      roi.dispose();

      final msg = "第 $sec 秒 RGB: R=$r, G=$g, B=$b";

      if (sec == durationSeconds - 1) {
        cv.rectangle(frame, _selectedRect!, cv.Scalar(0, 255, 0, 255), thickness: 2);
        final frameBytes = cv.imencode(".png", frame).$2;
        setState(() {
          _currentFrameBytes = frameBytes;
        });
      }

      frame.dispose();

      setState(() {
        rgbLog += "$msg\n";
      });

      await Future.delayed(const Duration(milliseconds: 10));
    }

    setState(() {
      rgbLog += "✅ 分析完成，共 $durationSeconds 秒資料\n";
    });
  }


  void _autoCrop() async {
    if (_firstFrameBytes == null) {
      setState(() => rgbLog = "請先選擇影片以擷取第一幀\n");
      return;
    }

    setState(() {
      rgbLog += "開始自動偵測矩形區域...\n";
    });

    // 定義所有資源變數，方便在 finally 中統一釋放
    cv.Mat? srcMat, hsvMat, mask, openedMask, kernel;
    //List<cv.Mat>? contours;
  

    try {
      // 解碼第一幀
      srcMat = cv.imdecode(_firstFrameBytes!, cv.IMREAD_COLOR);
      if (srcMat.isEmpty) {
        setState(() => rgbLog += "無法解析第一幀影像\n");
        return;
      }

      // 轉換為 HSV 色彩空間
      hsvMat = cv.Mat.empty();
      cv.cvtColor(srcMat, cv.COLOR_BGR2HSV, dst: hsvMat);

      // 創建遮罩
      mask = cv.Mat.empty();
      cv.Scalar lowerScalar = cv.Scalar(80, 50, 50);
      cv.Scalar upperScalar = cv.Scalar(130, 255, 255);
      final lowerMat = cv.Mat.fromScalar(1, 3, cv.MatType.CV_8UC3, lowerScalar);
      final upperMat = cv.Mat.fromScalar(1, 3, cv.MatType.CV_8UC3, upperScalar);
      cv.inRange(hsvMat, lowerMat, upperMat, dst: mask);


      lowerMat.dispose();
      upperMat.dispose();
      
      // 創建結構元素並進行形態學開運算
      final kernelSize = (5, 5);
      kernel = cv.getStructuringElement(cv.MORPH_RECT, kernelSize);
      openedMask = cv.Mat.empty();
      cv.morphologyEx(mask, cv.MORPH_OPEN, kernel, dst: openedMask);

      // 檢查遮罩是否有效
      if (openedMask.isEmpty) {
        setState(() => rgbLog += "遮罩處理後為空，無法繼續。\n");
        return;
      }

      // 尋找輪廓
      final contoursResult = cv.findContours(openedMask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
      final contours = contoursResult.$1;

      // 找到面積最大的輪廓
      double maxArea = 0;
      cv.Rect? largestRect;

      for (final contour in contours) {
        if (contour.isEmpty) continue;
        final area = cv.contourArea(contour);
        if (area > maxArea) {
          maxArea = area;
          largestRect = cv.boundingRect(contour);
        }
      }
      
    

      // for (final contour in contours) {
      //   contour.dispose();
      // }

      contours.dispose();    



      // 根據結果更新狀態
      if (largestRect != null) {
        setState(() {
          _selectedRect = largestRect;
          rgbLog += "已自動選取矩形: ${_selectedRect!.x}, ${_selectedRect!.y}, ${_selectedRect!.width}x${_selectedRect!.height}\n";
          _drawRectangleOnFirstFrame();
        });
      } else {
        setState(() {
          rgbLog += "未能找到符合顏色範圍的區域\n";
        });
      }
    } catch (e) {
      setState(() {
        rgbLog += "自動偵測矩形時發生錯誤: $e\n";
      });
    } finally {
      // 統一釋放所有資源
      srcMat?.dispose();
      hsvMat?.dispose();
      mask?.dispose();
      openedMask?.dispose();
      kernel?.dispose();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _pickVideo, child: const Text("選擇影片")),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _navigateToCropScreen(context),
                  child: const Text("指定矩形"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _startAnalysis, child: const Text("開始分析")),
                
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _autoCrop, child: const Text("自動選取")),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _analyzeVideoEverySecond, child: const Text("開始分析整部影片")),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MainRectPage()),
                    );
                  },
                  child: const Text("校正"),
                ),
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                const SizedBox(width: 10),
                    ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RealtimeAnalyze()),
                    );
                  },
                  child: const Text("即時分析"),
                )
              ]

            ),
            Text("寬: $width, 高: $height, FPS: $fps, 後端: $backend"),
            ExtendedText(
              "來源: $src",
              maxLines: 1,
              overflowWidget: const TextOverflowWidget(
                position: TextOverflowPosition.middle,
                child: Text("..."),
              ),
            ),
            const SizedBox(height: 10),
            if (_firstFrameBytes != null)
              Column(
                children: [
                  _firstFrameWithRectBytes != null
                      ? Image.memory(_firstFrameWithRectBytes!, width: 300, fit: BoxFit.contain)
                      : Image.memory(_firstFrameBytes!, width: 300, fit: BoxFit.contain),
                  const SizedBox(height: 5),
                  Text("第一幀解析度: ${_firstFrameWidth}x$_firstFrameHeight"),
                ],
              )
            else
              const Placeholder(fallbackWidth: 300, fallbackHeight: 200),
            const SizedBox(height: 10),
            _currentFrameBytes != null
                ? Image.memory(_currentFrameBytes!, width: 300, fit: BoxFit.contain)
                : const SizedBox.shrink(),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(rgbLog.isEmpty ? "RGB 值將顯示在此處..." : rgbLog),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
