class ApiConstants {
  // =============================================================
  // 🌍 PRODUCTION (CANLI) SUNUCU AYARLARI
  // =============================================================

  // Backend domain adresi (SSL/HTTPS aktif)
  static const String _domain = "https://hemo.socialrate.net";

  // Django urls.py dosyasındaki 'api/' path'i buraya eklendi.
  // Sonuç: https://hemo.socialrate.net/api
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
  // ⚡ DİNAMİK PARAMETRELİ UÇ NOKTALAR (Fonksiyon Olarak Kalmalı)
  // =============================================================
  static String contracts(String slug) => "$baseUrl/contracts/$slug/";
  static String requestDonors(int requestId) => "$baseUrl/request-donors/$requestId/";
  static String deleteRequest(int requestId) => "$baseUrl/delete-request/$requestId/";
  static String userProfile(String phone) => "$baseUrl/user-profile/?phone=$phone";
  static String get leaderboard => "$baseUrl/leaderboard/";
}