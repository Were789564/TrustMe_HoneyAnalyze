import 'package:flutter/material.dart';

/// 檢測歷史紀錄顯示畫面
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("檢測歷史紀錄"),
      )
    );
  }
}
