import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class FullScreenSelectController extends ChangeNotifier {
  final CropController cropController = CropController();
  bool isProcessing = false;
  Uint8List? croppedData;
  Rect? cropRect;

  void setProcessing(bool value) {
    isProcessing = value;
    notifyListeners();
  }

  void setCroppedData(Uint8List? value) {
    croppedData = value;
    notifyListeners();
  }

  void setCropRect(Rect rect) {
    cropRect = rect;
    notifyListeners();
  }

  void reset() {
    croppedData = null;
    notifyListeners();
  }
}
