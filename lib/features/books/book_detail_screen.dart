import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  BookDetails? _book;
  List<BookReview> _reviews = [];
  bool _loading = true;
  bool _loadingReviews = false;
  String? _error;
  String _status = 'lendo';
  int? _nota;
  bool _purchasing = false;
  final _comentario = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final book = await ref.read(readerRepositoryProvider).bookDetails(widget.bookId);
      setState(() {
        _book = book;
        _status = book.myReading?.status ?? 'lendo';
        _nota = book.myReading?.nota;
        _comentario.text = book.myReading?.comentario ?? '';
      });
      _loadReviews();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Livro não encontrado.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final list = await ref.read(readerRepositoryProvider).bookReviews(widget.bookId);
      if (mounted) setState(() => _reviews = list);
    } catch (_) {
      // opcional
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _saveReading() async {
    final auth = ref.read(authProvider);
    if (auth.role != UserRole.leitor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas leitores podem registrar leitura.')),
      );
      return;
    }
    try {
      await ref.read(readerRepositoryProvider).registerReading(
            livroId: widget.bookId,
            status: _status,
            nota: _nota,
            comentario: _comentario.text.trim().isEmpty ? null : _comentario.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leitura salva!')),
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteReading() async {
    final myReading = _book?.myReading;
    if (myReading == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover leitura'),
        content: const Text('Tem certeza que deseja remover este livro da sua estante? Sua resenha também será excluída.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(readerRepositoryProvider).deleteReading(myReading.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leitura removida!')),
        );
        _comentario.clear();
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _purchase() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre como leitor para comprar.')),
      );
      return;
    }
    if (auth.role != UserRole.leitor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas leitores podem comprar.')),
      );
      return;
    }
    setState(() => _purchasing = true);
    try {
      await ref.read(readerRepositoryProvider).purchaseBook(widget.bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra realizada!')),
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _book == null) {
      return Scaffold(
        appBar: const BibDetailAppBar(),
        body: Center(child: Text(_error ?? 'Erro')),
      );
    }

    final book = _book!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: const BibDetailAppBar(),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _HeroCover(book: book)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.marginMobile),
                child: Column(
                  children: [
                    if (book.genero != null && book.genero!.isNotEmpty)
                      BibStatusChip(label: book.genero!, tone: BibChipTone.sage),
                    const SizedBox(height: 8),
                    Text(book.titulo, textAlign: TextAlign.center, style: AppTheme.displaySerif),
                    const SizedBox(height: 4),
                    Text(
                      book.autor,
                      style: AppTheme.bodySans.copyWith(fontSize: 18, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    BibPriceText(book.preco, style: AppTheme.headlineSerif.copyWith(fontSize: 22)),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.onSurfaceVariant,
                  indicatorColor: AppTheme.primary,
                  tabs: const [
                    Tab(text: 'Sobre'),
                    Tab(text: 'Resenhas'),
                    Tab(text: 'Comprar'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _AboutTab(
                book: book,
                auth: auth,
                status: _status,
                nota: _nota,
                comentarioController: _comentario,
                onStatusChanged: (v) => setState(() => _status = v),
                onNotaChanged: (v) => setState(() => _nota = v),
                onSaveReading: _saveReading,
                onDeleteReading: _deleteReading,
              ),
              _ReviewsTab(
                reviews: _reviews,
                loading: _loadingReviews,
                currentUserId: auth.userId,
                onEditTap: (tabContext) {
                  DefaultTabController.of(tabContext).animateTo(0);
                },
              ),
              _PurchaseTab(book: book, purchasing: _purchasing, onPurchase: _purchase),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(color: AppTheme.background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.book,
    required this.auth,
    required this.status,
    required this.nota,
    required this.comentarioController,
    required this.onStatusChanged,
    required this.onNotaChanged,
    required this.onSaveReading,
    required this.onDeleteReading,
  });

  final BookDetails book;
  final AuthState auth;
  final String status;
  final int? nota;
  final TextEditingController comentarioController;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int?> onNotaChanged;
  final VoidCallback onSaveReading;
  final VoidCallback onDeleteReading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.marginMobile),
      children: [
        Text(
          book.descricao?.isNotEmpty == true ? book.descricao! : 'Sem descrição disponível.',
          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, height: 1.6),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _InfoTile(label: 'Estoque', value: '${book.estoque} un.')),
            const SizedBox(width: 12),
            Expanded(child: _InfoTile(label: 'Editora', value: book.editora)),
          ],
        ),
        if (auth.isAuthenticated && auth.role == UserRole.leitor) ...[
          const SizedBox(height: 24),
          BibCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Minha leitura', style: AppTheme.labelSans),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'quero_ler', child: Text('Quero ler')),
                    DropdownMenuItem(value: 'lendo', child: Text('Lendo')),
                    DropdownMenuItem(value: 'lido', child: Text('Lido')),
                  ],
                  onChanged: (v) => onStatusChanged(v ?? 'lendo'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: nota,
                  decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ...List.generate(
                      5,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                    ),
                  ],
                  onChanged: onNotaChanged,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: comentarioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comentário / Resenha (opcional)',
                    hintText: 'O que achou do livro?',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (book.myReading != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDeleteReading,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                          ),
                          child: const Text('Remover'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: onSaveReading,
                        child: const Text('Salvar na estante'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({
    required this.reviews,
    required this.loading,
    required this.currentUserId,
    required this.onEditTap,
  });

  final List<BookReview> reviews;
  final bool loading;
  final int? currentUserId;
  final ValueChanged<BuildContext> onEditTap;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (reviews.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma resenha ainda.',
          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.marginMobile),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = reviews[i];
        final isMine = currentUserId != null && r.leitorId == currentUserId;
        return BibCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(url: r.leitorImagemUrl, name: r.leitorNome, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.leitorNome, style: AppTheme.labelSans)),
                  if (isMine)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                      onPressed: () => onEditTap(context),
                    ),
                ],
              ),
              if (r.nota != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (j) => Icon(
                      j < r.nota! ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
              if (r.comentario != null && r.comentario!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${r.comentario!}"',
                  style: AppTheme.bodySans.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseTab extends StatelessWidget {
  const _PurchaseTab({
    required this.book,
    required this.purchasing,
    required this.onPurchase,
  });

  final BookDetails book;
  final bool purchasing;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final available = book.estoque > 0;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.marginMobile),
      child: BibCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comprar na loja', style: AppTheme.headlineSerif.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Editora: ${book.editora}', style: AppTheme.bodySans),
            const SizedBox(height: 12),
            BibPriceText(book.preco, style: AppTheme.headlineSerif.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              available ? '${book.estoque} un. disponíveis' : 'Esgotado',
              style: AppTheme.captionSans.copyWith(
                color: available ? AppTheme.secondary : AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: available && !purchasing ? onPurchase : null,
              child: Text(purchasing ? 'Processando…' : 'Comprar agora'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.book});

  final BookDetails book;

  @override
  Widget build(BuildContext context) {
    final url = book.imagemUrl;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          else
            Container(color: AppTheme.surfaceContainer),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.background.withValues(alpha: 0.2),
                  AppTheme.background,
                ],
                stops: const [0.4, 0.75, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: AppTheme.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTheme.captionSans.copyWith(letterSpacing: 0.08)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.titleSerif.copyWith(color: AppTheme.primary, fontSize: 15)),
        ],
      ),
    );
  }
}
