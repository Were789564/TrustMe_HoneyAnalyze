import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv; // 引入 opencv_dart

class FullScreenCrop extends StatefulWidget {
  const FullScreenCrop({
    super.key,
    required this.imageBytes,
    this.initialRect,
    this.imageWidth,
    this.imageHeight
    });

  final Uint8List imageBytes;
  final Rect? initialRect; // 新增 initialRect 參數
  final int? imageWidth; // 新增 imageWidth 參數
  final int? imageHeight; // 新增 imageHeight 參數

  @override
  _FullScreenCropState createState() => _FullScreenCropState();
}

class _FullScreenCropState extends State<FullScreenCrop> {
  final _controller = CropController();
  var _isProcessing = false;
  Rect? _cropRect; // 保存裁剪的 Rect 物件


  set isProcessing(bool value) {
    setState(() {
      _isProcessing = value;
    });
  }

  Uint8List? _croppedData;

  set croppedData(Uint8List? value) {
    setState(() {
      _croppedData = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("FullScreenCrop build 方法被調用");
    debugPrint("FullScreenCrop 接收到的 imageBytes 長度: ${widget.imageBytes.length}");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '選取分析區域',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          if (_croppedData == null)
            IconButton(
              icon: const Icon(Icons.check), // 使用 check 圖示表示確認選取
              onPressed: () {
                isProcessing = true;
                _controller.crop();
              },
            ),
          if (_croppedData != null)
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: () => croppedData = null,
            ),
        ],
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),
      body: Visibility(
        visible: widget.imageBytes.isNotEmpty && !_isProcessing,
        replacement: const Center(child: CircularProgressIndicator()), // 注意這裡的判斷
        child: widget.imageBytes.isNotEmpty
            ? Visibility(
                visible: _croppedData == null,
                replacement: _croppedData != null
                    ? SizedBox(
                        height: double.infinity,
                        width: double.infinity,
                        child: Image.memory(
                          _croppedData!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const SizedBox.shrink(),
                child: Crop(
                  controller: _controller,
                  image: widget.imageBytes,
                  initialRectBuilder: InitialRectBuilder.withBuilder((viewportRect, imageRect) {
                    if (widget.initialRect != null) {

                      // 假設 widget.initialRect 是原圖座標
                      final scaleX = imageRect.width / widget.imageWidth!;
                      final scaleY = imageRect.height / widget.imageHeight!;
                      final left = imageRect.left + widget.initialRect!.left * scaleX;
                      final top = imageRect.top + widget.initialRect!.top * scaleY;
                      final right = left + widget.initialRect!.width * scaleX;
                      final bottom = top + widget.initialRect!.height * scaleY;
                      return Rect.fromLTRB(left, top, right, bottom);
                    }
                    // 預設裁剪框
                    return Rect.fromLTRB(
                      viewportRect.left + 24,
                      viewportRect.top + 32,
                      viewportRect.right - 24,
                      viewportRect.bottom - 32,
                    );
                  }),
                  onMoved: (Rect1, Rect2) {
                    _cropRect = Rect2; // 保存裁剪的 Rect
                  },
                  onCropped: (result) {
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        croppedData = croppedImage;
                        isProcessing = false;
                        if (_cropRect != null) {
                          final selectedRect = cv.Rect(
                            _cropRect!.left.toInt(),
                            _cropRect!.top.toInt(),
                            _cropRect!.width.toInt(),
                            _cropRect!.height.toInt(),
                          );
                          Navigator.pop(context, selectedRect); // 只有在裁剪成功後才 pop
                        }
                        break;
                      case CropFailure():
                        isProcessing = false;
                        break;
                    }
                  },
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}