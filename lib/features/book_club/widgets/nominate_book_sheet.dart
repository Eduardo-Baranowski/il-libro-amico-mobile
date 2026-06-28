import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/admin_editor_models.dart';
import '../../../core/models/book_club_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_mime.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../data/book_club_repository.dart';

class NominateBookData {
  NominateBookData({
    this.livroId,
    this.titulo,
    this.autor,
    this.editoraId,
    this.editora,
    this.motivo,
    this.imageFile,
    this.editoraImageFile,
  });

  final int? livroId;
  final String? titulo;
  final String? autor;
  final int? editoraId;
  final String? editora;
  final String? motivo;
  final ({String fieldName, String filePath, String mimeType})? imageFile;
  final ({String fieldName, String filePath, String mimeType})? editoraImageFile;
}

class NominateBookSheet extends ConsumerStatefulWidget {
  const NominateBookSheet({
    super.key,
    required this.searchBooks,
    required this.onSubmit,
  });

  final Future<GlobalSearchResult> Function(String query) searchBooks;
  final Future<BookClubNomination> Function(NominateBookData data) onSubmit;

  @override
  ConsumerState<NominateBookSheet> createState() => _NominateBookSheetState();
}

class _NominateBookSheetState extends ConsumerState<NominateBookSheet> {
  final _searchController = TextEditingController();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _editoraController = TextEditingController();
  final _motivoController = TextEditingController();

  final _imagePicker = ImagePicker();
  List<SearchBookHit> _results = [];
  SearchBookHit? _selectedBook;
  bool _manualMode = false;
  bool _searching = false;
  bool _submitting = false;
  String? _error;
  XFile? _pickedCoverFile;

  List<Editora> _editoras = [];
  Editora? _selectedEditora;
  bool _loadingEditoras = false;
  Timer? _editoraSearchDebounce;
  XFile? _pickedEditoraImageFile;

  @override
  void dispose() {
    _searchController.dispose();
    _tituloController.dispose();
    _autorController.dispose();
    _editoraController.dispose();
    _motivoController.dispose();
    _editoraSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadEditoras(String query) async {
    if (!mounted) return;
    setState(() {
      _loadingEditoras = true;
    });

    try {
      final editoras = await ref.read(bookClubRepositoryProvider).listEditoras(search: query);
      if (!mounted) return;
      setState(() {
        _editoras = editoras;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEditoras = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingEditoras = false;
        });
      }
    }
  }

  void _onEditoraChanged(String value) {
    if (_selectedEditora != null && _selectedEditora!.nome.trim() != value.trim()) {
      setState(() => _selectedEditora = null);
    }

    _editoraSearchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _editoras = [];
        _loadingEditoras = false;
      });
      return;
    }

    _editoraSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadEditoras(trimmed);
    });
  }

  Future<void> _pickPublisherImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (file == null || !mounted) return;
      setState(() {
        _pickedEditoraImageFile = file;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Não foi possível selecionar a imagem da editora.');
      }
    }
  }

  void _removePublisherImage() {
    setState(() {
      _pickedEditoraImageFile = null;
    });
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

  Future<void> _pickCover() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1800,
      );
      if (file == null || !mounted) return;

      setState(() {
        _pickedCoverFile = file;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Não foi possível selecionar a capa.');
      }
    }
  }

  void _removeCover() {
    setState(() {
      _pickedCoverFile = null;
    });
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
          editoraId: _selectedEditora?.id,
          editora: _selectedEditora == null && _manualMode ? _editoraController.text.trim() : null,
          motivo: _motivoController.text.trim(),
          imageFile: _pickedCoverFile != null
              ? (
                  fieldName: 'imagem',
                  filePath: _pickedCoverFile!.path,
                  mimeType: mimeTypeFromPath(_pickedCoverFile!.path),
                )
              : null,
          editoraImageFile: _selectedEditora == null && _manualMode && _pickedEditoraImageFile != null
              ? (
                  fieldName: 'imagem',
                  filePath: _pickedEditoraImageFile!.path,
                  mimeType: mimeTypeFromPath(_pickedEditoraImageFile!.path),
                )
              : null,
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
                const SizedBox(height: 8),
                TextField(
                  controller: _editoraController,
                  decoration: const InputDecoration(
                    labelText: 'Editora (opcional)',
                    hintText: 'Busque uma editora existente ou crie uma nova',
                  ),
                  onChanged: _onEditoraChanged,
                ),
                if (_selectedEditora != null) ...[
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Editora selecionada',
                      filled: true,
                      fillColor: AppTheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.radiusLg,
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedEditora = null;
                            _editoraController.clear();
                            _editoras = [];
                          });
                        },
                      ),
                    ),
                    child: Text(_selectedEditora!.nome),
                  ),
                ] else if (_loadingEditoras || _editoras.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: _loadingEditoras
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _editoras.length,
                            itemBuilder: (context, index) {
                              final editora = _editoras[index];
                              return ListTile(
                                title: Text(editora.nome),
                                leading: editora.imagemUrl != null
                                    ? BookCover(url: editora.imagemUrl, width: 32, height: 44)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedEditora = editora;
                                    _editoraController.text = editora.nome;
                                    _editoras = [];
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
                const SizedBox(height: 8),
                if (_selectedEditora == null && _editoraController.text.trim().isNotEmpty) ...[
                  Text(
                    'Criar nova editora com este nome?',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickPublisherImage,
                          icon: const Icon(Icons.photo),
                          label: Text(
                            _pickedEditoraImageFile == null ? 'Adicionar imagem da editora' : 'Alterar imagem da editora',
                          ),
                        ),
                      ),
                      if (_pickedEditoraImageFile != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _removePublisherImage,
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: 'Remover imagem da editora',
                        ),
                      ],
                    ],
                  ),
                  if (_pickedEditoraImageFile != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_pickedEditoraImageFile!.path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
                if (_selectedEditora == null && !_loadingEditoras && _editoraController.text.trim().isNotEmpty && _editoras.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma editora encontrada. Será criada uma nova editora ao enviar esta indicação.',
                    style: AppTheme.captionSans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickCover,
                        icon: const Icon(Icons.photo),
                        label: Text(_pickedCoverFile == null ? 'Adicionar capa' : 'Alterar capa'),
                      ),
                    ),
                    if (_pickedCoverFile != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _removeCover,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Theme.of(context).colorScheme.error,
                        tooltip: 'Remover capa',
                      ),
                    ],
                  ],
                ),
                if (_pickedCoverFile != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_pickedCoverFile!.path),
                      width: 100,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
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
                if (_manualMode && _editoraController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Editora: ${_selectedEditora?.nome ?? _editoraController.text.trim()}',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ],
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
