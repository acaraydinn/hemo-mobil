import 'package:flutter/material.dart';

class LegalDocumentsScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentsScreen({
    super.key,
    required this.title,
    required this.content
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        // Alt kısma hafif bir çizgi ekleyerek derinlik kazandıralım
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İkon ve Başlık Alanı (Görseli güçlendirmek için)
            Row(
              children: [
                const Icon(Icons.gavel_rounded, color: Color(0xFFD32F2F), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Resmi Bilgilendirme",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Ana Metin
            Text(
              content,
              textAlign: TextAlign.justify, // Metni iki yana yasla (Daha profesyonel durur)
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6, // Satır arası boşluğu artırarak okunabilirliği iyileştirdik
                fontFamily: 'Roboto', // Varsa kurumsal fontun
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "HEMO Güvenlik ve Hukuk Departmanı",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}