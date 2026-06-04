import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/editor_repository.dart';

class EditorCatalogBody extends ConsumerStatefulWidget {
  const EditorCatalogBody({super.key});

  @override
  ConsumerState<EditorCatalogBody> createState() => _EditorCatalogBodyState();
}

class _EditorCatalogBodyState extends ConsumerState<EditorCatalogBody> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _items = <EditorBook>[];
  int _page = 1;
  int _pages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _query = '';

  bool get _hasMore => _page < _pages;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) _load(_page + 1);
  }

  Future<void> _load(int page) async {
    if (page > 1 && (_loadingMore || !_hasMore)) return;
    setState(() {
      if (page == 1) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final res = await ref.read(editorRepositoryProvider).listBooks(
            page: page,
            q: _query,
          );
      if (!mounted) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(res.items);
        _page = res.page;
        _pages = res.pages;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao carregar catálogo.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onSearch(String value) {
    _query = value.trim();
    _load(1);
  }

  Future<void> _openForm([EditorBook? book]) async {
    final saved = book == null
        ? await context.push<bool>('/editor/livro/novo')
        : await context.push<bool>('/editor/livro/${book.id}', extra: book);
    if (saved == true) _load(1);
  }

  Future<void> _archive(EditorBook book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arquivar livro?'),
        content: Text('Remover "${book.titulo}" do catálogo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Arquivar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(editorRepositoryProvider).archiveBook(book.id);
      _load(1);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu catálogo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Solicitações',
            onPressed: () => context.push('/editor/solicitacoes'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Livro'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar no catálogo…',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: _onSearch,
              onChanged: (v) {
                if (v.isEmpty) _onSearch('');
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(1),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (_loading && _items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null && _items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(_error!)),
                    )
                  else if (_items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Nenhum livro cadastrado.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final book = _items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: AppTheme.surface,
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: Hero(
                                    tag: 'book-cover-${book.id}',
                                    child: BookCover(
                                      url: book.imagemUrl,
                                      width: 48,
                                      height: 64,
                                    ),
                                  ),
                                  title: Text(
                                    book.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    '${book.autor} · R\$ ${book.preco} · est. ${book.estoque}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (action) {
                                      if (action == 'edit') _openForm(book);
                                      if (action == 'delete') _archive(book);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                                      PopupMenuItem(value: 'delete', child: Text('Arquivar')),
                                    ],
                                  ),
                                  onTap: () => _openForm(book),
                                ),
                              ),
                            );
                          },
                          childCount: _items.length,
                        ),
                      ),
                    ),
                  if (_loadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
