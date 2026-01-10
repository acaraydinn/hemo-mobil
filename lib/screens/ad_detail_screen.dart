import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Merkezi sabitler eklendi

class AdDetailScreen extends StatefulWidget {
  final dynamic ad;

  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  // --- BAĞIŞ SÜRECİ DEĞİŞKENLERİ ---
  String? currentUserPhone;
  bool isMyAd = false;
  List<dynamic> pendingDonors = [];
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _checkOwnershipAndData();
  }

  // Kullanıcı ve İlan Sahibi Kontrolü
  Future<void> _checkOwnershipAndData() async {
    final prefs = await SharedPreferences.getInstance();
    // 🔥 BUG FIX: 'userPhone' yerine 'phone' kullanılmalı
    currentUserPhone = prefs.getString('phone');

    if (mounted) {
      setState(() {
        isMyAd = widget.ad['contact_phone'] == currentUserPhone;
      });
    }

    if (isMyAd) {
      _fetchPendingDonors();
    }
  }

  // BAĞIŞÇI: Kan Vermeye Gidiyorum İşlemi
  Future<void> _sendDonationRequest() async {
    if (currentUserPhone == null) {
      _showSnackBar("Lütfen önce giriş yapın.", Colors.orange);
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/donate/'), // Merkezi IP kullanımı
        body: {
          'phone': currentUserPhone,
          'request_id': widget.ad['id'].toString(),
        },
      );

      if (response.statusCode == 201) {
        if (mounted) _showSnackBar("Bağış talebiniz iletildi! Teşekkürler ❤️", Colors.green);
      } else {
        final errorMsg = json.decode(utf8.decode(response.bodyBytes))['error'] ?? "Bir hata oluştu.";
        if (mounted) _showSnackBar(errorMsg, Colors.orange);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Bağlantı hatası!", Colors.red);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // İLAN SAHİBİ: Gelen Talepleri Çek
  Future<void> _fetchPendingDonors() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/request-donors/${widget.ad['id']}/'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            pendingDonors = json.decode(utf8.decode(response.bodyBytes));
          });
        }
      }
    } catch (e) {
      print("Talep çekme hatası: $e");
    }
  }

  // İLAN SAHİBİ: Bağışı Onayla (Puan verme işlemi)
  Future<void> _approveDonation(int donationId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/approve-donation/'),
        body: {'donation_id': donationId.toString()},
      );

      if (response.statusCode == 200) {
        if (mounted) _showSnackBar("Bağış onaylandı, kahramana puanı verildi! 🎉", Colors.green);
        _fetchPendingDonors(); // Listeyi güncelle
      }
    } catch (e) {
      _showSnackBar("Onay işlemi başarısız.", Colors.red);
    }
  }

  // --- 🔥 ENGELLEME VE ŞİKAYET FONKSİYONLARI ---

  Future<void> _blockUser(int blockedUserId, String blockedUserName) async {
    if (currentUserPhone == null || currentUserPhone!.isEmpty) {
      _showSnackBar("Lütfen önce giriş yapın.", Colors.orange);
      return;
    }

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
          _showSnackBar("$blockedUserName engellendi. İlanlarını artık görmeyeceksiniz.", Colors.black);
          Navigator.pop(context); // Detay ekranından çık
        }
      } else {
        _showSnackBar("Engelleme işlemi başarısız oldu.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Bağlantı hatası!", Colors.red);
    }
  }

  Future<void> _reportContent(int requestId, String reason) async {
    if (currentUserPhone == null || currentUserPhone!.isEmpty) {
      _showSnackBar("Lütfen önce giriş yapın.", Colors.orange);
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
          _showSnackBar("Şikayetiniz alındı. 24 saat içinde incelenecektir.", Colors.green);
        }
      } else {
        _showSnackBar("Şikayet gönderilemedi.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Bağlantı hatası!", Colors.red);
    }
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
                Navigator.of(ctx).pop();
                _blockUser(blockedUserId, name);
              },
              child: const Text("ENGELLE", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  void _showReportDialog() {
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
                    Navigator.of(ctx).pop();
                    _reportContent(widget.ad['id'], selectedReason);
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

  // ... (Geri kalan UI fonksiyonları: _makePhoneCall, _shareAdImage, _getProductName, _buildPoster aynı kalıyor ancak ApiConstants entegrasyonu tamamlandı) ...

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (!await launchUrl(launchUri)) throw 'Hata';
    } catch (e) {
      if (mounted) _showSnackBar("Arama başlatılamadı.", Colors.red);
    }
  }

  Future<void> _shareAdImage(BuildContext context) async {
    setState(() => _isSharing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 4.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/hemo_ilan.png').create();
        await file.writeAsBytes(pngBytes);
        if (mounted) await Share.shareXFiles([XFile(file.path)], text: "🔴 ACİL KAN! ${widget.ad['blood_type']} - ${widget.ad['hospital']} #HemoApp");
      }
    } catch (e) {
      print("Hata: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _getProductName(String? code) {
    final Map<String, String> names = {'tam_kan': 'Tam Kan', 'eritrosit': 'Eritrosit', 'trombosit': 'Trombosit', 'plazma': 'Plazma'};
    return names[code] ?? 'Tam Kan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("İlan Detayı", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey[50], foregroundColor: Colors.black, elevation: 0, centerTitle: true,
        actions: isMyAd ? [] : [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'sikayet') {
                _showReportDialog();
              } else if (value == 'engelle') {
                String userName = "${widget.ad['first_name'] ?? ''} ${widget.ad['last_name'] ?? ''}".trim();
                if (userName.isEmpty) userName = "Bu kullanıcı";
                _showBlockDialog(widget.ad['user_id'], userName);
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: _buildNewVisibleUI(),
                ),
              ),
              _buildModernBottomBar(context),
            ],
          ),
          // Poster oluşturma alanı (Ekranda görünmez)
          Transform.translate(offset: const Offset(-5000, 0), child: RepaintBoundary(key: _globalKey, child: _buildPoster())),
          if (_isSharing || _isActionLoading)
            Container(color: Colors.black87, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildNewVisibleUI() {
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
          child: Column(
            children: [
              Container(width: 100, height: 100, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEF4444), width: 2)), child: Center(child: Text(widget.ad['blood_type'] ?? '?', style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 32, fontWeight: FontWeight.w900)))),
              const SizedBox(height: 15),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)), child: Text(_getProductName(widget.ad['blood_product']).toUpperCase(), style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernInfoRow(Icons.person_rounded, "Hasta Adı Soyadı", "${widget.ad['patient_first_name']} ${widget.ad['patient_last_name']}", Colors.blue),
              const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
              _buildModernInfoRow(Icons.local_hospital_rounded, "Hastane", widget.ad['hospital'] ?? 'Belirtilmedi', Colors.red),
              const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
              _buildModernInfoRow(Icons.location_on_rounded, "Konum", "${widget.ad['city']} / ${widget.ad['district']}", Colors.orange),
              const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
              _buildModernInfoRow(Icons.phone_rounded, "İletişim", widget.ad['contact_phone'] ?? '-', Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isMyAd && pendingDonors.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.volunteer_activism, color: Colors.green), SizedBox(width: 10), Text("Gelen Yardım Talepleri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                const SizedBox(height: 15),
                ...pendingDonors.map((donor) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(donor['donor_name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      ElevatedButton(
                        onPressed: () => _approveDonation(donor['donation_id']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                        child: const Text("ONAYLA"),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFFFEDD5))),
          child: Row(children: [const Icon(Icons.info_outline_rounded, color: Colors.orange), const SizedBox(width: 10), Expanded(child: Text("Bağış yapmadan önce lütfen hasta yakını ile iletişime geçiniz.", style: TextStyle(color: Colors.orange[900], fontSize: 13)))]),
        ),
      ],
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold))]))]);
  }

  Widget _buildModernBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _isSharing ? null : () => _shareAdImage(context), icon: const Icon(Icons.share_rounded, color: Color(0xFFB71C1C)), label: const Text("Paylaş", style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Color(0xFFB71C1C)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: isMyAd
              ? ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check_circle),
            label: const Text("Bu Sizin İlanınız"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
          )
              : ElevatedButton.icon(
            onPressed: _sendDonationRequest,
            icon: const Icon(Icons.favorite),
            label: const Text("KAN VERMEYE GELİYORUM"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
          ),
        ),
      ]),
    );
  }

  Widget _buildPoster() {
    return Container(
      width: 350, height: 622,
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8E0000), Color(0xFF1a1a1a)])),
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.warning_amber, color: Colors.yellow, size: 18), SizedBox(width: 8), Text("ACİL KAN İHTİYACI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))])),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Column(children: [const SizedBox(height: 20), Container(width: 160, height: 160, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(widget.ad['blood_type'], style: const TextStyle(color: Color(0xFF8E0000), fontSize: 50, fontWeight: FontWeight.w900)), const Text("ARANIYOR", style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold))]))), const SizedBox(height: 20), Text(_getProductName(widget.ad['blood_product']).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 40), Container(width: 300, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: Column(children: [_posterRow(Icons.person, "${widget.ad['patient_first_name']} ${widget.ad['patient_last_name']}"), const Divider(color: Colors.white24), _posterRow(Icons.local_hospital, widget.ad['hospital']), const Divider(color: Colors.white24), _posterRow(Icons.location_on, widget.ad['city'])]))]))),
          Column(children: [const Text("İLETİŞİME GEÇİN", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)), const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.call, color: Color(0xFF8E0000), size: 20), const SizedBox(width: 10), Text(widget.ad['contact_phone'], style: const TextStyle(color: Color(0xFF8E0000), fontSize: 22, fontWeight: FontWeight.bold))])), const SizedBox(height: 15), const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.share, color: Colors.blue, size: 14), SizedBox(width: 5), Text("HemoApp ile paylaşıldı", style: TextStyle(color: Colors.white30, fontSize: 10))])])
        ],
      ),
    );
  }

  Widget _posterRow(IconData icon, String text) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(icon, color: Colors.white70, size: 18), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis))]));
  }
}