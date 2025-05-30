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
          // 背景改為上到下漸變
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 235, 180), // 更淺的米色
                  Color.fromARGB(255, 200, 150, 70),  // 更深的鵝黃色
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 上方容器：Logo 區域
          Positioned(
            top: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 1,
                height: screenWidth * 0.8,
              ),
            ),
          ),
          // 表單區域
          Positioned(
            top: screenHeight * 0.4,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Container(
                height: screenHeight * 0.6,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.1,
                    screenHeight * 0.05,
                    screenWidth * 0.1,
                    screenHeight * 0.02,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      // 表單容器
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 帳號欄位
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _userController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  hintText: '帳號',
                                  hintStyle: TextStyle(color: Colors.brown.shade400),
                                  prefixIcon: Icon(Icons.person, color: Colors.brown.shade700),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            // 密碼欄位
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _pwdController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  hintText: '密碼',
                                  hintStyle: TextStyle(color: Colors.brown.shade400),
                                  prefixIcon: Icon(Icons.lock, color: Colors.brown.shade700),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    borderSide: BorderSide.none,
                                  ),
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
                                ? Container(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown.shade700),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 215, 161, 12),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        
                                      ],
                                    ),
                                    child: ElevatedButton(
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
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        minimumSize: Size(screenWidth * 0.7, screenHeight * 0.07),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30.0),
                                        ),
                                      ),
                                      child: Text(
                                        "登入",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
