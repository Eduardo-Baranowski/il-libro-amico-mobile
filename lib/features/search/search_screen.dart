import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSearch('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    _debounce?.cancel();
    if (trimmed.isEmpty) {
      _runSearch('');
      return;
    }
    if (trimmed.length < 2) {
      setState(() {
        _result = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(trimmed));
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
      backgroundColor: AppTheme.background,
      appBar: const BibDetailAppBar(title: 'Buscar'),
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 8, AppTheme.marginMobile, 0),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Título, autor, usuário ou ISBN…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile, vertical: 8),
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
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                children: [
                                  const Center(child: Text('Nenhum resultado')),
                                  if ((_scope == _SearchScope.all || _scope == _SearchScope.books) && _controller.text.trim().length >= 2) ...[
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: () => context.push('/livros/cadastrar'),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Cadastrar novo livro'),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Se o livro não foi encontrado, você pode cadastrá-lo no catálogo.',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                                    ),
                                  ],
                                ],
                              ),
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
      child: BibGenreChip(
        label: label,
        selected: _scope == scope,
        onTap: () => setState(() => _scope = scope),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text, style: AppTheme.headlineSerif.copyWith(fontSize: 18)),
      );

  String _roleLabel(UserRole papel) => switch (papel) {
        UserRole.editor => 'Editora',
        UserRole.admin => 'Admin',
        _ => 'Leitor',
      };

}
