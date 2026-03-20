import 'package:hive_flutter/hive_flutter.dart';

class TokenStorage {
  static const String _boxName = 'auth';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(_accessTokenKey, accessToken);
    await _box.put(_refreshTokenKey, refreshToken);
  }

  String? get accessToken => _box.get(_accessTokenKey) as String?;
  String? get refreshToken => _box.get(_refreshTokenKey) as String?;

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.put(_userKey, userData);
  }

  Map<String, dynamic>? get userData {
    final data = _box.get(_userKey);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  bool get hasToken => accessToken != null;

  Future<void> clear() async {
    await _box.clear();
  }
}
