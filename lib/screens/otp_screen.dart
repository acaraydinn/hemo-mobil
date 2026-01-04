import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart'; // Merkezi sabitler eklendi
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String email;

  const OtpScreen({super.key, required this.phone, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  // Doğrulama Fonksiyonu
  Future<void> _verifyCode() async {
    String code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 6 haneli kodu eksiksiz girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ApiConstants üzerinden verify-otp endpoint'ine bağlanıyoruz
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        // BAŞARILI!
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userPhone', widget.phone);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş Başarılı! Hoş geldin Kahraman.')),
          );

          // Anasayfaya yönlendir ve geçmişi temizle (Geri tuşuyla OTP'ye dönülmesin)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        }
      } else {
        if (mounted) {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['error'] ?? 'Hatalı Kod! Lütfen tekrar deneyin.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı Hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView( // Klavye açılınca taşma olmaması için eklendi
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.mark_email_read, size: 80, color: Color(0xFFD32F2F)),
                const SizedBox(height: 20),
                const Text(
                  "Doğrulama Kodu",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "${widget.email} adresine gönderilen\n6 haneli kodu giriniz.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "------",
                    hintStyle: TextStyle(color: Colors.grey.shade300),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("DOĞRULA VE GİRİŞ YAP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kod tekrar gönderildi (Simülasyon)")));
                  },
                  child: const Text("Kod gelmedi mi? Tekrar Gönder", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}