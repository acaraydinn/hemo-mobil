import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'ad_detail_screen.dart';
import 'create_ad_screen.dart';

class BloodRequestsList extends StatefulWidget {
  const BloodRequestsList({super.key});

  @override
  State<BloodRequestsList> createState() => _BloodRequestsListState();
}

class _BloodRequestsListState extends State<BloodRequestsList> {
  List<dynamic> _ads = [];
  bool _isLoading = true;
  List<String> _cities = [];
  String _currentCity = "Tüm Türkiye";
  String currentUserPhone = "";

  final Map<String, String> productDisplayNames = {
    'tam_kan': 'Tam Kan',
    'eritrosit': 'Eritrosit',
    'trombosit': 'Trombosit',
    'plazma': 'Plazma',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchCities();
  }

  // --- 1. KULLANICI YÜKLEME ---
  Future<void> _loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserPhone = prefs.getString('phone') ?? "";
    });
    debugPrint("--- AKTİF KULLANICI: $currentUserPhone ---");
    _fetchAds();
  }

  // --- 2. API FONKSİYONLARI ---
  Future<void> _fetchCities() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/cities/'));
      if (response.statusCode == 200) {
        List<dynamic> rawList = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _cities = ["Tüm Türkiye", ...List<String>.from(rawList)];
          });
        }
      }
    } catch (e) {
      debugPrint("Şehir çekme hatası: $e");
    }
  }

  Future<void> _fetchAds() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String url = '${ApiConstants.baseUrl}/blood-requests/?viewer_phone=$currentUserPhone';
    if (_currentCity != "Tüm Türkiye") {
      url += '&city=$_currentCity';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _ads = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("İlan çekme hatası: $e");
    }
  }

  // --- 🔥 GÜVENLİ ENGELLEME FONKSİYONU ---
  // (İçinde Navigator.pop YOK)
  Future<void> _blockUser(int blockedUserId, String blockedUserName) async {
    if (currentUserPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata: Oturum bilgisi bulunamadı.")));
      return;
    }

    // Yükleniyor göstergesi (Opsiyonel)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem yapılıyor..."), duration: Duration(milliseconds: 500)));

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.blockUser),
        body: {
          'blocker_phone': currentUserPhone,
          'blocked_user_id': blockedUserId.toString(),
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Önceki mesajı kaldır
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$blockedUserName engellendi."), backgroundColor: Colors.black),
          );
          _fetchAds(); // Listeyi yenile
        }
      } else {
        debugPrint("Engelleme hatası: ${response.body}");
      }
    } catch (e) {
      debugPrint("Bağlantı hatası: $e");
    }
  }

  // --- 🔥 GÜVENLİ ŞİKAYET FONKSİYONU ---
  // (İçinde Navigator.pop YOK)
  Future<void> _reportContent(int requestId, String reason) async {
    if (currentUserPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata: Oturum bilgisi bulunamadı.")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.reportContent),
        body: {
          'reporter_phone': currentUserPhone,
          'blood_request_id': requestId.toString(),
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Şikayetiniz alındı. Teşekkürler."), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint("Şikayet hatası: $e");
    }
  }

  // --- 3. DİYALOGLAR (PENCEREYİ BURADA KAPATIYORUZ) ---

  void _showReportDialog(int requestId) {
    String selectedReason = "Uygunsuz İçerik";
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("İlanı Şikayet Et"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Lütfen şikayet nedeninizi seçin:"),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: ["Uygunsuz İçerik", "Dolandırıcılık", "Hakaret / Küfür", "Yanlış Bilgi"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedReason = val!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                  onPressed: () {
                    // 🔥 1. ÖNCE PENCEREYİ KAPAT
                    Navigator.of(ctx).pop();

                    // 🔥 2. SONRA FONKSİYONU ÇAĞIR
                    // (Böylece fonksiyonun içinde tekrar kapatmaya çalışmayız)
                    _reportContent(requestId, selectedReason);
                  },
                  child: const Text("GÖNDER", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showBlockDialog(int blockedUserId, String name) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Kullanıcıyı Engelle"),
          content: Text("$name adlı kullanıcıyı engellemek istiyor musunuz? İlanlarını bir daha görmeyeceksiniz."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // 🔥 1. ÖNCE PENCEREYİ KAPAT
                Navigator.of(ctx).pop();

                // 🔥 2. SONRA FONKSİYONU ÇAĞIR
                _blockUser(blockedUserId, name);
              },
              child: const Text("ENGELLE", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  void _showCityFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text("Şehir Seçiniz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _cities.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                  : ListView.builder(
                itemCount: _cities.length,
                itemBuilder: (context, index) {
                  final city = _cities[index];
                  return ListTile(
                    title: Text(city),
                    leading: city == _currentCity
                        ? const Icon(Icons.radio_button_checked, color: Color(0xFFD32F2F))
                        : const Icon(Icons.radio_button_off),
                    onTap: () {
                      setState(() => _currentCity = city);
                      Navigator.pop(context);
                      _fetchAds();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 4. UI KISMI (AYNI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("HEMO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 3, color: Color(0xFFD32F2F))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAdScreen()))
              .then((_) => _fetchAds());
        },
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(Icons.add),
        label: const Text("İlan Ver"),
      ),
      body: Column(
        children: [
          InkWell(
            onTap: _showCityFilterDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 20),
                  const SizedBox(width: 8),
                  Text(_currentCity, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  const Spacer(),
                  Text("${_ads.length} İlan", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                : _ads.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _fetchAds,
              color: const Color(0xFFD32F2F),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _ads.length,
                itemBuilder: (context, index) {
                  return _buildAdCard(_ads[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(dynamic ad) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdDetailScreen(ad: ad))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]),
                child: Center(
                  child: Text(
                    ad['blood_type'] ?? '?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ad['hospital'] ?? 'Hastane Belirtilmedi',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ad['blood_product'] != 'tam_kan')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(left: 5),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                            child: Text(productDisplayNames[ad['blood_product']] ?? '', style: TextStyle(color: Colors.blue[800], fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("${ad['city']} / ${ad['district']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text("${ad['patient_first_name']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'sikayet') {
                    _showReportDialog(ad['id']);
                  } else if (value == 'engelle') {
                    String userName = "${ad['first_name'] ?? ''} ${ad['last_name'] ?? ''}";
                    _showBlockDialog(ad['user_id'], userName);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'sikayet',
                    child: Row(children: [Icon(Icons.flag, color: Colors.red, size: 20), SizedBox(width: 10), Text('İlanı Şikayet Et')]),
                  ),
                  const PopupMenuItem<String>(
                    value: 'engelle',
                    child: Row(children: [Icon(Icons.block, color: Colors.black, size: 20), SizedBox(width: 10), Text('Kullanıcıyı Engelle')]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("Bu konumda acil ihtiyaç yok.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          TextButton(
            onPressed: () {
              setState(() => _currentCity = "Tüm Türkiye");
              _fetchAds();
            },
            child: const Text("Tümünü Göster", style: TextStyle(color: Color(0xFFD32F2F))),
          )
        ],
      ),
    );
  }
}