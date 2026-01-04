import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // EKLENDİ: Metinleri düzeltmek için
import '../utils/constants.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _kvkkAccepted = false;

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedCity;
  String? _selectedBloodType;

  final List<String> _cities = ['Adana', 'Ankara', 'İstanbul', 'İzmir', 'Bursa', 'Antalya', 'Tokat', 'Samsun'];
  final List<String> _bloodTypes = ['A Rh+', 'A Rh-', 'B Rh+', 'B Rh-', 'AB Rh+', 'AB Rh-', '0 Rh+', '0 Rh-'];

  final Map<String, String> _bloodTypeMapping = {
    'A Rh+': 'A+', 'A Rh-': 'A-',
    'B Rh+': 'B+', 'B Rh-': 'B-',
    'AB Rh+': 'AB+', 'AB Rh-': 'AB-',
    '0 Rh+': '0+', '0 Rh-': '0-',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- HUKUKİ METİNLERİ BACKEND'DEN ÇEKME ---
  void _fetchAndShowLegal(String slug, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
    );

    try {
      final response = await http.get(Uri.parse(ApiConstants.contracts(slug)));

      if (!mounted) return;
      Navigator.pop(context); // Yükleme dialogunu kapat

      if (response.statusCode == 200) {
        String content = utf8.decode(response.bodyBytes);

        // --- KRİTİK DÜZELTME ---
        // Backend'den gelen metni temizliyoruz.
        // Tırnak işaretlerini kaldır, \r\n karakterlerini gerçek satıra çevir.
        content = content
            .replaceAll(r'\r\n', '\n') // Windows tarzı yeni satırları düzelt
            .replaceAll(r'\n', '\n')   // Normal yeni satırları düzelt
            .replaceAll('"', '');      // JSON tırnaklarını temizle

        _showLegalBottomSheet(title, content);
      } else {
        _showSnackBar("Metin şu an yüklenemedi.", Colors.orange);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Bağlantı hatası: Metin yüklenemedi.", Colors.red);
    }
  }

  // --- KAYIT FONKSİYONU ---
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_kvkkAccepted) {
      _showSnackBar('Lütfen sözleşmeleri onaylayın.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("Token Hatası: $e");
      }

      final Map<String, dynamic> registerData = {
        'first_name': _nameController.text.trim(),
        'last_name': _surnameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'city': _selectedCity,
        'blood_type': _bloodTypeMapping[_selectedBloodType],
        'password': _passwordController.text,
        'fcm_token': fcmToken,
      };

      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          _showSnackBar("Kayıt başarılı! Doğrulama kodunuz gönderildi.", Colors.green);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phone: _phoneController.text.trim(),
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        String errorMsg = errorData['phone'] != null ? "Bu numara zaten kayıtlı." : "Kayıt başarısız.";
        _showSnackBar(errorMsg, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Sunucu hatası: Lütfen internetinizi kontrol edin.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // UI Yardımcı Fonksiyonları
  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  // --- SÖZLEŞME GÖSTERİMİ (DÜZELTİLEN YER) ---
  void _showLegalBottomSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // Biraz daha yükselttim
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
            const Divider(height: 30),

            // Text yerine Markdown kullanıyoruz
            Expanded(
              child: Markdown(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(color: Color(0xFFD32F2F), fontSize: 20, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                  p: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("OKUDUM, ANLADIM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Yeni Kahraman Kaydı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFD32F2F),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Hayat kurtarmak için ilk adımı atın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_nameController, "Ad", Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_surnameController, "Soyad", Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: _inputDecoration("Telefon (05xxxxxxxxx)", Icons.phone).copyWith(counterText: ""),
                  validator: (value) => (value == null || value.length < 10) ? 'Geçerli bir numara girin' : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(_emailController, "E-posta", Icons.email, isEmail: true),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Şehir", Icons.location_city),
                  value: _selectedCity,
                  items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                  onChanged: (value) => setState(() => _selectedCity = value),
                  validator: (value) => value == null ? 'Şehir seçiniz' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Kan Grubu", Icons.bloodtype),
                  value: _selectedBloodType,
                  items: _bloodTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setState(() => _selectedBloodType = value),
                  validator: (value) => value == null ? 'Kan grubu seçiniz' : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(_passwordController, "Şifre", Icons.lock, isPassword: true),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24, width: 24,
                      child: Checkbox(
                        value: _kvkkAccepted,
                        activeColor: const Color(0xFFD32F2F),
                        onChanged: (value) => setState(() => _kvkkAccepted = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        children: [
                          _legalLink("Kullanım Koşulları", () => _fetchAndShowLegal('kullanim-kosullari', 'Kullanım Koşulları')),
                          const Text(" , "),
                          _legalLink("Gizlilik Politikası", () => _fetchAndShowLegal('gizlilik-politikasi', 'Gizlilik Politikası')),
                          const Text(" ve "),
                          _legalLink("KVKK", () => _fetchAndShowLegal('kvkk-aydinlatma-metni', 'KVKK Aydınlatma Metni')),
                          const Text(" metinlerini okudum, onaylıyorum."),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("KAYIT OL VE DEVAM ET", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 25),
                const Center(child: Text("from UBASOFT", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 3))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legalLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 12)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Gerekli';
        if (isEmail && !value.contains('@')) return 'Geçersiz e-posta';
        if (isPassword && value.length < 6) return 'En az 6 karakter';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}