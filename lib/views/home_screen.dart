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
                colors: [Colors.orangeAccent, Colors.yellowAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 蜂蜜圖示
                  Icon(
                    Icons.local_florist,
                    size: screenWidth * 0.25,
                    color: Colors.yellow.shade700,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  // 標題
                  CircleAvatar(
                    radius: screenWidth * 0.15,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: screenWidth * 0.15,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // 功能按鈕區塊
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Column(
                      children: [
                        HomeFeatureCard(
                          icon: Icons.movie_filter,
                          title: "影片分析",
                          color: Colors.deepOrangeAccent,
                          onTap: () {
                            Navigator.pushNamed(context, '/video_analyze');
                          },
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        HomeFeatureCard(
                          icon: Icons.camera_alt,
                          title: "即時分析",
                          color: Colors.amber,
                          onTap: () {
                            Navigator.pushNamed(context, '/realtime_analyze');
                          },
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        HomeFeatureCard(
                          icon: Icons.history,
                          title: "查看檢測紀錄",
                          color: Colors.purpleAccent,
                          onTap: () {
                            Navigator.pushNamed(context, '/history');
                          },
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        HomeFeatureCard(
                          icon: Icons.logout,
                          title: "登出",
                          color: Colors.grey,
                          onTap: () {
                            // TODO: 執行登出
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
