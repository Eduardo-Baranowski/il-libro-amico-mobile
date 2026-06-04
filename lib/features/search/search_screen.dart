import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart' show BookCover, UserAvatar;
import '../../data/search_repository.dart';

enum _SearchScope { all, books, users, editors }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  GlobalSearchResult? _result;
  bool _loading = false;
  String? _error;
  _SearchScope _scope = _SearchScope.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _result = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(searchRepositoryProvider).search(q);
      if (mounted) setState(() => _result = res);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Falha na busca.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final books = _scope == _SearchScope.users || _scope == _SearchScope.editors
        ? <SearchBookHit>[]
        : result?.books ?? [];
    final users = _scope == _SearchScope.books || _scope == _SearchScope.editors
        ? <SearchUserHit>[]
        : result?.users ?? [];
    final editors = _scope == _SearchScope.books || _scope == _SearchScope.users
        ? <SearchEditorHit>[]
        : result?.editors ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Livros, autores, usuários…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _scopeChip('Tudo', _SearchScope.all),
                _scopeChip('Livros', _SearchScope.books),
                _scopeChip('Usuários', _SearchScope.users),
                _scopeChip('Editoras', _SearchScope.editors),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!, textAlign: TextAlign.center))
                : result == null
                    ? const Center(
                        child: Text(
                          'Digite pelo menos 2 caracteres',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (books.isNotEmpty) ...[
                            _sectionTitle('Livros'),
                            ...books.map(
                              (b) => ListTile(
                                leading: BookCover(url: b.imagemUrl, width: 40, height: 52),
                                title: Text(b.titulo),
                                subtitle: Text('${b.autor} · R\$ ${b.preco}'),
                                onTap: () => context.push('/livro/${b.id}'),
                              ),
                            ),
                          ],
                          if (users.isNotEmpty) ...[
                            _sectionTitle('Usuários'),
                            ...users.map(
                              (u) => ListTile(
                                leading: UserAvatar(url: u.imagemUrl, name: u.nome),
                                title: Text(u.nome),
                                subtitle: Text(_roleLabel(u.papel)),
                                onTap: () {
                                  if (u.papel == UserRole.editor) {
                                    context.push('/editora/${u.id}');
                                  } else {
                                    context.push(
                                      '/mensagens/${u.id}?nome=${Uri.encodeComponent(u.nome)}',
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                          if (editors.isNotEmpty) ...[
                            _sectionTitle('Editoras'),
                            ...editors.map(
                              (e) => ListTile(
                                leading: UserAvatar(url: e.imagemUrl, name: e.nome),
                                title: Text(e.nome),
                                onTap: () => context.push('/editora/${e.id}'),
                              ),
                            ),
                          ],
                          if (books.isEmpty && users.isEmpty && editors.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(child: Text('Nenhum resultado')),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _scopeChip(String label, _SearchScope scope) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _scope == scope,
        onSelected: (_) => setState(() => _scope = scope),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      );

  String _roleLabel(UserRole papel) => switch (papel) {
        UserRole.editor => 'Editora',
        UserRole.admin => 'Admin',
        _ => 'Leitor',
      };

}
