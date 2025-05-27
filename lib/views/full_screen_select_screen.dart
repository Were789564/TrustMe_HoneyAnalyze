import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:provider/provider.dart';
import '../controllers/full_screen_select_controller.dart';

/// 全屏選取框調整畫面
class FullScreenSelect extends StatelessWidget {
  const FullScreenSelect({
    super.key,
    required this.imageBytes,
    this.initialRect,
    this.imageWidth,
    this.imageHeight,
  });

  final Uint8List imageBytes;
  final Rect? initialRect;
  final int? imageWidth;
  final int? imageHeight;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FullScreenSelectController(),
      child: _FullScreenSelectView(
        imageBytes: imageBytes,
        initialRect: initialRect,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      ),
    );
  }
}

/// 全屏選取框調整畫面內部視圖
class _FullScreenSelectView extends StatelessWidget {
  const _FullScreenSelectView({
    required this.imageBytes,
    required this.initialRect,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Uint8List imageBytes;
  final Rect? initialRect;
  final int? imageWidth;
  final int? imageHeight;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FullScreenSelectController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF176), // 黃色系
        title: const Text(
          '調整選取範圍',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.yellow,
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        actions: [
          if (controller.croppedData == null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.black87),
              onPressed: () {
                controller.setProcessing(true);
                controller.cropController.crop();
              },
            ),
          if (controller.croppedData != null)
            IconButton(
              icon: const Icon(Icons.redo, color: Colors.black87),
              onPressed: () => controller.reset(),
            ),
        ],
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),
      body: Visibility(
        visible: imageBytes.isNotEmpty && !controller.isProcessing,
        replacement: const Center(child: CircularProgressIndicator()),
        child: imageBytes.isNotEmpty
            ? Visibility(
                visible: controller.croppedData == null,
                replacement: controller.croppedData != null
                    ? SizedBox(
                        height: double.infinity,
                        width: double.infinity,
                        child: Image.memory(
                          controller.croppedData!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const SizedBox.shrink(),
                child: Crop(
                  controller: controller.cropController,
                  image: imageBytes,
                  initialRectBuilder:
                      InitialRectBuilder.withBuilder((viewportRect, imageRect) {
                    if (initialRect != null &&
                        imageWidth != null &&
                        imageHeight != null) {
                      final scaleX = imageRect.width / imageWidth!;
                      final scaleY = imageRect.height / imageHeight!;
                      final left = imageRect.left + initialRect!.left * scaleX;
                      final top = imageRect.top + initialRect!.top * scaleY;
                      final right = left + initialRect!.width * scaleX;
                      final bottom = top + initialRect!.height * scaleY;
                      return Rect.fromLTRB(left, top, right, bottom);
                    }
                    return Rect.fromLTRB(
                      viewportRect.left + 24,
                      viewportRect.top + 32,
                      viewportRect.right - 24,
                      viewportRect.bottom - 32,
                    );
                  }),
                  onMoved: (_, rect) {
                    controller.setCropRect(rect);
                  },
                  onCropped: (result) {
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        controller.setCroppedData(croppedImage);
                        controller.setProcessing(false);
                        if (controller.cropRect != null) {
                          final selectedRect = cv.Rect(
                            controller.cropRect!.left.toInt(),
                            controller.cropRect!.top.toInt(),
                            controller.cropRect!.width.toInt(),
                            controller.cropRect!.height.toInt(),
                          );
                          Navigator.pop(context, selectedRect);
                        }
                        break;
                      case CropFailure():
                        controller.setProcessing(false);
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