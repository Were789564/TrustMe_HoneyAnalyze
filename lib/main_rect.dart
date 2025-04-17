import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Store original and processed image bytes
  Uint8List? originalImageBytes;
  Uint8List? processedImageBytes;
  String processingLog = ""; // To store print output for display

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

//  Future<(cv.Mat, String)> detectRectanglesAsync(cv.Mat inputMat) async {
//   final outputMat = inputMat.clone();
//   final StringBuffer logBuffer = StringBuffer();

//   final gray = await cv.cvtColorAsync(inputMat, cv.COLOR_BGR2GRAY);
//   final blurred = await cv.gaussianBlurAsync(gray, (5, 5), 0, sigmaY: 0);
//   //final (_, thresholded) = await cv.thresholdAsync(
//       //blurred, 0, 255, cv.THRESH_BINARY + cv.THRESH_OTSU);
//   final thresholded = await cv.cannyAsync(blurred, 70, 100);
//   List<cv.Rect> detectedRects = [];
//   final contours = await cv.findContoursAsync(
//       thresholded, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);

//   int rectangleCount = 0;
//   for (var i = 0; i < contours.$1.length; i++) {
//     final contour = contours.$1.elementAt(i);
//     final peri = cv.arcLength(contour, true);
//     final approx = cv.approxPolyDP(contour, 0.03 * peri, true);

//     if (approx.length == 4) {
//       final area = cv.contourArea(contour);
//       const minArea = 100.0;
//       final isConvex = cv.isContourConvex(approx);

//       if (area > minArea && isConvex) {
//         rectangleCount++;
//         final rect = cv.boundingRect(approx);
//         final message =
//             "Detected Rectangle #$rectangleCount: Bounding Box [x: ${rect.x}, y: ${rect.y}, width: ${rect.width}, height: ${rect.height}], Area: ${area.toStringAsFixed(2)}";
//         print(message);
//         logBuffer.writeln(message);
//         cv.rectangle(outputMat, rect, cv.Scalar(0, 255, 0, 255), thickness: 2);
//       }
//     }

//     // 只釋放 approx，因為它是獨立創建的
//     approx.dispose();
//     // 移除 contour.dispose()，因為 contour 是 contours.$1 的一部分
//   }

//   logBuffer.writeln("\nFinished. Found $rectangleCount potential rectangles meeting criteria.");
//   print("Finished processing. Found $rectangleCount potential rectangles meeting criteria.");

//   gray.dispose();
//   blurred.dispose();
//   thresholded.dispose();
//   contours.$1.dispose();

//   return (outputMat, logBuffer.toString());
// }

Future<(cv.Mat, String)> detectRectanglesAsync(cv.Mat inputMat) async {
  final outputMat = inputMat.clone();
  final StringBuffer logBuffer = StringBuffer();

  final gray = await cv.cvtColorAsync(inputMat, cv.COLOR_BGR2GRAY);
  final blurred = await cv.gaussianBlurAsync(gray, (5, 5), 0, sigmaY: 0);
  final thresholded = await cv.cannyAsync(blurred, 70, 100); // 調整高閾值為 100
  final contours = await cv.findContoursAsync(
      thresholded, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);

  int rectangleCount = 0;
  // 儲存檢測到的矩形邊界框
  List<cv.Rect> detectedRects = [];

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

        // 檢查是否與已有矩形過於相似
        bool isDuplicate = false;
        for (var existingRect in detectedRects) {
          final dx = (rect.x - existingRect.x).abs();
          final dy = (rect.y - existingRect.y).abs();
          final dw = (rect.width - existingRect.width).abs();
          final dh = (rect.height - existingRect.height).abs();

          // 如果座標差異小於某個閾值（例如 5 像素），視為重複
          if (dx < 5 && dy < 5 && dw < 10 && dh < 10) {
            isDuplicate = true;
            break;
          }
        }

        if (!isDuplicate) {
          rectangleCount++;
          detectedRects.add(rect);

          final message =
              "Detected Rectangle #$rectangleCount: Bounding Box [x: ${rect.x}, y: ${rect.y}, width: ${rect.width}, height: ${rect.height}], Area: ${area.toStringAsFixed(2)}";
          print(message);
          logBuffer.writeln(message);
          cv.rectangle(outputMat, rect, cv.Scalar(0, 255, 0, 255), thickness: 2);
        }
      }
    }

    approx.dispose();
  }

  logBuffer.writeln("\nFinished. Found $rectangleCount potential rectangles meeting criteria.");
  print("Finished processing. Found $rectangleCount potential rectangles meeting criteria.");

  gray.dispose();
  blurred.dispose();
  thresholded.dispose();
  contours.$1.dispose();

  return (outputMat, logBuffer.toString());
}

  // --- Button Actions ---

  Future<void> processImageFromPath(String path) async {
    setState(() {
      processingLog = "Loading image...";
      originalImageBytes = null;
      processedImageBytes = null;
    });

    try {
      final mat = cv.imread(path, flags: cv.IMREAD_COLOR);
      if (mat.isEmpty) {
         setState(() => processingLog = "Error: Could not read image from path: $path");
         return;
      }
      print("cv.imread: width: ${mat.cols}, height: ${mat.rows}, path: $path");
      debugPrint("Input mat.data.length: ${mat.data.length}");

       // Encode original for display before processing
      final originalBytes = cv.imencode(".png", mat).$2;

      setState(() {
        originalImageBytes = originalBytes;
        processingLog = "Processing image for rectangles...";
      });
      await Future.delayed(Duration(milliseconds: 50)); // Allow UI update

      // Perform rectangle detection
      final (resultMat, log) = await detectRectanglesAsync(mat);

      // Encode the result image (with rectangles drawn)
      final resultBytes = cv.imencode(".png", resultMat).$2;

      setState(() {
        processedImageBytes = resultBytes;
        processingLog = log; // Display the collected logs
      });

      // Clean up Mats
      mat.dispose();
      resultMat.dispose();

    } catch (e) {
       print("Error processing image: $e");
       setState(() => processingLog = "Error processing image: $e");
    }
  }

  Future<void> processImageAsset(String assetPath) async {
    setState(() {
      processingLog = "Loading asset image...";
      originalImageBytes = null;
      processedImageBytes = null;
    });

     try {
      final data = await DefaultAssetBundle.of(context).load(assetPath);
      final bytes = data.buffer.asUint8List();

      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
       if (mat.isEmpty) {
         setState(() => processingLog = "Error: Could not decode image from asset: $assetPath");
         return;
      }
      print("cv.imdecode: width: ${mat.cols}, height: ${mat.rows}");
      debugPrint("Input mat.data.length: ${mat.data.length}");

      // Use the loaded bytes directly as original for display
      setState(() {
        originalImageBytes = bytes;
        processingLog = "Processing image for rectangles...";
      });
       await Future.delayed(Duration(milliseconds: 50)); // Allow UI update


      // Perform rectangle detection
      final (resultMat, log) = await detectRectanglesAsync(mat);

      // Encode the result image
      final resultBytes = cv.imencode(".png", resultMat).$2;

      setState(() {
        processedImageBytes = resultBytes;
        processingLog = log;
      });

      // Clean up Mats
      mat.dispose();
      resultMat.dispose();

    } catch (e) {
       print("Error processing asset: $e");
       setState(() => processingLog = "Error processing asset: $e");
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
                      final img =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        await processImageFromPath(img.path);
                      }
                    },
                    child: const Text("Pick & Process Image"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Make sure 'images/rectangles.jpg' (or your test image)
                      // exists in your assets folder and is declared in pubspec.yaml
                      await processImageAsset("assets/images/sudoku.png"); // Example asset path
                    },
                    child: const Text("Process Asset Image"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 3, // More space for images
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original Image Display
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
                    // Processed Image Display
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
              // Log Display Area
               const Text("Processing Log / Results", style: TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(height: 5),
               Expanded(
                flex: 2, // Space for logs
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Text(processingLog.isEmpty ? "Logs will appear here..." : processingLog),
                  ),
                ),
              ),
              // OpenCV Build Info (Optional)
              // Expanded(
              //   flex: 1,
              //   child: SingleChildScrollView(
              //      child: Padding(
              //        padding: const EdgeInsets.only(top: 8.0),
              //        child: Text(cv.getBuildInformation()),
              //      ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}