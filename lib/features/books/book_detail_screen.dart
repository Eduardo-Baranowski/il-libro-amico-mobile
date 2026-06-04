import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../data/reader_repository.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  BookDetails? _book;
  bool _loading = true;
  String? _error;
  String _status = 'lendo';
  int? _nota;

  @override
  void initState() {
    super.initState();
    _load();
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
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Livro não encontrado.');
    } finally {
      setState(() => _loading = false);
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const BibDetailAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCover(book: book),
            Padding(
              padding: const EdgeInsets.all(AppTheme.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (book.genero != null && book.genero!.isNotEmpty)
                    Align(
                      alignment: Alignment.center,
                      child: BibStatusChip(label: book.genero!, tone: BibChipTone.sage),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    book.titulo,
                    textAlign: TextAlign.center,
                    style: AppTheme.displaySerif,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.autor,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySans.copyWith(
                      fontSize: 18,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: BibPriceText(book.preco, style: AppTheme.headlineSerif.copyWith(fontSize: 22))),
                  Text(
                    book.editora,
                    textAlign: TextAlign.center,
                    style: AppTheme.captionSans,
                  ),
                  const SizedBox(height: 24),
                  if (auth.isAuthenticated && auth.role == UserRole.leitor) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saveReading,
                            icon: const Icon(Icons.library_add_rounded, size: 20),
                            label: const Text('Salvar na estante'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BibCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Minha leitura', style: AppTheme.labelSans),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: const [
                              DropdownMenuItem(value: 'quero_ler', child: Text('Quero ler')),
                              DropdownMenuItem(value: 'lendo', child: Text('Lendo')),
                              DropdownMenuItem(value: 'lido', child: Text('Lido')),
                            ],
                            onChanged: (v) => setState(() => _status = v ?? 'lendo'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            value: _nota,
                            decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('—')),
                              ...List.generate(
                                5,
                                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                              ),
                            ],
                            onChanged: (v) => setState(() => _nota = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text('Sobre', style: AppTheme.headlineSerif.copyWith(fontSize: 20)),
                  const SizedBox(height: 12),
                  if (book.descricao != null && book.descricao!.isNotEmpty)
                    Text(
                      book.descricao!,
                      style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, height: 1.6),
                    )
                  else
                    Text(
                      'Sem descrição disponível.',
                      style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(label: 'Estoque', value: '${book.estoque} un.'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          label: 'Disponibilidade',
                          value: _stockLabel(book.statusEstoque),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stockLabel(String? s) => switch (s) {
        'esgotado' => 'Esgotado',
        'baixo' => 'Baixo',
        _ => 'Disponível',
      };
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
          Text(value, style: AppTheme.titleSerif.copyWith(color: AppTheme.primary)),
        ],
      ),
    );
  }
}
