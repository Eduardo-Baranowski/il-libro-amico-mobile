import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/providers.dart';
import '../core/models/models.dart';

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return ReaderRepository(ref.watch(apiClientProvider));
});

class ReaderRepository {
  ReaderRepository(this._api);

  final ApiClient _api;

  Future<PaginatedResponse<FeedItem>> feed({int page = 1, int perPage = 10}) {
    return _api.get(
      '/reader/feed',
      query: {'page': '$page', 'per_page': '$perPage'},
      parser: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        FeedItem.fromJson,
      ),
    );
  }

  Future<({bool liked, int likesCount})> toggleFeedLike(int readingId) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/reader/feed/$readingId/like',
      parser: (d) => d as Map<String, dynamic>,
    );
    return (
      liked: res['liked'] as bool? ?? false,
      likesCount: res['likes_count'] as int? ?? 0,
    );
  }

  Future<List<FeedComment>> feedComments(int readingId) {
    return _api.get(
      '/reader/feed/$readingId/comments',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(FeedComment.fromJson)
          .toList(),
    );
  }

  Future<int> addFeedComment(int readingId, String conteudo) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/reader/feed/$readingId/comments',
      body: {'conteudo': conteudo},
      parser: (d) => d as Map<String, dynamic>,
    );
    return res['comments_count'] as int? ?? 0;
  }

  Future<PaginatedResponse<Book>> books({
    int page = 1,
    int perPage = 12,
    String? genero,
    String? condicao,
  }) {
    final query = {
      'page': '$page',
      'per_page': '$perPage',
      if (genero != null && genero.isNotEmpty) 'genero': genero,
      if (condicao != null && condicao.isNotEmpty) 'condicao': condicao,
    };
    return _api.get(
      '/reader/books',
      query: query,
      parser: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        Book.fromJson,
      ),
    );
  }

  Future<BookDetails> bookDetails(int id) {
    return _api.get(
      '/reader/books/$id',
      parser: (data) => BookDetails.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<BookReview>> bookReviews(int id) {
    return _api.get(
      '/reader/books/$id/reviews',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(BookReview.fromJson)
          .toList(),
    );
  }

  Future<void> purchaseBook(int livroId, {int quantidade = 1}) async {
    await _api.post(
      '/reader/purchases',
      body: {'livro_id': livroId, 'quantidade': quantidade},
    );
  }

  Future<PaginatedResponse<ReadingItem>> readings({
    int page = 1,
    int perPage = 12,
    String? status,
  }) {
    return _api.get(
      '/reader/readings',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (status != null && status.isNotEmpty) 'status': status,
      },
      parser: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        ReadingItem.fromJson,
      ),
    );
  }

  Future<PaginatedResponse<RecommendedBook>> recommendations({
    int page = 1,
    int perPage = 6,
  }) {
    return _api.get(
      '/reader/recommendations',
      query: {'page': '$page', 'per_page': '$perPage'},
      parser: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        RecommendedBook.fromJson,
      ),
    );
  }

  Future<PaginatedResponse<Conversation>> conversations({
    int page = 1,
    int perPage = 15,
  }) {
    return _api.get(
      '/reader/conversations',
      query: {'page': '$page', 'per_page': '$perPage'},
      parser: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        Conversation.fromJson,
      ),
    );
  }

  Future<List<DirectMessage>> messagesWith(int userId, {int afterId = 0}) {
    return _api.get(
      '/reader/users/$userId/messages',
      query: {'after_id': '$afterId'},
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(DirectMessage.fromJson)
          .toList(),
    );
  }

  Future<void> sendMessage(int userId, String conteudo) async {
    await _api.post(
      '/reader/users/$userId/messages',
      body: {'conteudo': conteudo},
    );
  }

  Future<PublicUser> publicUser(int id) {
    return _api.get(
      '/reader/users/$id',
      parser: (data) => PublicUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<Book>> editorBooks(int editorId) {
    return _api.get(
      '/reader/editors/$editorId/books',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(Book.fromJson)
          .toList(),
    );
  }

  Future<void> registerReading({
    required int livroId,
    required String status,
    int? nota,
    String? comentario,
    int? paginasLidas,
  }) async {
    await _api.post(
      '/reader/readings',
      body: {
        'livro_id': livroId,
        'status': status,
        if (nota != null) 'nota': nota,
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
        if (paginasLidas != null) 'paginas_lidas': paginasLidas,
      },
    );
  }

  Future<Map<String, dynamic>> profileDetails() {
    return _api.get(
      '/reader/profile',
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Uploads a new profile photo. [filePath] is the local file path,
  /// [mimeType] should be e.g. 'image/jpeg' or 'image/png'.
  /// Returns the new [imagem_url] from the server.
  Future<String> uploadProfilePhoto(String filePath, String mimeType) async {
    final res = await _api.postMultipart<Map<String, dynamic>>(
      '/reader/profile/photo',
      file: (fieldName: 'imagem', filePath: filePath, mimeType: mimeType),
      parser: (d) => d as Map<String, dynamic>,
    );
    return res['imagem_url'] as String? ?? '';
  }

  Future<Map<String, dynamic>> randomQuote() {
    return _api.get(
      '/reader/random-quote',
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  Future<void> deleteReading(int id) async {
    await _api.delete('/reader/readings/$id');
  }

  Future<List<Address>> getAddresses() {
    return _api.get(
      '/reader/addresses',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(Address.fromJson)
          .toList(),
    );
  }

  Future<Address> addAddress(Map<String, dynamic> data) {
    return _api.post(
      '/reader/addresses',
      body: data,
      parser: (res) => Address.fromJson(res as Map<String, dynamic>),
    );
  }

  Future<void> changePassword({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    await _api.put(
      '/reader/profile/password',
      body: {'senha_atual': senhaAtual, 'nova_senha': novaSenha},
    );
  }

  Future<BookLookupResponse> lookupBooks(String query, {int limit = 8}) {
    return _api.get(
      '/reader/books/lookup',
      query: {'q': query, 'limit': '$limit'},
      parser: (data) => BookLookupResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookSubmitResult> submitBook({
    required String titulo,
    required String autor,
    String? genero,
    String? descricao,
    String? isbn,
    int? paginas,
    int? openLibraryCoverId,
    bool addToShelf = true,
    String shelfStatus = 'quero_ler',
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final fields = <String, String>{
      'titulo': titulo,
      'autor': autor,
      'add_to_shelf': addToShelf.toString(),
      'shelf_status': shelfStatus,
      if (genero != null) 'genero': genero,
      if (descricao != null) 'descricao': descricao,
      if (isbn != null) 'isbn': isbn,
      if (paginas != null) 'paginas': paginas.toString(),
      if (openLibraryCoverId != null) 'open_library_cover_id': openLibraryCoverId.toString(),
    };

    final res = await _api.postMultipart<Map<String, dynamic>>(
      '/reader/books',
      fields: fields,
      file: imageFile,
      parser: (d) => d as Map<String, dynamic>,
    );
    return BookSubmitResult.fromJson(res);
  }

  Future<AutorProfile> autorProfile(int id) {
    return _api.get(
      '/reader/autores/$id',
      parser: (data) => AutorProfile.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> updateBook({
    required int id,
    String? titulo,
    String? autor,
    String? genero,
    String? descricao,
    String? isbn,
    int? paginas,
    int? openLibraryCoverId,
    ({String fieldName, String filePath, String mimeType})? imageFile,
  }) async {
    final fields = <String, String>{};
    if (titulo != null) fields['titulo'] = titulo;
    if (autor != null) fields['autor'] = autor;
    if (genero != null) fields['genero'] = genero;
    if (descricao != null) fields['descricao'] = descricao;
    if (isbn != null) fields['isbn'] = isbn;
    if (paginas != null) fields['paginas'] = paginas.toString();
    if (openLibraryCoverId != null) {
      fields['open_library_cover_id'] = openLibraryCoverId.toString();
    }
    await _api.putMultipart('/reader/books/$id', fields: fields, file: imageFile);
  }
}

