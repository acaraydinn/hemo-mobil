import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // 1. Logoyu ve UBASOFT yazısını görmesi için bekleyelim
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      // Navigasyon animasyonunu daha akıcı hale getirmek için PageRouteBuilder kullanılabilir
      // ama şu aşamada pushReplacement yeterli ve temizdir.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ORTA ALAN: LOGO VE METİNLER
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 150,
                    height: 150,
                    // Eğer asset dosyası henüz yoksa hata vermemesi için errorBuilder eklenebilir
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.bloodtype,
                        size: 100,
                        color: Color(0xFFD32F2F)
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "HEMO",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD32F2F),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Hayat Kurtaran Bağlantı",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Color(0xFFD32F2F),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),

          // EN ALT ALAN: UBASOFT İMZASI
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "from",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "UBASOFT",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}