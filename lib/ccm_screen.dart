import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ml_linalg/linalg.dart';

/// CCM 計算工具類（可在其他檔案直接呼叫）
class CCMCalculator {
  /// 計算 OLS CCM 與誤差
  /// 
  /// 輸入：
  ///   [deviceRGB]：Matrix，形狀為 (18,3)，每一列為偵測到的色塊 RGB
  ///   [targetRGB]：Matrix，形狀為 (18,3)，每一列為標準色卡 RGB
  /// 輸出：
  ///   Map<String, Matrix>，包含
  ///     'olsCCM'：OLS 計算得到的 3x3 CCM 矩陣
  ///     'olsError'：校正後的誤差 (18x3)
  Map<String, Matrix> calculateCCMs(Matrix deviceRGB, Matrix targetRGB) {
    final olsCCM = _calculateOLSCCM(deviceRGB, targetRGB);
    final olsError = _calculateError(deviceRGB, targetRGB, olsCCM);
    return {'olsCCM': olsCCM, 'olsError': olsError};
  }

  /// OLS CCM 計算 (不加 bias，3x3)
  /// 
  /// 輸入：
  ///   [deviceRGB]：Matrix (18x3)
  ///   [targetRGB]：Matrix (18x3)
  /// 輸出：
  ///   Matrix (3x3)，OLS 計算得到的 CCM
  Matrix _calculateOLSCCM(Matrix deviceRGB, Matrix targetRGB) {
    // OLS: (X^T X)^-1 X^T Y
    return (deviceRGB.transpose() * deviceRGB)
        .inverse() *
        deviceRGB.transpose() *
        targetRGB;
  }

  /// 計算 CCM 校正後誤差
  /// 
  /// 輸入：
  ///   [deviceRGB]：Matrix (18x3)
  ///   [targetRGB]：Matrix (18x3)
  ///   [ccm]：Matrix (3x3)
  /// 輸出：
  ///   Matrix (18x3)，校正後誤差
  Matrix _calculateError(Matrix deviceRGB, Matrix targetRGB, Matrix ccm) {
    final predictedRGB = (deviceRGB * ccm).mapElements((v) => v.clamp(0.0, 255.0));
    return targetRGB - predictedRGB;
  }
}

/// CCM 計算與顯示頁面（只保留顯示與互動）
class CcmScreen extends StatefulWidget {
  /// deviceRGBData: List<List<double>>，每一列為偵測到的色塊 RGB
  /// targetRGBData: List<List<double>>，每一列為標準色卡 RGB
  const CcmScreen({super.key, required this.deviceRGBData, required this.targetRGBData});

  final List<List<double>> deviceRGBData;
  final List<List<double>> targetRGBData;

  @override
  State<CcmScreen> createState() => _CcmScreenState();
}

class _CcmScreenState extends State<CcmScreen> {
  Matrix? _olsCCM, _olsError, _originalError, _predictedRGB;

  /// 格式化矩陣為字串
  /// 
  /// 輸入：
  ///   [matrix]：Matrix?，要格式化的矩陣
  ///   [maxRows]：int，最多顯示幾列（預設20）
  /// 輸出：
  ///   String，多行字串
  String formatMatrix(Matrix? matrix, [int maxRows = 20]) {
    if (matrix == null) return 'N/A';
    return List.generate(
      min(matrix.rowCount, maxRows),
      (i) => matrix.getRow(i).toList().map((e) => e.toStringAsFixed(4)).join(', ')
    ).join('\n');
  }

  /// 計算原始 RMSE 誤差
  /// 
  /// 輸入：
  ///   [deviceRGB]：Matrix (18x3)
  ///   [targetRGB]：Matrix (18x3)
  /// 輸出：
  ///   Matrix (18x1)，每一列為該色塊的 RMSE
  Matrix calculateOriginalError(Matrix deviceRGB, Matrix targetRGB) {
    return Matrix.fromList(List.generate(deviceRGB.rowCount, (i) {
      final r = targetRGB[i][0] - deviceRGB[i][0];
      final g = targetRGB[i][1] - deviceRGB[i][1];
      final b = targetRGB[i][2] - deviceRGB[i][2];
      return [sqrt(r * r + g * g + b * b)];
    }));
  }

  @override
  void initState() {
    super.initState();
    final calculator = CCMCalculator();
    final deviceRGB = Matrix.fromList(widget.deviceRGBData);
    final targetRGB = Matrix.fromList(widget.targetRGBData);
    final results = calculator.calculateCCMs(deviceRGB, targetRGB);
    _olsCCM = results['olsCCM'];
    _olsError = results['olsError'];
    _originalError = calculateOriginalError(deviceRGB, targetRGB);
    _predictedRGB = (_olsCCM != null)
        ? (deviceRGB * _olsCCM!).mapElements((v) => v.clamp(0.0, 255.0))
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CCM Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OLS CCM:'), Text(formatMatrix(_olsCCM)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OLS Error:'), Text(formatMatrix(_olsError, 10)),
                    ],
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Original Error:'), Text(formatMatrix(_originalError, 10)),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Original RGB (前3):'),
              Text(formatMatrix(Matrix.fromList(widget.deviceRGBData.sublist(0, 3)))),
              const SizedBox(height: 8),
              const Text('Predicted RGB (前3):'),
              Text(formatMatrix(_predictedRGB, 3)),
              const SizedBox(height: 8),
              const Text('Target RGB (前3):'),
              Text(formatMatrix(Matrix.fromList(widget.targetRGBData.sublist(0, 3)))),
            ],
          ),
        ),
      ),
    );
  }
}