class ApiConstants {
  /// Base URL API. Dapat dikonfigurasi saat build/run tanpa mengubah kode:
  ///
  ///   flutter run --dart-define=API_BASE_URL=https://api.tepilog.app/api
  ///   flutter build apk --dart-define=API_BASE_URL=https://api.tepilog.app/api
  ///
  /// Default `10.0.2.2` = alias localhost host dari Android emulator.
  /// Untuk device fisik/produksi WAJIB di-override lewat --dart-define
  /// (gunakan https:// pada endpoint produksi).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  // Locations
  static const String locations = '/locations';
  static const String trending = '/locations/trending';
  static const String search = '/locations/search';

  // Posts
  static const String posts = '/posts';

  // Comments
  static const String comments = '/comments';

  // Saved
  static const String saved = '/saved';

  // Profile
  static const String myProfile = '/users/me';
  static const String myPosts = '/users/me/posts';
}
