import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';
import '../cart/cart_notifier.dart';

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
  final _comentario = TextEditingController();
  final _paginasLidasCtrl = TextEditingController();
  bool _descExpanded = false;
  final _readingSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comentario.dispose();
    _paginasLidasCtrl.dispose();
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
        _paginasLidasCtrl.text = book.myReading?.paginasLidas != null && book.myReading!.paginasLidas > 0
            ? '${book.myReading!.paginasLidas}'
            : '';
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
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre na sua conta para salvar leituras.')),
      );
      context.push('/entrar');
      return;
    }
    if (auth.role != UserRole.leitor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas leitores podem registrar leitura.')),
      );
      return;
    }
    try {
      int? paginasLidas;
      if (_status == 'lido' && _book!.paginas > 0) {
        paginasLidas = _book!.paginas;
      } else if (_status == 'lendo') {
        final rawText = _paginasLidasCtrl.text.trim();
        if (rawText.isNotEmpty) {
          final val = int.tryParse(rawText);
          if (val == null || val < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, insira um número válido de páginas lidas.')),
            );
            return;
          }
          if (_book!.paginas > 0 && val > _book!.paginas) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Páginas lidas não pode ser maior que o total do livro (${_book!.paginas}).')),
            );
            return;
          }
          paginasLidas = val;
        } else {
          paginasLidas = 0;
        }
      }

      await ref.read(readerRepositoryProvider).registerReading(
            livroId: widget.bookId,
            status: _status,
            nota: _nota,
            comentario: _comentario.text.trim().isEmpty ? null : _comentario.text.trim(),
            paginasLidas: paginasLidas,
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
        _paginasLidasCtrl.clear();
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _scrollToReadingSection() {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre na sua conta para adicionar livros à estante.')),
      );
      context.push('/entrar');
      return;
    }
    if (auth.role != UserRole.leitor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas leitores podem adicionar à estante.')),
      );
      return;
    }
    if (_readingSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _readingSectionKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openHistoryBottomSheet(BookDetails book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Histórico de leitura', style: AppTheme.titleSerif.copyWith(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Atualize a página onde você parou de ler:',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _paginasLidasCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Páginas lidas',
                      hintText: book.paginas > 0 ? 'ex: de 1 a ${book.paginas}' : 'Página atual',
                      suffixText: book.paginas > 0 ? '/ ${book.paginas}' : null,
                    ),
                    onChanged: (val) {
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final rawText = _paginasLidasCtrl.text.trim();
                      if (rawText.isNotEmpty) {
                        final val = int.tryParse(rawText);
                        if (val == null || val < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, insira um número válido de páginas.')),
                          );
                          return;
                        }
                        if (book.paginas > 0 && val > book.paginas) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Páginas lidas não pode ser maior que o total do livro (${book.paginas}).')),
                          );
                          return;
                        }
                      }
                      Navigator.pop(context);
                      await _saveReading();
                    },
                    child: const Text('Salvar Progresso'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openReviewBottomSheet(BookDetails book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Avaliação & Resenha', style: AppTheme.titleSerif.copyWith(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sua nota:',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      final isSelected = _nota != null && _nota! >= starVal;
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          _nota = (isSelected && _nota == starVal) ? null : starVal;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 36,
                            color: const Color(0xFFFBC02D),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _comentario,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Sua Resenha',
                      hintText: 'Conte o que achou da obra...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _saveReading();
                    },
                    child: const Text('Salvar Avaliação'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cartItems = ref.watch(cartProvider);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes'),
          backgroundColor: AppTheme.background,
        ),
        body: Center(child: Text(_error ?? 'Erro')),
      );
    }

    final book = _book!;

    // Compute average rating from reviews
    final ratedReviews = _reviews.where((r) => r.nota != null).toList();
    final double avgRating = ratedReviews.isEmpty
        ? 0.0
        : ratedReviews.map((r) => r.nota!).reduce((a, b) => a + b) / ratedReviews.length;

    final hasReading = book.myReading != null;
    final String estanteText = hasReading
        ? (book.myReading!.status == 'lendo'
            ? 'Lendo (Editar)'
            : book.myReading!.status == 'lido'
                ? 'Lido (Editar)'
                : 'Quero ler (Editar)')
        : 'Adicionar à estante';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Stack
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Blurred Cover Background
                Container(
                  height: 250,
                  width: double.infinity,
                  color: AppTheme.surfaceContainer,
                  child: book.imagemUrl != null && book.imagemUrl!.isNotEmpty
                      ? ClipRect(
                          child: ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: CachedNetworkImage(
                              imageUrl: book.imagemUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : null,
                ),
                // Overlay on top of blurred background
                Container(
                  height: 250,
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                // Floating back and cart buttons
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                          onPressed: () => context.push('/carrinho'),
                        ),
                      ),
                      if (cartItems.isNotEmpty)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartItems.length}',
                              style: AppTheme.captionSans.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Book Cover centered and overlapping the bottom edge
                Positioned(
                  bottom: -45,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(4), // Elegant white frame
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BookCover(
                            url: book.imagemUrl,
                            width: 125,
                            height: 180,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 58),

            // 2. Info Block (Left aligned, premium look)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.genero != null && book.genero!.isNotEmpty) ...[
                    Text(
                      book.genero!.toUpperCase(),
                      style: AppTheme.captionSans.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    book.titulo,
                    style: AppTheme.displaySerif.copyWith(fontSize: 24, height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.autor,
                    style: AppTheme.bodySans.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : '0.0',
                          style: AppTheme.labelSans.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) {
                          final isHalf = (avgRating - index) > 0.25 && (avgRating - index) < 0.75;
                          final isFull = (avgRating - index) >= 0.75;
                          return Icon(
                            isFull
                                ? Icons.star_rounded
                                : isHalf
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded,
                            size: 18,
                            color: const Color(0xFFFBC02D),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _reviews.isEmpty
                            ? 'Nenhuma avaliação'
                            : '${_reviews.length} ${_reviews.length == 1 ? "avaliação" : "avaliações"}',
                        style: AppTheme.captionSans.copyWith(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Actions Row
                  Row(
                    children: [
                      // Shelf Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _scrollToReadingSection,
                          icon: Icon(hasReading ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined),
                          label: Text(estanteText),
                          style: FilledButton.styleFrom(
                            backgroundColor: hasReading ? AppTheme.secondary : AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Purchase / Cart icon button
                      IconButton(
                        onPressed: () {
                          final price = double.tryParse(book.preco) ?? 0.0;
                          if (book.estoque <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Livro esgotado.')),
                            );
                            return;
                          }
                          if (price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Este livro não está disponível para venda.')),
                            );
                            return;
                          }

                          ref.read(cartProvider.notifier).addBook(book);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${book.titulo}" adicionado ao carrinho!'),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'VER CARRINHO',
                                onPressed: () => context.push('/carrinho'),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 4. Synopsis
                  Text(
                    'Sinopse',
                    style: AppTheme.titleSerif.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.descricao?.isNotEmpty == true ? book.descricao! : 'Sem descrição disponível.',
                    maxLines: _descExpanded ? null : 4,
                    overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: AppTheme.bodySans.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      height: 1.6,
                      fontSize: 14.5,
                    ),
                  ),
                  if (book.descricao != null && book.descricao!.length > 150) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => setState(() => _descExpanded = !_descExpanded),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _descExpanded ? 'Ver menos' : 'Ver mais',
                            style: AppTheme.labelSans.copyWith(color: AppTheme.primary, fontSize: 13),
                          ),
                          Icon(
                            _descExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 5. Ficha Técnica
                  Text(
                    'Detalhes do livro',
                    style: AppTheme.titleSerif.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _SkoobDetailItem(
                        icon: Icons.storefront_outlined,
                        text: book.editora,
                      ),
                      if (book.paginas > 0)
                        _SkoobDetailItem(
                          icon: Icons.menu_book_outlined,
                          text: '${book.paginas} páginas',
                        ),
                      _SkoobDetailItem(
                        icon: Icons.inventory_2_outlined,
                        text: book.estoque > 0 ? '${book.estoque} un. em estoque' : 'Esgotado',
                      ),
                      _SkoobDetailItem(
                        icon: Icons.info_outline_rounded,
                        text: book.condicao != null && book.condicao!.toLowerCase() == 'novo' ? 'Livro Novo' : 'Livro Usado',
                      ),
                      _SkoobDetailItem(
                        icon: Icons.local_offer_outlined,
                        text: 'R\$ ${book.preco}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // 6. Minha Leitura Section (Skoob-style)
                  if (auth.isAuthenticated && auth.role == UserRole.leitor) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: _readingSectionKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bookmark_border_rounded, color: AppTheme.primary, size: 22),
                              const SizedBox(width: 8),
                              Text('Minha leitura', style: AppTheme.titleSerif.copyWith(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          BibCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Status selection Dropdown/Pill button
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySoft,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: book.myReading != null ? _status : null,
                                        hint: Text(
                                          'Marcar status...',
                                          style: AppTheme.labelSans.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        dropdownColor: AppTheme.surfaceWhite,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                                        isExpanded: true,
                                        style: AppTheme.labelSans.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'quero_ler',
                                            child: Text('Quero ler'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'lendo',
                                            child: Text('Lendo'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'lido',
                                            child: Text('Lido'),
                                          ),
                                        ],
                                        onChanged: (val) async {
                                          if (val != null) {
                                            setState(() => _status = val);
                                            await _saveReading();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  if (book.myReading != null) ...[
                                    const SizedBox(height: 20),
                                    Text(
                                      'Opções rápidas para seu status de leitura:',
                                      style: AppTheme.captionSans.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        // Histórico de Leitura Option Card (only interactive when Lendo)
                                        Expanded(
                                          child: _QuickOptionCard(
                                            icon: Icons.history_rounded,
                                            label: 'Histórico de leitura',
                                            subtitle: _status == 'lendo'
                                                ? '${book.myReading?.paginasLidas ?? 0} / ${book.paginas} págs'
                                                : (_status == 'lido' ? 'Concluído' : 'Sem progresso'),
                                            onTap: _status == 'lendo'
                                                ? () => _openHistoryBottomSheet(book)
                                                : () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Defina o status como "Lendo" para atualizar as páginas lidas.'),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Avaliação & Resenha Option Card
                                        Expanded(
                                          child: _QuickOptionCard(
                                            icon: Icons.rate_review_outlined,
                                            label: 'Resenha & Avaliação',
                                            subtitle: _nota != null ? 'Nota: $_nota/5' : 'Não avaliado',
                                            onTap: () => _openReviewBottomSheet(book),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: _deleteReading,
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                                        label: const Text(
                                          'Remover da estante',
                                          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Adicione este livro à sua estante para começar a monitorar seu progresso e escrever resenhas.',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.captionSans.copyWith(
                                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                  ],

                  // 7. Reviews List
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.reviews_outlined, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Avaliações dos leitores',
                        style: AppTheme.titleSerif.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingReviews)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (_reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Nenhuma resenha ainda para este livro.',
                          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final r = _reviews[i];
                        return BibCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    UserAvatar(url: r.leitorImagemUrl, name: r.leitorNome, radius: 16),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        r.leitorNome,
                                        style: AppTheme.labelSans.copyWith(fontSize: 13),
                                      ),
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
                                        size: 14,
                                        color: const Color(0xFFFBC02D),
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
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickOptionCard extends StatelessWidget {
  const _QuickOptionCard({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.labelSans.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTheme.captionSans.copyWith(fontSize: 11, color: AppTheme.secondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkoobDetailItem extends StatelessWidget {
  const _SkoobDetailItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTheme.bodySans.copyWith(
              fontSize: 14.5,
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
