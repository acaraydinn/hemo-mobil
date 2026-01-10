// lib/utils/user_session.dart

class UserSession {
  // Uygulamanın her yerinden erişilebilen statik değişken
  static String? currentUserPhone;

  // Giriş yapılmış mı kontrolü
  static bool get isLoggedIn => currentUserPhone != null && currentUserPhone!.isNotEmpty;
}