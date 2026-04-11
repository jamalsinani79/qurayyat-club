import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool isLoading = false;

  void handleLogin() async {
    final username = emailController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور')),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.login(
      username: username,
      password: password,
      deviceToken: 'dummy_device_token_123',
    );

    setState(() => isLoading = false);

    if (result['success']) {
      final user = result['user'];
      final token = result['token'];

      final prefs = await SharedPreferences.getInstance();

      // ✅ نحفظ البيانات فقط إذا تم تفعيل خيار "تذكرني"
      if (rememberMe) {
        await prefs.setString('auth_token', token);
        await prefs.setString('username', user['username']);
        await prefs.setInt('team_id', user['id']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('مرحبًا ${user['username']}')),
      );

      Get.offAllNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'فشل تسجيل الدخول')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'تسجيل الدخول',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/logo.png',
                width: 190,
                height: 190,
              ),
              const SizedBox(height: 20),

              // البريد الإلكتروني
              TextField(
                controller: emailController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email, color: Colors.orange),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // كلمة المرور
              TextField(
                controller: passwordController,
                obscureText: true,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 10),

              // سطر التذكير وكلمة المرور المنسية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('نسيت كلمة السر؟'),
                  ),
                  Row(
                    children: [
                      const Text('تذكرني'),
                      Checkbox(
                        value: rememberMe,
                        activeColor: Colors.orange,
                        onChanged: (value) {
                          setState(() => rememberMe = value!);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // زر الدخول
              Center(
                child: GestureDetector(
                  onTap: isLoading ? null : handleLogin,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isLoading ? Colors.orange[200] : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}  