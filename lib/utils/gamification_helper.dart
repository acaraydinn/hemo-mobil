import 'package:flutter/material.dart'; // <--- BU SATIR EKSİKTİ, ARTIK TAMAM.

class UserLevel {
  final String title;
  final String badge;
  final Color color;
  final double progress; // Sonraki seviyeye ne kadar kaldı (0.0 - 1.0)

  UserLevel(this.title, this.badge, this.color, this.progress);
}

class GamificationHelper {
  static UserLevel getLevelInfo(int points) {
    if (points < 50) return UserLevel("Yeni Gönüllü", "🌱", Colors.green.shade300, points / 50);
    if (points < 150) return UserLevel("Duyarlı Vatandaş", "🤝", Colors.teal, (points - 50) / 100);
    if (points < 300) return UserLevel("Kan Kardeşi", "🩸", Colors.redAccent, (points - 150) / 150);
    if (points < 500) return UserLevel("Umut Elçisi", "🕊️", Colors.blue, (points - 300) / 200);
    if (points < 800) return UserLevel("Hayat Kurtarıcı", "🚑", Colors.red, (points - 500) / 300);
    if (points < 1200) return UserLevel("Cesur Yürek", "🦁", Colors.orange, (points - 800) / 400);
    if (points < 1700) return UserLevel("Kahraman", "🦸", Colors.indigo, (points - 1200) / 500);
    if (points < 2500) return UserLevel("Süper Kahraman", "🦸‍♂️", Colors.purple, (points - 1700) / 800);
    if (points < 4000) return UserLevel("Koruyucu Melek", "👼", Colors.amber, (points - 2500) / 1500);
    return UserLevel("HEMO EFSANESİ", "👑", Colors.amber.shade900, 1.0);
  }
}