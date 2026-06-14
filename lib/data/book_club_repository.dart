import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/models/book_club_models.dart';
import '../core/providers.dart';

final bookClubRepositoryProvider = Provider<BookClubRepository>((ref) {
  return BookClubRepository(ref.watch(apiClientProvider));
});

class BookClubRepository {
  BookClubRepository(this._api);

  final ApiClient _api;

  Future<BookClubHub> hub() {
    return _api.get(
      '/reader/book-club/hub',
      parser: (data) => BookClubHub.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookClubNominationsPage> nominations({
    int page = 1,
    int perPage = 12,
    String? search,
  }) {
    return _api.get(
      '/reader/book-club/nominations',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (search != null && search.isNotEmpty) 'search': search,
      },
      parser: (data) => BookClubNominationsPage.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookClubNomination> nominate({
    int? livroId,
    String? titulo,
    String? autor,
    String? motivo,
  }) {
    return _api.post(
      '/reader/book-club/nominations',
      body: {
        if (livroId != null) 'livro_id': livroId,
        if (titulo != null) 'titulo': titulo,
        if (autor != null) 'autor': autor,
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      },
      parser: (data) => BookClubNomination.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookClubVoteResult> toggleVote(int nominationId) {
    return _api.post(
      '/reader/book-club/nominations/$nominationId/vote',
      parser: (data) => BookClubVoteResult.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<BookClubActivity>> activity() {
    return _api.get(
      '/reader/book-club/activity',
      parser: (data) {
        final raw = (data as Map<String, dynamic>)['items'];
        if (raw is! List) return <BookClubActivity>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(BookClubActivity.fromJson)
            .toList();
      },
    );
  }
}
