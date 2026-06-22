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

  Future<AdminBookDetail> getBook(int bookId) {
    return _api.get(
      '/admin/books/$bookId',
      parser: (data) => AdminBookDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> updateBook({
    required int id,
    int? editoraId,
    String? titulo,
    String? autor,
    String? preco,
    String? estoque,
    String? genero,
    String? descricao,
    int? paginas,
    ({String fieldName, String filePath, String mimeType})? imageFile,
    int? openLibraryCoverId,
  }) async {
    final fields = <String, String>{};
    if (editoraId != null) fields['editora_id'] = editoraId.toString();
    if (titulo != null) fields['titulo'] = titulo;
    if (autor != null) fields['autor'] = autor;
    if (preco != null) fields['preco'] = preco;
    if (estoque != null) fields['estoque'] = estoque;
    if (genero != null) fields['genero'] = genero;
    if (descricao != null) fields['descricao'] = descricao;
    if (paginas != null) fields['paginas'] = paginas.toString();
    if (openLibraryCoverId != null) {
      fields['open_library_cover_id'] = openLibraryCoverId.toString();
    }
    await _api.putMultipart('/admin/books/$id', fields: fields, file: imageFile);
  }

  Future<void> refreshMetrics() async {
    await _api.post('/admin/refresh-metrics');
  }

  Future<List<Editora>> listEditoras({String? search}) {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    return _api.get(
      '/admin/editoras',
      query: query,
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(Editora.fromJson)
          .toList(),
    );
  }

  Future<int> createEditora({
    required String nome,
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final body = <String, String>{'nome': nome};

    final res = await _api.postMultipart(
      '/admin/editoras',
      fields: body,
      file: imageFile,
      parser: (d) => d as Map<String, dynamic>,
    );
    return res['id'] as int? ?? 0;
  }

  Future<int> createBook({
    required int editoraId,
    required String titulo,
    required String autor,
    int? paginas,
    String? genero,
    String? descricao,
    ({String fieldName, String filePath, String mimeType})? imageFile,
    int? openLibraryCoverId,
  }) async {
    final body = <String, String>{
      'editora_id': editoraId.toString(),
      'titulo': titulo,
      'autor': autor,
    };
    if (paginas != null && paginas > 0) body['paginas'] = paginas.toString();
    if (genero != null) body['genero'] = genero;
    if (descricao != null) body['descricao'] = descricao;
    if (openLibraryCoverId != null) {
      body['open_library_cover_id'] = openLibraryCoverId.toString();
    }

    final res = await _api.postMultipart(
      '/admin/books',
      fields: body,
      file: imageFile,
      parser: (d) => d as Map<String, dynamic>,
    );
    return res['id'] as int? ?? 0;
  }
}
