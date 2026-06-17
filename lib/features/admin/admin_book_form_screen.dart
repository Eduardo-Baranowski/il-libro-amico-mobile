import 'dart:async';
import 'dart:io' as dart_io;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/admin_repository.dart';
import '../../data/editor_repository.dart';

const _generos = [
  'Romance',
  'Mistério',
  'Ficção Científica',
  'Fantasia',
  'Terror',
  'História',
  'Biografia',
  'Autoajuda',
  'Técnico',
  'Infantil',
];

class AdminBookFormScreen extends ConsumerStatefulWidget {
  const AdminBookFormScreen({super.key});

  @override
  ConsumerState<AdminBookFormScreen> createState() => _AdminBookFormScreenState();
}

class _AdminBookFormScreenState extends ConsumerState<AdminBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _autor;
  late final TextEditingController _descricao;
  late final TextEditingController _paginas;
  String _genero = 'Romance';
  bool _saving = false;

  final _lookupController = TextEditingController();
  Timer? _lookupDebounce;
  List<BookLookupItem> _lookupResults = [];
  bool _lookupLoading = false;
  String? _lookupError;
  String? _coverPreviewUrl;
  int? _openLibraryCoverId;
  XFile? _pickedCoverFile;

  List<Editora> _editoras = [];
  int? _selectedEditoraId;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController();
    _autor = TextEditingController();
    _descricao = TextEditingController();
    _paginas = TextEditingController();

    for (final c in [_titulo, _autor, _descricao, _paginas]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _lookupController.addListener(_onLookupQueryChanged);
    _loadEditoras();
  }

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _lookupController.dispose();
    _titulo.dispose();
    _autor.dispose();
    _descricao.dispose();
    _paginas.dispose();
    super.dispose();
  }

  Future<void> _loadEditoras() async {
    try {
      final editoras = await ref.read(adminRepositoryProvider).listEditoras();
      if (mounted) {
        setState(() {
          _editoras = editoras;
          if (_editoras.isNotEmpty) {
            _selectedEditoraId = _editoras.first.id;
          }
        });
      }
    } catch (_) {}
  }

  void _onLookupQueryChanged() {
    _lookupDebounce?.cancel();
    final q = _lookupController.text.trim();
    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _lookupResults = [];
          _lookupError = null;
          _lookupLoading = false;
        });
      }
      return;
    }
    _lookupDebounce = Timer(const Duration(milliseconds: 400), () => _runLookup(q));
    if (mounted) setState(() {});
  }

  Future<void> _runLookup(String q) async {
    setState(() {
      _lookupLoading = true;
      _lookupError = null;
    });
    try {
      // Reusing editor lookup since it's the same logic
      final res = await ref.read(editorRepositoryProvider).lookupBooks(q);
      if (mounted) setState(() => _lookupResults = res.items);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _lookupResults = [];
          _lookupError = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lookupResults = [];
          _lookupError = 'Busca indisponível.';
        });
      }
    } finally {
      if (mounted) setState(() => _lookupLoading = false);
    }
  }

  Future<void> _pickCover(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1800,
      );
      if (file == null) return;
      if (mounted) {
        setState(() {
          _pickedCoverFile = file;
          _coverPreviewUrl = file.path;
          _openLibraryCoverId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir a galeria: $e')),
        );
      }
    }
  }

  void _showPickCoverSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolher capa',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              ),
              title: const Text('Galeria de fotos', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickCover(ImageSource.gallery);
              },
            ),
            if (_pickedCoverFile != null || _openLibraryCoverId != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600),
                ),
                title: Text(
                  'Remover capa personalizada',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red.shade600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _pickedCoverFile = null;
                    _openLibraryCoverId = null;
                    _coverPreviewUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _applyLookup(BookLookupItem item) {
    setState(() {
      _titulo.text = item.titulo;
      _autor.text = item.autor;
      if (item.genero != null && _generos.contains(item.genero)) {
        _genero = item.genero!;
      }
      if (item.descricao != null && item.descricao!.isNotEmpty) {
        _descricao.text = item.descricao!;
      }
      _coverPreviewUrl = item.imagemUrl;
      _openLibraryCoverId = item.coverId;
      _lookupController.clear();
      _lookupResults = [];
      _lookupError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados preenchidos automaticamente.')),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEditoraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione ou crie uma editora')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      final pInt = int.tryParse(_paginas.text.trim());
      final imageFile = _pickedCoverFile != null
          ? (fieldName: 'imagem', filePath: _pickedCoverFile!.path, mimeType: 'image/jpeg')
          : null;

      await repo.createBook(
        editoraId: _selectedEditoraId!,
        titulo: _titulo.text.trim(),
        autor: _autor.text.trim(),
        genero: _genero,
        descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
        openLibraryCoverId: imageFile == null ? _openLibraryCoverId : null,
        imageFile: imageFile,
        paginas: pInt,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livro cadastrado com sucesso!')),
        );
        context.pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _previewChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titlePreview = _titulo.text.trim().isEmpty ? 'Sem título' : _titulo.text.trim();
    final authorPreview = _autor.text.trim().isEmpty ? 'Autor' : _autor.text.trim();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 196,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    title: const Text(
                      'Novo livro (Admin)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_coverPreviewUrl != null && _coverPreviewUrl!.isNotEmpty)
                            Positioned.fill(
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: _pickedCoverFile != null
                                    ? Image.file(
                                        dart_io.File(_pickedCoverFile!.path),
                                        fit: BoxFit.cover,
                                      )
                                    : BookCover(
                                        url: _coverPreviewUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        borderRadius: 0,
                                      ),
                              ),
                            )
                          else
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.primary.withValues(alpha: 0.85),
                                    const Color(0xFF8B6FFF),
                                  ],
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Hero(
                                tag: 'book-cover-new',
                                child: Material(
                                  color: Colors.transparent,
                                  child: GestureDetector(
                                    onTap: _showPickCoverSheet,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.25),
                                                blurRadius: 24,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: _pickedCoverFile != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: Image.file(
                                                    dart_io.File(_pickedCoverFile!.path),
                                                    width: 100,
                                                    height: 140,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : BookCover(
                                                  url: _coverPreviewUrl,
                                                  width: 100,
                                                  height: 140,
                                                  borderRadius: 16,
                                                ),
                                        ),
                                        Positioned(
                                          bottom: -10,
                                          right: -10,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titlePreview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authorPreview,
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _previewChip(Icons.category_outlined, _genero),
                                        if (_paginas.text.trim().isNotEmpty)
                                          _previewChip(
                                            Icons.menu_book_outlined,
                                            '${_paginas.text.trim()} pág.',
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.travel_explore_rounded, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Buscar obra',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _lookupController,
                                    decoration: InputDecoration(
                                      hintText: 'Open Library — título, autor ou ISBN',
                                      prefixIcon: const Icon(Icons.search_rounded),
                                      suffixIcon: _lookupLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          : _lookupController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear_rounded),
                                                  onPressed: () => _lookupController.clear(),
                                                )
                                              : null,
                                    ),
                                  ),
                                  if (_lookupError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(_lookupError!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                                  ],
                                  if (_lookupResults.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Material(
                                      color: AppTheme.background,
                                      borderRadius: BorderRadius.circular(14),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _lookupResults.length,
                                        separatorBuilder: (_, _) => Divider(
                                          height: 1,
                                          color: Colors.black.withValues(alpha: 0.06),
                                        ),
                                        itemBuilder: (context, i) {
                                          final item = _lookupResults[i];
                                          return InkWell(
                                            onTap: () => _applyLookup(item),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                              child: Row(
                                                children: [
                                                  BookCover(
                                                    url: item.imagemUrl,
                                                    width: 36,
                                                    height: 52,
                                                    borderRadius: 8,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(item.titulo, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          [item.autor, if (item.ano != null) '${item.ano}', if (item.isbn != null) 'ISBN ${item.isbn}'].join(' · '),
                                                          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.business_rounded, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Editora',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_editoras.isEmpty)
                                    const Text('Nenhuma editora cadastrada. Por favor, cadastre uma na tela de Editoras primeiro.')
                                  else
                                    DropdownButtonFormField<int>(
                                      value: _selectedEditoraId,
                                      decoration: const InputDecoration(
                                        labelText: 'Selecione a Editora',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _editoras
                                          .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome)))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selectedEditoraId = v),
                                      validator: (v) => v == null ? 'Selecione uma editora' : null,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.menu_book_rounded, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Obra',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _titulo,
                                    decoration: const InputDecoration(labelText: 'Título', prefixIcon: Icon(Icons.title_rounded)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o título' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _autor,
                                    decoration: const InputDecoration(labelText: 'Autor', prefixIcon: Icon(Icons.person_outline_rounded)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o autor' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _paginas,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(labelText: 'Páginas', prefixIcon: Icon(Icons.numbers_rounded)),
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    value: _genero,
                                    decoration: const InputDecoration(labelText: 'Gênero', prefixIcon: Icon(Icons.category_outlined)),
                                    items: _generos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                    onChanged: (v) => setState(() => _genero = v ?? 'Romance'),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _descricao,
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: const InputDecoration(labelText: 'Sinopse/Descrição', alignLabelWithHint: true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _saving ? null : _save,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                _saving ? 'Salvando…' : 'Cadastrar Livro',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
