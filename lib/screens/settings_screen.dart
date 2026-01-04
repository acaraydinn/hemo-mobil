import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Merkezi sabitler
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  String phone = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDataForEdit();
  }

  // 1. Verileri API'den Çekip Doldur
  Future<void> _fetchUserDataForEdit() async {
    final prefs = await SharedPreferences.getInstance();
    phone = prefs.getString('userPhone') ?? "";

    if (phone.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/user-profile/?phone=$phone'));

      if (response.statusCode == 200) {
        // UTF-8 decoding eklendi
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (mounted) {
          setState(() {
            _nameController.text = data['first_name'] ?? "";
            _surnameController.text = data['last_name'] ?? "";
            _emailController.text = data['email'] ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("Ayarlar veri çekme hatası: $e");
    }
  }

  // 2. Profili Güncelle
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
          Uri.parse('${ApiConstants.baseUrl}/update-profile/'),
          body: {
            'phone': phone,
            'first_name': _nameController.text,
            'last_name': _surnameController.text,
            'email': _emailController.text,
          }
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', "${_nameController.text} ${_surnameController.text}");
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil Güncellendi ✅"), backgroundColor: Colors.green));
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güncelleme başarısız."), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Profil güncelleme hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Şifre Değiştirme
  Future<void> _changePassword() async {
    try {
      final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/change-password/'),
          body: {
            'phone': phone,
            'old_password': _oldPassController.text,
            'new_password': _newPassController.text,
          }
      );

      if (response.statusCode == 200) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre başarıyla değişti ✅"), backgroundColor: Colors.green));
        }
        _oldPassController.clear();
        _newPassController.clear();
      } else {
        if(mounted) {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorData['error'] ?? "Eski şifre yanlış."), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Şifre değiştirme hatası: $e");
    }
  }

  // --- UI YARDIMCILARI ---

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Şifre Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _oldPassController, obscureText: true, decoration: const InputDecoration(labelText: "Eski Şifre")),
            const SizedBox(height: 10),
            TextField(controller: _newPassController, obscureText: true, decoration: const InputDecoration(labelText: "Yeni Şifre")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _changePassword();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Tüm verileri temizle
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  Future<void> _launchWeb() async {
    final Uri url = Uri.parse('https://ubasoft.com.tr');
    if (!await launchUrl(url)) throw 'Açılamadı';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Ayarlar", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("PROFİLİ DÜZENLE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
            child: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Ad", prefixIcon: Icon(Icons.person, color: Color(0xFFD32F2F)))),
                const SizedBox(height: 10),
                TextField(controller: _surnameController, decoration: const InputDecoration(labelText: "Soyad", prefixIcon: Icon(Icons.person_outline, color: Color(0xFFD32F2F)))),
                const SizedBox(height: 10),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-Posta", prefixIcon: Icon(Icons.email, color: Color(0xFFD32F2F)))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("GÜVENLİK & DİĞER", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text("Şifre Değiştir"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text("Hakkımızda (ubasoft.com.tr)"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _launchWeb,
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}