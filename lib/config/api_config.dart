import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// URL base da API.
///
/// Produção: `https://lumina-nodejs-api.vercel.app` (padrão)
///
/// Para dev local, sobrescreva em Conta → URL da API, ou:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.3.2:5000`
class ApiConfig {
  ApiConfig._();
  static final ApiConfig instance = ApiConfig._();

  static const _prefsKey = 'api_base_url_override';

  /// URL de produção na Vercel.
  static const String productionUrl = 'https://lumina-nodejs-api.vercel.app';

  String? _override;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _override = prefs.getString(_prefsKey)?.trim();
    if (_override != null && _override!.isEmpty) _override = null;
  }

  String get baseUrl => _resolveForPlatform(_rawBaseUrl);

  String get _rawBaseUrl {
    if (_override != null && _override!.isNotEmpty) return _override!;

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    return productionUrl;
  }

  /// No Android, localhost/127.0.0.1 apontam para o emulador — redireciona ao host.
  static String _resolveForPlatform(String url) {
    if (kIsWeb || !Platform.isAndroid) return url;

    return url
        .replaceAll('127.0.0.1', '10.0.2.2')
        .replaceAll('localhost', '10.0.2.2');
  }

  /// URL local sugerida conforme a plataforma (AVD Android Studio).
  static String get suggestedLocalUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000';
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

  /// URLs de atalho na tela de configuração.
  static List<String> get androidPresets => [
        productionUrl,
        suggestedLocalUrl,
        'http://10.0.3.2:5000',
        'http://127.0.0.1:5000',
      ];
}
