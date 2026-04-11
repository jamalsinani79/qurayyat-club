import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // تأكد من مسار الاستيراد الصحيح

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => errorMessage = 'يرجى إدخال البريد الإلكتروني');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await AuthService.forgotPassword(email);

    setState(() => isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      Navigator.pop(context);
    } else {
      setState(() => errorMessage = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'استعادة كلمة المرور',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.orange,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Image.asset(
                'assets/images/logo.png',
                height: 190,
                width: 190,
              ),
              const SizedBox(height: 10),
              const Text(
                'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email, color: Colors.orange),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إرسال الرابط',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
