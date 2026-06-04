import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';
import '../editor/editor_catalog_body.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final _scrollController = ScrollController();
  final _items = <Book>[];
  int _page = 1;
  int _pages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  bool get _hasMore => _page < _pages;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(1);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _load(_page + 1);
    }
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
      final res = await ref.read(readerRepositoryProvider).books(page: page);
      if (!mounted) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(res.items);
        _page = res.page;
        _pages = res.pages;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao carregar livros.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authProvider).role == UserRole.editor) {
      return const EditorCatalogBody();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: RefreshIndicator(
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
                child: Center(child: Text('Nenhum livro no catálogo.')),
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
                            leading: BookCover(
                              url: book.imagemUrl,
                              width: 48,
                              height: 64,
                            ),
                            title: Text(
                              book.titulo,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text('${book.autor} · R\$ ${book.preco}'),
                            trailing: _stockChip(book.statusEstoque),
                            onTap: () => context.push('/livro/${book.id}'),
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
            if (!_loading && !_hasMore && _items.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: Text(
                      'Fim do catálogo',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _stockChip(String? status) {
    if (status == null) return null;
    final (label, color) = switch (status) {
      'esgotado' => ('Esgotado', AppTheme.error),
      'baixo' => ('Baixo', Colors.orange),
      _ => ('OK', Colors.green),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
