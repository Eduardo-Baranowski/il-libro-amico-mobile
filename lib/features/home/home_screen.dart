import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
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
  final _highlights = <Book>[];
  int _page = 1;
  int _pages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _loadingHighlights = true;
  String? _error;

  bool get _hasMore => _page < _pages;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(page: 1);
    _loadHighlights();
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
    if (position.pixels >= position.maxScrollExtent - 280) {
      _load(page: _page + 1);
    }
  }

  Future<void> _loadHighlights() async {
    try {
      final res = await ref.read(readerRepositoryProvider).books(page: 1, perPage: 8);
      if (mounted) setState(() => _highlights..clear()..addAll(res.items));
    } catch (_) {
      // carrossel opcional
    } finally {
      if (mounted) setState(() => _loadingHighlights = false);
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

  Future<void> _refresh() async {
    await Future.wait([_load(page: 1), _loadHighlights()]);
  }

  String _statusLabel(String status) => switch (status) {
        'quero_ler' => 'Quero ler',
        'lendo' => 'Lendo',
        'lido' => 'Concluiu',
        _ => status,
      };

  BibChipTone _statusTone(String status) => switch (status) {
        'lido' => BibChipTone.neutral,
        'lendo' => BibChipTone.sage,
        _ => BibChipTone.terracotta,
      };

  String _statusVerb(String status) => switch (status) {
        'lendo' => 'está lendo',
        'lido' => 'terminou',
        'quero_ler' => 'quer ler',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          if (_highlights.isNotEmpty || _loadingHighlights)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.marginMobile,
                  8,
                  AppTheme.marginMobile,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BibSectionHeader(
                      title: 'Livros à venda',
                      actionLabel: 'Ver tudo',
                      onAction: () => context.go('/livros'),
                    ),
                    SizedBox(
                      height: 220,
                      child: _loadingHighlights && _highlights.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _highlights.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final b = _highlights[i];
                                return GestureDetector(
                                  onTap: () => context.push('/livro/${b.id}'),
                                  child: SizedBox(
                                    width: 130,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 2 / 3,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: AppTheme.radiusLg,
                                              border: Border.all(
                                                color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                                              ),
                                              boxShadow: AppTheme.cardShadow,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: BookCover(
                                              url: b.imagemUrl,
                                              width: 130,
                                              height: 195,
                                              borderRadius: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          b.titulo,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.titleSerif.copyWith(fontSize: 15),
                                        ),
                                        BibPriceText(b.preco),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
            sliver: SliverToBoxAdapter(
              child: BibSectionHeader(title: 'Seu círculo'),
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
                  child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
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
              padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 0, AppTheme.marginMobile, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FeedCard(
                      item: _items[index],
                      statusLabel: _statusLabel(_items[index].status),
                      statusTone: _statusTone(_items[index].status),
                      statusVerb: _statusVerb(_items[index].status),
                      onTap: () => context.push('/livro/${_items[index].livroId}'),
                    ),
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
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.item,
    required this.statusLabel,
    required this.statusTone,
    required this.statusVerb,
    required this.onTap,
  });

  final FeedItem item;
  final String statusLabel;
  final BibChipTone statusTone;
  final String statusVerb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BibCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(url: item.leitorImagemUrl, name: item.leitorNome, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTheme.labelSans,
                          children: [
                            TextSpan(
                              text: item.leitorNome,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: ' $statusVerb ',
                              style: AppTheme.bodySans.copyWith(
                                fontSize: 14,
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: item.livroTitulo,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(url: item.livroImagemUrl, width: 72, height: 96, borderRadius: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BibStatusChip(label: statusLabel, tone: statusTone),
                      const SizedBox(height: 8),
                      Text(item.livroAutor, style: AppTheme.titleSerif.copyWith(fontSize: 16)),
                      if (item.nota != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < item.nota! ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                      if (item.comentario != null && item.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${item.comentario!}"',
                          style: AppTheme.bodySans.copyWith(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
