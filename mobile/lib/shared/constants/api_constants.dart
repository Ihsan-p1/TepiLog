class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator

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

  // Saved
  static const String saved = '/saved';

  // Profile
  static const String myProfile = '/users/me';
  static const String myPosts = '/users/me/posts';
}
