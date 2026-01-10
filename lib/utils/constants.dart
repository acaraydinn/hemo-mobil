class ApiConstants {
  // =============================================================
  // 🌍 PRODUCTION (CANLI) SUNUCU AYARLARI
  // =============================================================

  // NOT: Backend'i yerelde (kendi bilgisayarında) çalıştırıyorsan ve
  // emülatör kullanıyorsan burayı "http://10.0.2.2:8000" yapmalısın.
  // Gerçek cihazla test ediyorsan bilgisayarının IP adresini yaz (örn: 192.168.1.35:8000)
  // Canlı sunucuya attıysan domain kalabilir.
  static const String _domain = "https://hemo.com.tr"; // 🔥 PRODUCTION

  // Django urls.py dosyasındaki 'api/' path'i buraya eklendi.
  static const String baseUrl = "$_domain/api";

  // =============================================================
  // 🔐 HESAP VE DOĞRULAMA
  // =============================================================
  static const String register = "$baseUrl/register/";
  static const String login = "$baseUrl/login/";
  static const String verifyOtp = "$baseUrl/verify-otp/";
  static const String updateProfile = "$baseUrl/update-profile/";
  static const String changePassword = "$baseUrl/change-password/";
  static const String deleteAccount = "$baseUrl/delete-account/";

  // =============================================================
  // 🩸 İLAN VE BAĞIŞ İŞLEMLERİ
  // =============================================================
  static const String bloodRequests = "$baseUrl/blood-requests/";
  static const String cities = "$baseUrl/cities/";
  static const String districts = "$baseUrl/districts/";
  static const String hospitals = "$baseUrl/hospitals/";
  static const String myRequests = "$baseUrl/my-requests/";
  static const String donate = "$baseUrl/donate/";
  static const String myDonations = "$baseUrl/my-donations/";
  static const String approveDonation = "$baseUrl/approve-donation/";

  // =============================================================
  // 🛡️ GÜVENLİK VE MODERASYON (YENİ - APPLE İÇİN ŞART)
  // =============================================================
  static const String blockUser = "$baseUrl/block-user/";
  static const String reportContent = "$baseUrl/report-content/";

  // =============================================================
  // ⚡ DİNAMİK PARAMETRELİ UÇ NOKTALAR (Fonksiyon Olarak Kalmalı)
  // =============================================================
  static String contracts(String slug) => "$baseUrl/contracts/$slug/";
  static String requestDonors(int requestId) => "$baseUrl/request-donors/$requestId/";
  static String deleteRequest(int requestId) => "$baseUrl/delete-request/$requestId/";
  static String userProfile(String phone) => "$baseUrl/user-profile/?phone=$phone";
  static String get leaderboard => "$baseUrl/leaderboard/";
}