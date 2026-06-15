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

  Future<BookClubListResponse> listClubs({String? search}) {
    return _api.get(
      '/reader/book-club',
      query: search != null && search.isNotEmpty ? {'search': search} : null,
      parser: (data) => BookClubListResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookClub> createClub({
    required String nome,
    String? descricao,
    required bool privado,
  }) {
    return _api.post(
      '/reader/book-club',
      body: {
        'nome': nome,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        'privado': privado,
      },
      parser: (data) => BookClub.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<({String message, String membershipStatus, int? clubId})> joinClub({
    int? clubId,
    String? inviteCode,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/reader/book-club/join',
      body: {
        if (clubId != null) 'club_id': clubId,
        if (inviteCode != null && inviteCode.isNotEmpty) 'convite_codigo': inviteCode,
      },
      parser: (d) => d as Map<String, dynamic>,
    );
    final club = res['club'] as Map<String, dynamic>?;
    return (
      message: res['message'] as String? ?? '',
      membershipStatus: res['membership_status'] as String? ?? 'active',
      clubId: club?['id'] as int?,
    );
  }

  Future<void> inviteUser(int clubId, {int? userId, String? email}) {
    return _api.post(
      '/reader/book-club/$clubId/invite',
      body: {
        if (userId != null) 'user_id': userId,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
  }

  Future<List<BookClubMemberRequest>> getPendingRequests(int clubId) {
    return _api.get(
      '/reader/book-club/$clubId/requests',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(BookClubMemberRequest.fromJson)
          .toList(),
    );
  }

  Future<List<BookClubMember>> getMembers(int clubId) {
    return _api.get(
      '/reader/book-club/$clubId/members',
      parser: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(BookClubMember.fromJson)
          .toList(),
    );
  }

  Future<void> approveRequest(int clubId, int requestId) {
    return _api.post('/reader/book-club/$clubId/requests/$requestId/approve');
  }

  Future<void> rejectRequest(int clubId, int requestId) {
    return _api.post('/reader/book-club/$clubId/requests/$requestId/reject');
  }

  Future<BookClubHub> hub(int clubId) {
    return _api.get(
      '/reader/book-club/$clubId/hub',
      parser: (data) => BookClubHub.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookClubNominationsPage> nominations(
    int clubId, {
    int page = 1,
    int perPage = 12,
    String? search,
  }) {
    return _api.get(
      '/reader/book-club/$clubId/nominations',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (search != null && search.isNotEmpty) 'search': search,
      },
      parser: (data) => BookClubNominationsPage.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookClubNomination> nominate(
    int clubId, {
    int? livroId,
    String? titulo,
    String? autor,
    String? motivo,
  }) {
    return _api.post(
      '/reader/book-club/$clubId/nominations',
      body: {
        if (livroId != null) 'livro_id': livroId,
        if (titulo != null) 'titulo': titulo,
        if (autor != null) 'autor': autor,
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      },
      parser: (data) => BookClubNomination.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<BookClubVoteResult> toggleVote(int clubId, int nominationId) {
    return _api.post(
      '/reader/book-club/$clubId/nominations/$nominationId/vote',
      parser: (data) => BookClubVoteResult.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<BookClubActivity>> activity(int clubId) {
    return _api.get(
      '/reader/book-club/$clubId/activity',
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

  Future<void> draw(int clubId) {
    return _api.post('/reader/book-club/$clubId/draw');
  }

  Future<void> newCycle(int clubId) {
    return _api.post('/reader/book-club/$clubId/cycle');
  }
}
