import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _items = <FeedItem>[];
  int _page = 1;
  int _pages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  bool get _hasMore => _page < _pages;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(page: 1);
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
      _load(page: _page + 1);
    }
  }

  Future<void> _load({required int page}) async {
    if (page > 1 && (_loadingMore || !_hasMore)) return;

    if (page == 1) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final res = await ref.read(readerRepositoryProvider).feed(page: page);
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('ApiException(0): ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  String _statusLabel(String status) => switch (status) {
        'quero_ler' => 'Quero ler',
        'lendo' => 'Lendo',
        'lido' => 'Lido',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumina Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => context.go('/buscar'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(page: 1),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Comunidade de leitores',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Nenhuma atividade no feed ainda.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _FeedCard(
                      item: _items[index],
                      statusLabel: _statusLabel(_items[index].status),
                      onTap: () => context.push('/livro/${_items[index].livroId}'),
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
            if (!_loading && !_hasMore && _items.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 24),
                  child: Center(
                    child: Text(
                      'Você viu tudo por agora',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.item,
    required this.statusLabel,
    required this.onTap,
  });

  final FeedItem item;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(url: item.livroImagemUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.leitorNome,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$statusLabel · ${item.livroTitulo}',
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      if (item.comentario != null &&
                          item.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(item.comentario!),
                      ],
                      if (item.nota != null) ...[
                        const SizedBox(height: 4),
                        Text('Nota: ${item.nota}/5'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
