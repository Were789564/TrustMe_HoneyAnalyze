import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();

  String? _errorText;
  bool _loading = false;
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 蜂蜜圖示
                    Icon(
                      Icons.local_florist,
                      size: screenWidth * 0.25,
                      color: Colors.yellow.shade700,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // 標題
                    Text(
                      "Trust蜜",
                      style: TextStyle(
                        fontSize: screenWidth * 0.15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black45,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "蜂蜜檢測系統",
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black45,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    // 帳號欄位
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withAlpha(230),
                        hintText: '帳號',
                        prefixIcon:
                            Icon(Icons.person, color: Colors.orangeAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    // 密碼欄位
                    TextField(
                      controller: _pwdController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withAlpha(230),
                        hintText: '密碼',
                        prefixIcon:
                            Icon(Icons.lock, color: Colors.orangeAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.04),
                    // 登入按鈕
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _loading = true;
                                _errorText = null;
                              });
                              final user = User(
                                username: _userController.text.trim(),
                                password: _pwdController.text.trim(),
                              );
                              final success = await _controller.login(user);
                              setState(() {
                                _loading = false;
                              });
                              if (success) {
                                Navigator.pushReplacementNamed(
                                    context, '/home');
                              } else {
                                setState(() {
                                  _errorText = "帳號或密碼錯誤";
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withAlpha(230),
                              minimumSize:
                                  Size(screenWidth * 0.7, screenHeight * 0.07),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              elevation: 8,
                              shadowColor: Colors.orangeAccent.withAlpha(230),
                            ),
                            child: Text(
                              "登入",
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
