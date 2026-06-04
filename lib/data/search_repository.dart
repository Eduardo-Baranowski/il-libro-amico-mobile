import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/models/admin_editor_models.dart';
import '../core/providers.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});

class SearchRepository {
  SearchRepository(this._api);

  final ApiClient _api;

  Future<GlobalSearchResult> search(String q, {String? genero}) {
    final query = {
      'q': q,
      'limit': '25',
      if (genero != null && genero.isNotEmpty && genero != 'Todos') 'genero': genero,
    };
    return _api.get(
      '/reader/search',
      query: query,
      parser: (data) {
        final map = data as Map<String, dynamic>;
        return GlobalSearchResult(
          books: (map['books'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(SearchBookHit.fromJson)
              .toList(),
          users: (map['users'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(SearchUserHit.fromJson)
              .toList(),
          editors: (map['editors'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(SearchEditorHit.fromJson)
              .toList(),
        );
      },
    );
  }
}
