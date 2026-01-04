import 'package:flutter/material.dart';
import 'blood_requests_list.dart'; // Az önce oluşturduğumuz dosya
import 'leaderboard_screen.dart';   // Liderlik Tablosu
import 'profile_screen.dart';       // Profil Ekranı

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Sayfalar Listesi
  // 0: Anasayfa (İlan Listesi)
  // 1: Liderler (Oyunlaştırma)
  // 2: Profil (Ayarlar, Fotoğraf vs.)
  final List<Widget> _pages = [
    const BloodRequestsList(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DİKKAT: Burada AppBar YOK! (Her sayfa kendi başlığını yönetecek)

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFD32F2F), // Hemo Kırmızısı
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Liderler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}