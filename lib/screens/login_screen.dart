import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/constants.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. İZİN VE TOKEN İŞLEMLERİ
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("Token Hatası: $e");
      }

      // 2. LOGİN İSTEĞİ
      final Map<String, dynamic> bodyData = {
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'fcm_token': fcmToken,
        'registration_id': fcmToken,
        'device_type': Platform.isIOS ? 'ios' : 'android',
        'active': true,
      };

      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // --- 🔥 DÜZELTİLEN KISIM: Anahtar 'phone' olarak sabitlendi ---
        // Backend'den dönen numarayı veya kullanıcının girdiğini kaydediyoruz
        await prefs.setString('phone', decodedData['phone'] ?? _phoneController.text.trim());

        String fullName = "${decodedData['first_name'] ?? ""} ${decodedData['last_name'] ?? ""}";
        await prefs.setString('userName', fullName.trim());
        await prefs.setInt('userPoints', decodedData['points'] ?? 0);
        await prefs.setString('userBadge', decodedData['badge'] ?? 'Gönüllü');

        if (fcmToken != null) await prefs.setString('fcmToken', fcmToken);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş Başarılı!'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          _showErrorSnackBar(errorData['error'] ?? 'Giriş başarısız oldu.');
        }
      }
    } catch (e) {
      debugPrint("Kritik Hata: $e");
      if (mounted) {
        _showErrorSnackBar('Sunucu hatası veya bağlantı yok.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.bloodtype, size: 90, color: Color(0xFFD32F2F)),
                  const SizedBox(height: 10),
                  const Text(
                      "HEMO",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F), letterSpacing: 4)
                  ),
                  const Text(
                      "Hayat Kurtaran Bağlantı",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14)
                  ),
                  const SizedBox(height: 50),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    decoration: _inputDecoration('Telefon Numarası', Icons.phone_android),
                    validator: (value) => (value == null || value.isEmpty) ? 'Lütfen telefon girin' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Şifre', Icons.lock),
                    validator: (value) => (value == null || value.isEmpty) ? 'Lütfen şifre girin' : null,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("GİRİŞ YAP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Hesabın yok mu? ", style: TextStyle(color: Colors.black54)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                        },
                        child: const Text(
                            "Hemen Kaydol",
                            style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Center(child: Text("from UBASOFT", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 3))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFFD32F2F)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2)),
      counterText: "",
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}