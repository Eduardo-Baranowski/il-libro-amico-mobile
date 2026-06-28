import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
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
    String? authorNationality,
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
    if (authorNationality != null) fields['author_nationality'] = authorNationality;
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

  Future<List<AdminAuthor>> listAuthors({String? search}) {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    return _api.get(
      '/admin/autores',
      query: query,
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(AdminAuthor.fromJson)
          .toList(),
    );
  }

  Future<List<NacionalidadeAdmin>> listNacionalidadesAdmin({String? search}) {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    return _api.get(
      '/admin/nacionalidades',
      query: query,
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(NacionalidadeAdmin.fromJson)
          .toList(),
    );
  }

  Future<int> createNacionalidade({
    required String nome,
    ({String fieldName, String filePath, String mimeType})? imageFile,
    String? flagUrl,
  }) async {
    if (imageFile != null) {
      final res = await _api.postMultipart('/admin/nacionalidades', fields: {'nome': nome}, file: imageFile, parser: (d) => d as Map<String, dynamic>);
      return res['id'] as int? ?? 0;
    }
    final res = await _api.post('/admin/nacionalidades', body: {'nome': nome, 'flag': flagUrl}, parser: (d) => d as Map<String, dynamic>);
    return res['id'] as int? ?? 0;
  }

  Future<void> updateNacionalidade({
    required int id,
    String? nome,
    ({String fieldName, String filePath, String mimeType})? imageFile,
    String? flagUrl,
  }) async {
    final fields = <String, String>{};
    if (nome != null) fields['nome'] = nome;
    if (imageFile != null) {
      await _api.putMultipart('/admin/nacionalidades/$id', fields: fields, file: imageFile);
      return;
    }
    if (flagUrl != null) fields['flag'] = flagUrl;
    await _api.put('/admin/nacionalidades/$id', body: fields);
  }

  Future<void> deleteNacionalidade(int id) async {
    await _api.delete('/admin/nacionalidades/$id');
  }

  Future<List<String>> listAuthorNationalities() {
    // Prefer the authenticated public endpoint which returns full objects.
    // If it fails (e.g. missing token), fall back to the admin endpoint that returns plain strings.
    return _api.get(
      '/reader/autores/nacionalidades',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => (m['nome'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
    ).catchError((_) async {
      return _api.get(
        '/admin/autores/nacionalidades',
        parser: (data) => (data as List).whereType<String>().toList(),
      );
    });
  }

  Future<AdminAuthorDetail> getAuthor(int id) {
    return _api.get('/admin/autores/$id', parser: (data) => AdminAuthorDetail.fromJson(data as Map<String, dynamic>));
  }

  Future<int> createAuthor({
    required String nome,
    String? bio,
    String? nacionalidade,
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final fields = <String, String>{'nome': nome};
    if (bio != null) fields['bio'] = bio;
    if (nacionalidade != null) fields['nacionalidade'] = nacionalidade;

    final res = await _api.postMultipart('/admin/autores', fields: fields, file: imageFile, parser: (d) => d as Map<String, dynamic>);
    return res['id'] as int? ?? 0;
  }

  Future<void> updateAuthor({
    required int id,
    String? nome,
    String? bio,
    String? nacionalidade,
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final fields = <String, String>{};
    if (nome != null) fields['nome'] = nome;
    if (bio != null) fields['bio'] = bio;
    if (nacionalidade != null) fields['nacionalidade'] = nacionalidade;
    await _api.putMultipart('/admin/autores/$id', fields: fields, file: imageFile);
  }

  Future<void> deleteAuthor(int id) async {
    await _api.delete('/admin/autores/$id');
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

  Future<void> updateEditora({
    required int id,
    String? nome,
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final fields = <String, String>{};
    if (nome != null) fields['nome'] = nome;
    if (imageFile != null) {
      await _api.putMultipart('/admin/editoras/$id', fields: fields, file: imageFile);
      return;
    }
    await _api.put('/admin/editoras/$id', body: fields);
  }

  Future<void> deleteEditora(int id) async {
    await _api.delete('/admin/editoras/$id');
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
    String? authorNationality,
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
    if (authorNationality != null) body['author_nationality'] = authorNationality;

    final res = await _api.postMultipart(
      '/admin/books',
      fields: body,
      file: imageFile,
      parser: (d) => d as Map<String, dynamic>,
    );
    return res['id'] as int? ?? 0;
  }
}
