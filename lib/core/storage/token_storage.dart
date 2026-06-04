import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart'; // UserRole, UserRoleX

class TokenStorage {
  static const _tokenKey = 'doc.jwt';
  static const _roleKey = 'doc.role';
  static const _nameKey = 'doc.name';
  static const _imageKey = 'doc.image';

  Future<void> saveSession({
    required String token,
    required UserRole role,
    required String name,
    String? imageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role.name);
    await prefs.setString(_nameKey, name);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await prefs.setString(_imageKey, imageUrl);
    } else {
      await prefs.remove(_imageKey);
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserRole?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return UserRoleX.tryParse(prefs.getString(_roleKey));
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<String?> getImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_imageKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_imageKey);
  }
}
