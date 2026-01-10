import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Resim seçmek için
import 'package:path_provider/path_provider.dart'; // Resmi kaydetmek için
import 'package:flutter_markdown/flutter_markdown.dart'; // EKLENDİ: Metinleri düzeltmek için

import '../utils/constants.dart';
import '../utils/gamification_helper.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String userName = "Yükleniyor...";
  String userPhone = "";
  int userPoints = 0;
  File? _profileImage; // Ekranda gösterilecek yerel dosya

  List<dynamic> activeAds = [];
  List<dynamic> pastAds = [];
  List<dynamic> myDonations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocalData();
  }

  // --- YEREL VERİ VE RESİM YÜKLEME ---
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 🔥 BUG FIX: 'userPhone' yerine 'phone' kullanılmalı (login'de 'phone' ile kaydediliyor)
      userPhone = prefs.getString('phone') ?? "";
      userName = prefs.getString('userName') ?? "Kullanıcı";

      // Kaydedilmiş resim yolunu kontrol et
      String? savedImagePath = prefs.getString('profile_image_path');
      if (savedImagePath != null) {
        final File imageFile = File(savedImagePath);
        if (imageFile.existsSync()) {
          _profileImage = imageFile;
        }
      }
    });

    if (userPhone.isNotEmpty) {
      _refreshUserDataFromApi();
      _fetchMyAds();
      _fetchMyDonations();
    }
  }

  // --- PROFİL FOTOĞRAFI SEÇME VE KAYDETME ---
  Future<void> _pickAndSaveImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      // Galeriyi aç
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return; // Seçim yapılmadıysa çık

      // Uygulamanın kalıcı belge dizinini bul
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_photo.jpg'; // Sabit isim (her seferinde üzerine yazar)
      final String newPath = '${appDir.path}/$fileName';

      // Geçici dosyayı kalıcı yere kopyala
      final File localFile = await File(pickedFile.path).copy(newPath);

      // Yolu hafızaya kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', newPath);

      // Ekranda güncelle
      setState(() {
        _profileImage = localFile;
      });

      _showSnackBar("Profil fotoğrafı güncellendi!", Colors.green);
    } catch (e) {
      _showSnackBar("Fotoğraf yüklenirken hata oluştu.", Colors.red);
      print("Resim hatası: $e");
    }
  }

  // --- API İŞLEMLERİ ---

  Future<void> _refreshUserDataFromApi() async {
    try {
      // ApiConstants.userProfile fonksiyonunu kullandık
      final response = await http.get(Uri.parse(ApiConstants.userProfile(userPhone)));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            userPoints = data['points'] ?? 0;
            userName = "${data['first_name']} ${data['last_name']}";
          });
          final prefs = await SharedPreferences.getInstance();
          prefs.setInt('userPoints', userPoints);
          prefs.setString('userName', userName);
        }
      }
    } catch (e) { print("Profil API hatası: $e"); }
  }

  Future<void> _fetchMyAds() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.myRequests}?phone=$userPhone'));
      if (response.statusCode == 200) {
        final List<dynamic> allAds = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            activeAds = allAds.where((ad) => ad['is_active'] == true).toList();
            pastAds = allAds.where((ad) => ad['is_active'] == false).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _fetchMyDonations() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.myDonations}?phone=$userPhone'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            myDonations = json.decode(utf8.decode(response.bodyBytes));
          });
        }
      }
    } catch (e) { print("Bağış API hatası: $e"); }
  }

  // --- HUKUKİ METİN ÇEKME (DÜZENLENDİ) ---
  void _showLegalContent(String slug, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
    );

    try {
      final response = await http.get(Uri.parse(ApiConstants.contracts(slug)));
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        String content = utf8.decode(response.bodyBytes);

        // --- KRİTİK DÜZELTME ---
        // Register ekranındaki gibi temizlik yapıyoruz
        content = content
            .replaceAll(r'\r\n', '\n') // Windows satır sonları
            .replaceAll(r'\n', '\n')   // Normal satır sonları
            .replaceAll('"', '');      // JSON tırnakları

        _showLegalBottomSheet(title, content);
      } else {
        _showSnackBar("İçerik bulunamadı.", Colors.orange);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Bağlantı hatası.", Colors.red);
    }
  }

  // --- YÖNETİM AKSİYONLARI ---

  Future<void> _closeAd(int adId) async {
    try {
      // ApiConstants.deleteRequest fonksiyonunu kullandık
      final response = await http.delete(Uri.parse(ApiConstants.deleteRequest(adId)));
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar("İhtiyaç karşılandı olarak işaretlendi.", Colors.green);
          _fetchMyAds();
        }
      }
    } catch (e) { _showSnackBar("Hata oluştu!", Colors.red); }
  }

  Future<void> _approveDonor(int donationId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.approveDonation),
        body: {'donation_id': donationId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(data['message'] ?? "Bağış onaylandı!", Colors.green);
          _refreshUserDataFromApi(); // Puan güncellensin diye
          _fetchMyAds();
        }
      }
    } catch (e) { _showSnackBar("Bağlantı hatası", Colors.red); }
  }

  Future<void> _deleteAccountRequest() async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.deleteAccount),
        body: {'phone': userPhone},
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) { _showSnackBar("Hesap silinemedi.", Colors.red); }
  }

  // --- ARAYÜZ ---

  @override
  Widget build(BuildContext context) {
    UserLevel levelInfo = GamificationHelper.getLevelInfo(userPoints);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text("Profilim", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) => _loadLocalData()),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(levelInfo),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFD32F2F), unselectedLabelColor: Colors.grey, indicatorColor: const Color(0xFFD32F2F),
              tabs: const [Tab(text: "İlanlarım"), Tab(text: "Bağışlarım")],
            ),
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [_buildAdsTab(), _buildDonationsTab()],
              ),
            ),
            const Divider(),
            _buildLegalAndAccountSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserLevel levelInfo) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profil Resmi Alanı (Tıklanabilir)
          GestureDetector(
            onTap: _pickAndSaveImage, // Tıklayınca galeri açılır
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(children: [Text(levelInfo.badge, style: const TextStyle(fontSize: 28)), const SizedBox(width: 8), Text(levelInfo.title, style: TextStyle(color: levelInfo.color, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 5),
                LinearProgressIndicator(value: levelInfo.progress, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(levelInfo.color)),
                Text("$userPoints Puan", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- TAB İÇERİKLERİ ---

  Widget _buildAdsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (activeAds.isNotEmpty) ...[
          const Text("AKTİF İLANLAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
          ...activeAds.map((ad) => _buildAdCard(ad, true)).toList(),
        ],
        if (pastAds.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text("GEÇMİŞ İLANLAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ...pastAds.map((ad) => _buildAdCard(ad, false)).toList(),
        ],
        if (activeAds.isEmpty && pastAds.isEmpty) const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: Text("İlan bulunamadı."))),
      ],
    );
  }

  Widget _buildDonationsTab() {
    if (myDonations.isEmpty) return const Center(child: Text("Bağış kaydı bulunamadı."));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: myDonations.length,
      itemBuilder: (context, index) {
        final d = myDonations[index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.favorite, color: d['status_code'] == 'approved' ? Colors.green : Colors.orange),
            title: Text(d['hospital']),
            subtitle: Text(d['date']),
            trailing: Text(d['status']),
          ),
        );
      },
    );
  }

  Widget _buildAdCard(dynamic ad, bool isActive) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: isActive ? () => _showAdManagementSheet(ad) : null,
        leading: CircleAvatar(backgroundColor: isActive ? const Color(0xFFD32F2F) : Colors.grey, child: Text(ad['blood_type'], style: const TextStyle(color: Colors.white, fontSize: 12))),
        title: Text(ad['hospital'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${ad['city']} / ${ad['district']}"),
        trailing: isActive ? const Icon(Icons.settings, size: 20) : null,
      ),
    );
  }

  // --- DİĞER YARDIMCILAR ---

  void _showAdManagementSheet(dynamic ad) async {
    List<dynamic> donors = [];
    try {
      final response = await http.get(Uri.parse(ApiConstants.requestDonors(ad['id'])));
      if (response.statusCode == 200) {
        donors = json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) { print(e); }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(ad['hospital'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const Divider(height: 30),
              const Text("Gelen Kahraman Talepleri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              donors.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("Henüz bir başvuru yok.", style: TextStyle(color: Colors.grey)))
                  : Column(
                children: donors.map((d) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFEE2E2), child: Icon(Icons.person, color: Color(0xFFD32F2F))),
                  title: Text(d['donor_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: ElevatedButton(
                    onPressed: () => _approveDonor(d['donation_id']),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                    child: const Text("ONAYLA"),
                  ),
                )).toList(),
              ),
              const Divider(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _closeAd(ad['id']),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text("İHTİYAÇ KARŞILANDI (KAPAT)"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // --- SÖZLEŞME GÖSTERİMİ (DÜZENLENDİ) ---
  void _showLegalBottomSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            // Text widget'ı yerine Markdown kullanıyoruz
            Expanded(
              child: Markdown(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(color: Color(0xFFD32F2F), fontSize: 20, fontWeight: FontWeight.bold),
                  p: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
                child: const Text("ANLADIM"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegalAndAccountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 10),
            child: Text("YASAL & HESAP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          ),
          _legalTile(Icons.description_outlined, "Kullanım Koşulları", "kullanim-kosullari"),
          _legalTile(Icons.privacy_tip_outlined, "Gizlilik Politikası", "gizlilik-politikasi"),
          _legalTile(Icons.gavel_outlined, "KVKK Aydınlatma Metni", "kvkk-aydinlatma-metni"),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Hesabı Sil"),
                    content: const Text("Tüm verileriniz kalıcı olarak silinecektir. Bu işlem geri alınamaz."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("VAZGEÇ")),
                      TextButton(onPressed: _deleteAccountRequest, child: const Text("SİL", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
              label: const Text("Hesabımı ve Verilerimi Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 15),
          const Center(child: Text("from UBASOFT", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 3))),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _legalTile(IconData icon, String title, String slug) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFFD32F2F), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _showLegalContent(slug, title),
    );
  }
}