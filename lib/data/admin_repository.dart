import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/models/admin_editor_models.dart';
import '../core/models/user_role.dart';
import '../core/providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<List<AdminUser>> listUsers() {
    return _api.get(
      '/admin/users',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(AdminUser.fromJson)
          .toList(),
    );
  }

  Future<int> createUser({
    required String nome,
    required String email,
    required String senha,
    required UserRole papel,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/admin/users',
      body: {'nome': nome, 'email': email, 'senha': senha, 'papel': papel.name},
      parser: (d) => d as Map<String, dynamic>,
    );
    return res['id'] as int? ?? 0;
  }

  Future<AdminReport> reports() {
    return _api.get(
      '/admin/reports',
      parser: (data) => AdminReport.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> refreshMetrics() async {
    await _api.post('/admin/refresh-metrics');
  }
}
