import 'dart:convert';

int? userIdFromToken(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final normalized = base64Url.normalize(parts[1]);
    final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
    if (payload is Map<String, dynamic>) {
      final sub = payload['sub'];
      if (sub is int) return sub;
      if (sub is String) return int.tryParse(sub);
    }
  } catch (_) {}
  return null;
}
