import 'package:flutter/material.dart';
import '../widgets/home_feature_card.dart';

/// 應用主頁畫面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 背景漸層
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFDBB5), Color(0xFF8B4513)], // 皮膚色到棕色
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.08), // 加入頂部間距
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 標題
                  Image.asset(
                    'assets/images/logo.png',
                    width: screenWidth,
                    height: screenWidth * 0.8,
                  ),
                  SizedBox(height: screenHeight * 0.01),

                  // 功能按鈕區塊
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      children: [
                        HomeFeatureCard(
                          icon: Icons.movie_filter,
                          title: "影片分析",
                          color: const Color.fromARGB(255, 241, 204, 147),
                          backgroundColor: Color(0xFF8B4513), // 棕色背景
                          onTap: () {
                            Navigator.pushNamed(context, '/video_analyze');
                          },
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        HomeFeatureCard(
                          icon: Icons.history,
                          title: "查看檢測紀錄",
                          color: const Color.fromARGB(255, 241, 204, 147),
                          backgroundColor: Color(0xFF8B4513), // 棕色背景
                          onTap: () {
                            Navigator.pushNamed(context, '/history');
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}