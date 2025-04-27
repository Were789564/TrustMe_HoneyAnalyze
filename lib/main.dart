import 'package:flutter/material.dart';
import 'package:flutter_app/views/login_screen.dart';
import 'package:flutter_app/views/home_screen.dart';
import 'package:flutter_app/views/realtime_analyze_screen.dart';
import 'package:flutter_app/views/video_analyze_screen.dart';
import 'package:flutter_app/views/history_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  // 初始化相機
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       routes: {
          '/home': (context) => HomeScreen(),
          '/realtime_analyze': (context) => RealtimeAnalyzeScreen(), // 即時分析頁
          '/video_analyze': (context) => VideoAnalyzeScreen(), // 影片分析頁
          '/history': (context) => HistoryScreen(), // 檢測紀錄頁
          // 其他路由
      },
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.blue, // 主色
          secondary: Colors.green, // 輔助色
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16), // 更新為 bodyLarge
          bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14), // 更新為 bodyMedium
          headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 20), // 保持 headline6
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('zh', 'TW'),
        Locale('en', 'US'),
        Locale('en', 'US'),
        // 其他需要的語系
      ],
      home: LoginScreen(),
    );
  }
}
