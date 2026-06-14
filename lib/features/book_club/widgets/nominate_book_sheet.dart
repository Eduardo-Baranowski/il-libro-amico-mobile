import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/admin_editor_models.dart';
import '../../../core/models/book_club_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/book_cover.dart';

class NominateBookData {
  NominateBookData({
    this.livroId,
    this.titulo,
    this.autor,
    this.motivo,
  });

  final int? livroId;
  final String? titulo;
  final String? autor;
  final String? motivo;
}

class NominateBookSheet extends StatefulWidget {
  const NominateBookSheet({
    super.key,
    required this.searchBooks,
    required this.onSubmit,
  });

  final Future<GlobalSearchResult> Function(String query) searchBooks;
  final Future<BookClubNomination> Function(NominateBookData data) onSubmit;

  @override
  State<NominateBookSheet> createState() => _NominateBookSheetState();
}

class _NominateBookSheetState extends State<NominateBookSheet> {
  final _searchController = TextEditingController();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _motivoController = TextEditingController();

  List<SearchBookHit> _results = [];
  SearchBookHit? _selectedBook;
  bool _manualMode = false;
  bool _searching = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _tituloController.dispose();
    _autorController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.length < 2) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final res = await widget.searchBooks(query);
      if (mounted) {
        setState(() {
          _results = res.books;
          _manualMode = res.books.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        NominateBookData(
          livroId: _selectedBook?.id,
          titulo: _selectedBook?.titulo ?? _tituloController.text.trim(),
          autor: _selectedBook?.autor ?? _autorController.text.trim(),
          motivo: _motivoController.text.trim(),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final selectedTitle = _selectedBook?.titulo ?? _tituloController.text.trim();
    final selectedAuthor = _selectedBook?.autor ?? _autorController.text.trim();
    final canSubmit = _selectedBook != null ||
        (_manualMode && selectedTitle.isNotEmpty && selectedAuthor.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Confirmar indicação', style: AppTheme.headlineSerif),
              const SizedBox(height: 8),
              Text(
                'Busque no catálogo ou informe título e autor manualmente.',
                style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar título ou autor...',
                  filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  suffixIcon: IconButton(
                    icon: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    onPressed: _search,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.radiusLg,
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              if (_results.isNotEmpty)
                ..._results.take(5).map(
                      (book) => ListTile(
                        leading: BookCover(url: book.imagemUrl, width: 40, height: 56),
                        title: Text(book.titulo, style: AppTheme.labelSans),
                        subtitle: Text(book.autor, style: AppTheme.captionSans),
                        selected: _selectedBook?.id == book.id,
                        onTap: () => setState(() {
                          _selectedBook = book;
                          _manualMode = false;
                        }),
                      ),
                    ),
              TextButton(
                onPressed: () => setState(() {
                  _manualMode = true;
                  _selectedBook = null;
                }),
                child: const Text('Indicar livro que não está no catálogo'),
              ),
              if (_manualMode) ...[
                TextField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _autorController,
                  decoration: const InputDecoration(labelText: 'Autor'),
                ),
              ],
              if (_selectedBook != null || (_manualMode && canSubmit)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_selectedBook != null)
                      BookCover(url: _selectedBook!.imagemUrl, width: 56, height: 80),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nova proposta', style: AppTheme.captionSans.copyWith(color: AppTheme.primary)),
                          Text(selectedTitle, style: AppTheme.titleSerif),
                          Text(
                            selectedAuthor,
                            style: AppTheme.bodySans.copyWith(
                              color: AppTheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _motivoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Por que devemos ler este livro?',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.radiusLg,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTheme.captionSans.copyWith(color: AppTheme.error)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: !_submitting && canSubmit ? _submit : null,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Enviar indicação'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
