import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';
import '../editor/editor_catalog_body.dart';

const _marketFilters = [
  ('Todos', null),
  ('Usado', 'usado'),
  ('Raro', 'raro'),
  ('Autografado', 'autografado'),
];

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
  String? _condicao;

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
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) _load(_page + 1);
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
      final res = await ref.read(readerRepositoryProvider).books(
            page: page,
            condicao: _condicao,
          );
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

  void _onFilter(String? condicao) {
    if (_condicao == condicao) return;
    setState(() => _condicao = condicao);
    _load(1);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).role;
    final auth = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: role == UserRole.editor
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/editor/livro/novo'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Vender livro'),
            )
          : auth.isAuthenticated
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/livros/cadastrar'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.library_add_rounded),
                  label: const Text('Cadastrar livro'),
                )
              : null,
      body: role == UserRole.editor
          ? const EditorCatalogBody()
          : RefreshIndicator(
      onRefresh: () => _load(1),
      color: AppTheme.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 8, AppTheme.marginMobile, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    readOnly: true,
                    onTap: () => context.go('/buscar'),
                    decoration: const InputDecoration(
                      hintText: 'Busque seu próximo livro…',
                      prefixIcon: Icon(Icons.search_rounded, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _marketFilters.map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: BibGenreChip(
                            label: f.$1,
                            selected: _condicao == f.$2,
                            onTap: () => _onFilter(f.$2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 0, AppTheme.marginMobile, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppTheme.gutterMobile,
                  crossAxisSpacing: AppTheme.gutterMobile,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _MarketBookCard(
                    book: _items[i],
                    onTap: () => context.push('/livro/${_items[i].id}'),
                  ),
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
    );
  }
}

class _MarketBookCard extends StatelessWidget {
  const _MarketBookCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.radiusLg,
        side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(boxShadow: AppTheme.cardShadow, borderRadius: AppTheme.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: book.imagemUrl != null && book.imagemUrl!.isNotEmpty
                        ? BookCover(url: book.imagemUrl, width: 200, height: 400, borderRadius: 0)
                        : const ColoredBox(
                            color: AppTheme.primarySoft,
                            child: Center(
                              child: Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 40),
                            ),
                          ),
                  ),
                  if (book.condicao == 'raro' || book.condicao == 'autografado')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: BibStatusChip(
                        label: book.condicao == 'raro' ? 'Raro' : 'Signed',
                        tone: book.condicao == 'raro' ? BibChipTone.terracotta : BibChipTone.sage,
                      ),
                    ),
                ],
              ),
            ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleSerif.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.autor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.captionSans,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BibPriceText(book.preco, style: AppTheme.titleSerif.copyWith(fontSize: 15)),
                        if (book.genero != null)
                          Flexible(
                            child: Text(
                              book.genero!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppTheme.captionSans.copyWith(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
