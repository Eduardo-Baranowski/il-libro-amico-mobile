import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
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
      final book =
          await ref.read(readerRepositoryProvider).bookDetails(widget.bookId);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Erro')),
      );
    }

    final book = _book!;

    return Scaffold(
      appBar: AppBar(title: Text(book.titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: BookCover(url: book.imagemUrl, width: 140, height: 200)),
            const SizedBox(height: 16),
            Text(book.titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    )),
            Text(book.autor, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 8),
            Text('R\$ ${book.preco} · ${book.editora}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (book.descricao != null && book.descricao!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(book.descricao!),
            ],
            if (auth.isAuthenticated && auth.role == UserRole.leitor) ...[
              const SizedBox(height: 24),
              const Text('Minha leitura',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _status,
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
                initialValue: _nota,
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saveReading,
                child: const Text('Salvar leitura'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
