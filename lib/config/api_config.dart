import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// URL base da API Flask.
///
/// Android emulador:
/// - **Genymotion:** `http://10.0.3.2:5000` (padrão aqui)
/// - **AVD (Android Studio):** `http://10.0.2.2:5000`
///
/// Sobrescreva em Conta → URL da API, ou:
/// `flutter run --dart-define=API_BASE_URL=http://SEU_IP:5000`
class ApiConfig {
  ApiConfig._();
  static final ApiConfig instance = ApiConfig._();

  static const _prefsKey = 'api_base_url_override';

  String? _override;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _override = prefs.getString(_prefsKey)?.trim();
    if (_override != null && _override!.isEmpty) _override = null;
  }

  String get baseUrl {
    if (_override != null && _override!.isNotEmpty) return _override!;

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (Platform.isAndroid) {
      // Genymotion → host via 10.0.3.2 (não use 10.0.2.2 do AVD).
      return 'http://10.0.3.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  Future<void> setOverride(String? url) async {
    final trimmed = url?.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed == null || trimmed.isEmpty) {
      _override = null;
      await prefs.remove(_prefsKey);
    } else {
      _override = trimmed.replaceAll(RegExp(r'/+$'), '');
      await prefs.setString(_prefsKey, _override!);
    }
  }

  /// IPs comuns para atalho na tela de configuração.
  static List<String> get androidPresets => const [
        'http://10.0.3.2:5000',
        'http://10.0.2.2:5000',
        'http://127.0.0.1:5000',
      ];
}
