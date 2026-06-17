import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/models/admin_editor_models.dart';
import '../core/models/models.dart';
import '../core/providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<List<AdminUser>> listUsers({String? search}) {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    return _api.get(
      '/admin/users',
      query: query,
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

  Future<PaginatedResponse<AdminBook>> listBooks({int page = 1, String? search}) {
    final query = {'page': '$page'};
    if (search != null && search.isNotEmpty) query['search'] = search;
    return _api.get(
      '/admin/books',
      query: query,
      parser: (data) {
        final map = data as Map<String, dynamic>;
        return PaginatedResponse(
          items: (map['items'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(AdminBook.fromJson)
              .toList(),
          total: map['total'] as int? ?? 0,
          page: map['page'] as int? ?? 1,
          pages: map['pages'] as int? ?? 1,
        );
      },
    );
  }

  Future<void> deleteUser(int userId) async {
    await _api.delete('/admin/users/$userId');
  }

  Future<void> deleteBook(int bookId) async {
    await _api.delete('/admin/books/$bookId');
  }

  Future<void> refreshMetrics() async {
    await _api.post('/admin/refresh-metrics');
  }
}
