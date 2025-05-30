import 'package:flutter/material.dart';

/// 自定義對話框元件，支持標題、內容、進度條和百分比顯示
class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onClose;
  final bool isLoading;
  final bool showProgressBar;
  final double? progress;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.onClose,
    this.isLoading = false,
    this.showProgressBar = false,
    this.progress,
  });

  /// 構建自定義對話框 UI
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white.withAlpha((1 * 255).toInt()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.yellowAccent,
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading || showProgressBar)
              Column(
                children: [
                  LinearProgressIndicator(
                    minHeight: 8,
                    backgroundColor: const Color(0xFFFFF9C4),
                    color: const Color(0xFFFFF176),
                    value: (progress != null && progress! >= 0 && progress! <= 1) ? progress : null,
                  ),
                  const SizedBox(height: 16),
                  // 顯示百分比
                  Text(
                    progress != null
                        ? "${(progress! * 100).toStringAsFixed(0)}%"
                        : content,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF444444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF444444),
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700]?.withAlpha((0.9 * 255).toInt()),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: onClose ?? () => Navigator.of(context).pop(),
                child: const Text(
                  "關閉",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
