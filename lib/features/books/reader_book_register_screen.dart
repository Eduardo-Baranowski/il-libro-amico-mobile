import 'dart:io' as dart_io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_mime.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';
import '../../data/admin_repository.dart';

enum _RegisterStep { isbn, confirm }

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

class ReaderBookRegisterScreen extends ConsumerStatefulWidget {
  const ReaderBookRegisterScreen({super.key, this.bookId});

  final int? bookId;

  bool get isEditing => bookId != null;

  @override
  ConsumerState<ReaderBookRegisterScreen> createState() =>
      _ReaderBookRegisterScreenState();
}

class _ReaderBookRegisterScreenState
    extends ConsumerState<ReaderBookRegisterScreen> {
  _RegisterStep _step = _RegisterStep.isbn;
  final _isbnController = TextEditingController();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _authorNationalityController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _paginasController = TextEditingController();

  bool _loading = false;
  bool _loadingBook = false;
  bool _submitting = false;
  String? _error;
  BookLookupResponse? _lookup;
  BookLookupItem? _selected;
  bool _manualMode = false;
  bool _addToShelf = true;
  String _genero = 'Romance';
  List<String> _nationalities = [];

  String? _coverPreviewUrl;
  int? _openLibraryCoverId;
  XFile? _pickedCoverFile;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _step = _RegisterStep.confirm;
      _loadBookForEdit();
    }
    _fetchNationalities();
  }

  Future<void> _fetchNationalities() async {
    try {
      final list = await ref.read(adminRepositoryProvider).listAuthorNationalities();
      if (mounted) setState(() => _nationalities = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _tituloController.dispose();
    _autorController.dispose();
    _descricaoController.dispose();
    _paginasController.dispose();
    _authorNationalityController.dispose();
    super.dispose();
  }

  Future<void> _loadBookForEdit() async {
    setState(() {
      _loadingBook = true;
      _error = null;
    });
    try {
      final book = await ref
          .read(readerRepositoryProvider)
          .bookDetails(widget.bookId!);
      if (!mounted) return;
      setState(() {
        _tituloController.text = book.titulo;
        _autorController.text = book.autor;
        _descricaoController.text = book.descricao ?? '';
        _paginasController.text = book.paginas > 0 ? '${book.paginas}' : '';
        _isbnController.text = book.isbn ?? '';
        if (book.genero != null && _generos.contains(book.genero)) {
          _genero = book.genero!;
        }
        _coverPreviewUrl = book.imagemUrl;
        _manualMode = true;
        _loadingBook = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loadingBook = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar livro.';
          _loadingBook = false;
        });
      }
    }
  }

  Future<void> _pickCover(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1800,
      );
      if (file == null || !mounted) return;
      setState(() {
        _pickedCoverFile = file;
        _coverPreviewUrl = file.path;
        _openLibraryCoverId = null;
      });
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
              'Capa do livro',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: AppTheme.primary,
              ),
              title: const Text(
                'Galeria de fotos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickCover(ImageSource.gallery);
              },
            ),
            if (_pickedCoverFile != null || _coverPreviewUrl != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade600,
                ),
                title: Text(
                  'Remover capa',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                  ),
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

  void _applyLookupItem(BookLookupItem item, {bool notify = true}) {
    void apply() {
      _selected = item;
      _tituloController.text = item.titulo;
      _autorController.text = item.autor;
      if (item.genero != null && _generos.contains(item.genero)) {
        _genero = item.genero!;
      }
      if (item.descricao != null && item.descricao!.isNotEmpty) {
        _descricaoController.text = item.descricao!;
      }
      _coverPreviewUrl = item.imagemUrl;
      _openLibraryCoverId = item.coverId;
      _pickedCoverFile = null;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  Future<void> _searchIsbn() async {
    final q = _isbnController.text.trim();
    if (q.length < 2) {
      setState(() => _error = 'Informe ao menos 2 caracteres.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ref.read(readerRepositoryProvider).lookupBooks(q);
      if (!mounted) return;

      if (res.existingBook != null) {
        setState(() {
          _lookup = res;
          _selected = null;
          _manualMode = false;
          _step = _RegisterStep.confirm;
          _loading = false;
        });
        return;
      }

      if (res.items.isEmpty) {
        setState(() {
          _lookup = res;
          _manualMode = true;
          _step = _RegisterStep.confirm;
          _loading = false;
        });
        return;
      }

      final first = res.items.first;
      setState(() {
        _lookup = res;
        _manualMode = false;
        _applyLookupItem(first, notify: false);
        _step = _RegisterStep.confirm;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Busca indisponível no momento.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final existing = _lookup?.existingBook;
    if (!widget.isEditing && existing != null) {
      if (_addToShelf) {
        await ref
            .read(readerRepositoryProvider)
            .registerReading(livroId: existing.id, status: 'quero_ler');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Livro já estava no acervo. Adicionado à sua estante!',
            ),
          ),
        );
        context.pop(existing.id);
      }
      return;
    }

    final titulo = _tituloController.text.trim();
    final autor = _autorController.text.trim();
    if (titulo.isEmpty || autor.isEmpty) {
      setState(() => _error = 'Título e autor são obrigatórios.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final pInt = int.tryParse(_paginasController.text.trim());
    final imageFile = _pickedCoverFile != null
        ? (
            fieldName: 'imagem',
            filePath: _pickedCoverFile!.path,
            mimeType: mimeTypeFromPath(_pickedCoverFile!.path),
          )
        : null;
    final openLibraryCoverId = imageFile == null ? _openLibraryCoverId : null;

    try {
      final repo = ref.read(readerRepositoryProvider);
        if (widget.isEditing) {
        await repo.updateBook(
          id: widget.bookId!,
          titulo: titulo,
          autor: autor,
          genero: _genero,
          descricao: _descricaoController.text.trim(),
          isbn: _isbnController.text.trim().isEmpty
              ? null
              : _isbnController.text.trim(),
          paginas: pInt,
          imageFile: imageFile,
          openLibraryCoverId: openLibraryCoverId,
          // reader update route doesn't currently accept authorNationality in repo.updateBook
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livro atualizado com sucesso!')),
        );
        context.pop(true);
      } else {
        final result = await repo.submitBook(
          titulo: titulo,
          autor: autor,
          genero: _genero,
          descricao: _descricaoController.text.trim().isEmpty
              ? null
              : _descricaoController.text.trim(),
          isbn: _isbnController.text.trim().isEmpty
              ? _selected?.isbn
              : _isbnController.text.trim(),
          paginas: pInt,
          openLibraryCoverId: openLibraryCoverId,
          addToShelf: _addToShelf,
          imageFile: imageFile,
          authorNationality: _authorNationalityController.text.trim().isEmpty ? null : _authorNationalityController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        context.pop(result.id);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildCoverPicker() {
    return Center(
      child: GestureDetector(
        onTap: _showPickCoverSheet,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _pickedCoverFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      dart_io.File(_pickedCoverFile!.path),
                      width: 110,
                      height: 154,
                      fit: BoxFit.cover,
                    ),
                  )
                : BookCover(
                    url: _coverPreviewUrl,
                    width: 110,
                    height: 154,
                    borderRadius: 12,
                  ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
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
    );
  }

  Widget _buildBookFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _tituloController,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _autorController,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(labelText: 'Autor(es)'),
        ),
        const SizedBox(height: 12),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            final q = textEditingValue.text.toLowerCase();
            if (q.isEmpty) return _nationalities;
            return _nationalities.where((e) => e.toLowerCase().contains(q)).toList();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            controller.text = _authorNationalityController.text;
            controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
            controller.addListener(() {
              _authorNationalityController.text = controller.text;
            });
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: const InputDecoration(labelText: 'Nacionalidade do autor'),
              validator: (v) {
                final val = v?.trim() ?? '';
                if (val.isEmpty) return null;
                if (!_nationalities.contains(val)) return 'Selecione uma nacionalidade existente';
                return null;
              },
            );
          },
          onSelected: (s) => _authorNationalityController.text = s,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _isbnController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9Xx\-]')),
          ],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(labelText: 'ISBN (opcional)'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _genero,
          decoration: const InputDecoration(labelText: 'Gênero'),
          items: _generos
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) => setState(() => _genero = v ?? 'Romance'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _paginasController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(labelText: 'Páginas (opcional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descricaoController,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Sinopse (opcional)',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: const BibDetailAppBar(title: 'Cadastro de livros'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Cadastro de livros', style: AppTheme.headlineSerif),
                const SizedBox(height: 8),
                Text(
                  'Entre para contribuir com o acervo da comunidade.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySans.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.push('/entrar'),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.isEditing && _loadingBook) {
      return const Scaffold(
        appBar: BibDetailAppBar(
          title: 'Editar livro',
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          titleColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.isEditing && _error != null && _tituloController.text.isEmpty) {
      return Scaffold(
        appBar: const BibDetailAppBar(
          title: 'Editar livro',
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          titleColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadBookForEdit,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final title = widget.isEditing
        ? 'Editar livro'
        : _step == _RegisterStep.isbn
        ? 'Cadastro de livros'
        : 'Confirmar livro';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: BibDetailAppBar(
        title: title,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        titleColor: Colors.white,
      ),
      body: widget.isEditing || _step == _RegisterStep.confirm
          ? _buildConfirmStep()
          : _buildIsbnStep(),
    );
  }

  Widget _buildIsbnStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adicionar ao acervo',
            style: AppTheme.displaySerif.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 8),
          Text(
            'Informe o ISBN do livro para buscarmos os dados automaticamente.',
            style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: AppTheme.radiusXl,
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Antes de cadastrar, busque o livro no catálogo. Assim evitamos duplicatas no acervo.',
                    style: AppTheme.bodySans.copyWith(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Informe o ISBN do livro:',
            style: AppTheme.labelSans.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _isbnController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9Xx\-]')),
            ],
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(hintText: 'Digite aqui'),
            onSubmitted: (_) => _searchIsbn(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _searchIsbn,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXl),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Continuar',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() {
              _manualMode = true;
              _step = _RegisterStep.confirm;
            }),
            child: const Text('Cadastrar manualmente sem ISBN'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    final existing = _lookup?.existingBook;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (existing != null && !widget.isEditing) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft.withValues(alpha: 0.5),
                borderRadius: AppTheme.radiusXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Já está no acervo',
                    style: AppTheme.labelSans.copyWith(color: AppTheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(existing.titulo, style: AppTheme.titleSerif),
                  Text(
                    existing.autor,
                    style: AppTheme.bodySans.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              widget.isEditing ? 'Altere os dados do livro' : 'Dados do livro',
              style: AppTheme.headlineSerif,
            ),
            const SizedBox(height: 20),
            _buildCoverPicker(),
            const SizedBox(height: 8),
            Text(
              'Toque na capa para enviar uma foto',
              textAlign: TextAlign.center,
              style: AppTheme.captionSans.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            if (!widget.isEditing &&
                !_manualMode &&
                (_lookup?.items.length ?? 0) > 1) ...[
              Text('Outras edições:', style: AppTheme.labelSans),
              const SizedBox(height: 8),
              ..._lookup!.items.map((item) {
                final selected =
                    _selected?.titulo == item.titulo &&
                    _selected?.autor == item.autor;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: BookCover(
                    url: item.imagemUrl,
                    width: 36,
                    height: 52,
                    borderRadius: 6,
                  ),
                  title: Text(
                    item.titulo,
                    maxLines: 2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    item.autor,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primary,
                        )
                      : null,
                  onTap: () => _applyLookupItem(item),
                );
              }),
              const SizedBox(height: 12),
            ],
            _buildBookFields(),
          ],
          if (!widget.isEditing && existing == null) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Adicionar à minha estante'),
              subtitle: const Text('Como "Quero ler"'),
              value: _addToShelf,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) => setState(() => _addToShelf = v),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXl),
            ),
            child: Text(
              _submitting
                  ? 'Salvando…'
                  : widget.isEditing
                  ? 'Salvar alterações'
                  : existing != null
                  ? 'Ir para o livro'
                  : 'Cadastrar no acervo',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          if (!widget.isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _step = _RegisterStep.isbn;
                _error = null;
              }),
              child: const Text('Voltar'),
            ),
          ],
        ],
      ),
    );
  }
}
