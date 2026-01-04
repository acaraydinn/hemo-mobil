import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// 👇 BU SATIR ÇOK ÖNEMLİ: Oluşturduğumuz ayar dosyasını dahil ediyoruz
import 'firebase_options.dart';

void main() async {
  // 1. Flutter motorunu hazırla
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Firebase'i "firebase_options.dart" içindeki ayarlarla başlat
    // Bu sayede iOS için ekstra plist dosyası aramasına gerek kalmaz.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("--- [SİSTEM] FIREBASE BAŞARIYLA BAŞLATILDI (Options ile) ---");

    // 3. Bildirim kurulumunu yap ve token alımını bekle
    await _setupFirebaseMessaging();

  } catch (e) {
    debugPrint("--- [KRİTİK HATA] FIREBASE BAŞLATILAMADI: $e ---");
  }

  runApp(const MyApp());
}

// Firebase Bildirim Ayarları ve Akıllı Token Alma
Future<void> _setupFirebaseMessaging() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 4. Kullanıcıdan bildirim izni iste
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('--- [BİLDİRİM] KULLANICI İZİN VERDİ ---');

      // 5. iOS Gerçek Cihazda APNs Bekleme Mekanizması
      // iOS'ta FCM Token alabilmek için önce Apple'ın (APNs) token vermesi şarttır.
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();

        // Eğer ilk denemede APNs yoksa, 10 saniye boyunca bekle
        if (apnsToken == null) {
          int retryCount = 0;
          while (await messaging.getAPNSToken() == null && retryCount < 10) {
            debugPrint("--- [iOS] Sertifika (APNs) bekleniyor... Deneme: ${retryCount + 1} ---");
            await Future.delayed(const Duration(seconds: 1));
            retryCount++;
          }
        }

        // Son kontrol
        if (await messaging.getAPNSToken() == null) {
          debugPrint("--- [UYARI] APNs Token alınamadı. (Simülatörde çalışmaz, gerçek cihaz gerekir) ---");
          debugPrint("--- [UYARI] Xcode -> Signing & Capabilities -> Push Notifications açık mı? ---");
        } else {
          debugPrint("--- [iOS] APNs Token Başarıyla Alındı ---");
        }
      }

      // 6. FCM Token Al ve Logla
      String? token = await messaging.getToken();

      if (token != null) {
        debugPrint("-------------------------------------");
        debugPrint("--- [ZAFER] YENİ CİHAZ FCM TOKEN ---");
        debugPrint(token);
        debugPrint("-------------------------------------");
        // Not: Bu token artık Login/Register ekranlarında Django'ya gönderilmeye hazır.
      } else {
        debugPrint("--- [HATA] FCM TOKEN ALINAMADI ---");
      }
    } else {
      debugPrint('--- [UYARI] BİLDİRİM İZNİ REDDEDİLDİ ---');
    }
  } catch (e) {
    debugPrint("--- [HATA] KURULUM SIRASINDA HATA: $e ---");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hemo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD32F2F),
          centerTitle: true,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}