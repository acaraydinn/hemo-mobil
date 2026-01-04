import 'dart:io';

class ApiConstants {
  // --- TEMEL BAĞLANTI AYARI ---
  // iMac Yerel IP: 192.168.0.30
  // Django'yu "python manage.py runserver 0.0.0.0:8000" ile başlatmayı unutma!

  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emülatör hala 10.0.2.2 kullanabilir ama 192.168.0.30 daha garantidir.
      // Eğer emülatörde sorun yaşarsan burayı "http://10.0.2.2:8000/api" yapabilirsin.
      return "http://192.168.0.30:8000/api";
    } else {
      // iOS Simülatör ve GERÇEK iPhone için iMac IP'si zorunludur.
      return "http://192.168.0.30:8000/api";
    }
  }

  // --- HESAP VE DOĞRULAMA ---
  static String get register => "$baseUrl/register/";
  static String get login => "$baseUrl/login/";
  static String get verifyOtp => "$baseUrl/verify-otp/";
  static String get updateProfile => "$baseUrl/update-profile/";
  static String get changePassword => "$baseUrl/change-password/";
  static String get deleteAccount => "$baseUrl/delete-account/";

  // --- İLAN VE BAĞIŞ İŞLEMLERİ ---
  static String get bloodRequests => "$baseUrl/blood-requests/";
  static String get cities => "$baseUrl/cities/";
  static String get districts => "$baseUrl/districts/";
  static String get hospitals => "$baseUrl/hospitals/";
  static String get myRequests => "$baseUrl/my-requests/";
  static String get donate => "$baseUrl/donate/";
  static String get myDonations => "$baseUrl/my-donations/";
  static String get approveDonation => "$baseUrl/approve-donation/";

  // --- DİNAMİK PARAMETRELİ UÇ NOKTALAR ---
  static String contracts(String slug) => "$baseUrl/contracts/$slug/";
  static String requestDonors(int requestId) => "$baseUrl/request-donors/$requestId/";
  static String deleteRequest(int requestId) => "$baseUrl/delete-request/$requestId/";
  static String userProfile(String phone) => "$baseUrl/user-profile/?phone=$phone";
  static String get leaderboard => "$baseUrl/leaderboard/";
}