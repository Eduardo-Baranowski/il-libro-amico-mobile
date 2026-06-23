import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/models/admin_editor_models.dart';
import '../core/models/models.dart';
import '../core/providers.dart';

final editorRepositoryProvider = Provider<EditorRepository>((ref) {
  return EditorRepository(ref.watch(apiClientProvider));
});

class EditorRepository {
  EditorRepository(this._api);

  final ApiClient _api;

  Future<PaginatedResponse<EditorBook>> listBooks({
    int page = 1,
    int perPage = 10,
    String q = '',
  }) {
    return _api.get(
      '/editor/books',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (q.isNotEmpty) 'q': q,
      },
      parser: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        EditorBook.fromJson,
      ),
    );
  }

  Future<BookLookupResponse> lookupBooks(String q, {int limit = 8}) {
    return _api.get(
      '/editor/books/lookup',
      query: {'q': q, 'limit': '$limit'},
      parser: (data) => BookLookupResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<int> createBook({
    required String titulo,
    required String autor,
    required String preco,
    required String estoque,
    required String genero,
    String? descricao,
    int? openLibraryCoverId,
    String condicao = 'novo',
    int? paginas,
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final res = await _api.postMultipart<Map<String, dynamic>>(
      '/editor/books',
      fields: {
        'titulo': titulo,
        'autor': autor,
        'preco': preco,
        'estoque': estoque,
        'genero': genero,
        'condicao': condicao,
        if (descricao != null) 'descricao': descricao,
        if (openLibraryCoverId != null)
          'open_library_cover_id': '$openLibraryCoverId',
        if (paginas != null) 'paginas': '$paginas',
      },
      file: imageFile,
      parser: (d) => d as Map<String, dynamic>,
    );
    return res['id'] as int? ?? 0;
  }

  Future<void> updateBook({
    required int id,
    String? titulo,
    String? autor,
    String? preco,
    String? estoque,
    String? genero,
    String? descricao,
    int? openLibraryCoverId,
    String? condicao,
    int? paginas,
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final fields = <String, String>{};
    if (titulo != null) fields['titulo'] = titulo;
    if (autor != null) fields['autor'] = autor;
    if (preco != null) fields['preco'] = preco;
    if (estoque != null) fields['estoque'] = estoque;
    if (genero != null) fields['genero'] = genero;
    if (descricao != null) fields['descricao'] = descricao;
    if (condicao != null) fields['condicao'] = condicao;
    if (openLibraryCoverId != null) {
      fields['open_library_cover_id'] = '$openLibraryCoverId';
    }
    if (paginas != null) fields['paginas'] = '$paginas';
    await _api.putMultipart('/editor/books/$id', fields: fields, file: imageFile);
  }

  Future<void> archiveBook(int id) async {
    await _api.delete('/editor/books/$id');
  }

  Future<List<EditorRequest>> listRequests() {
    return _api.get(
      '/editor/requests',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(EditorRequest.fromJson)
          .toList(),
    );
  }

  Future<void> respondRequest(int id, String resposta) async {
    await _api.put(
      '/editor/requests/$id/respond',
      body: {'resposta': resposta},
    );
  }
}
