import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
          // 半透明蜂巢圖案可考慮加在這裡
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
                  Text(
                    "蜂蜜檢測系統",
                    style: TextStyle(
                      fontSize: screenWidth * 0.075,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black26,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // 功能按鈕區塊
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Column(
                      children: [
                        _HomeFeatureCard(
                          icon: Icons.movie_filter,
                          title: "影片分析",
                          color: Colors.deepOrangeAccent,
                          onTap: () {
                            // TODO: 導向影片分析頁
                          },
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        _HomeFeatureCard(
                          icon: Icons.camera_alt,
                          title: "即時分析",
                          color: Colors.amber,
                          onTap: () {
                            // TODO: 導向即時分析頁
                          },
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        _HomeFeatureCard(
                          icon: Icons.history,
                          title: "查看檢測紀錄",
                          color: Colors.purpleAccent,
                          onTap: () {
                            // TODO: 導向檢測紀錄頁
                          },
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        _HomeFeatureCard(
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

// 卡片式功能按鈕元件
class _HomeFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _HomeFeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        color: Colors.white.withOpacity(0.93),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(12),
                child: Icon(icon, color: color, size: screenWidth * 0.08),
              ),
              SizedBox(width: 22),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}