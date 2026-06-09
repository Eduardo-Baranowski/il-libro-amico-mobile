import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/editor_repository.dart';

/// Mesmos gêneros do web / Open Library (`app/services/book_lookup.py`).
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

const _condicoes = [
  ('novo', 'Como novo'),
  ('usado', 'Usado'),
  ('raro', 'Raro'),
  ('autografado', 'Autografado'),
];

class EditorBookFormScreen extends ConsumerStatefulWidget {
  const EditorBookFormScreen({super.key, this.book});

  final EditorBook? book;

  bool get isEditing => book != null;

  @override
  ConsumerState<EditorBookFormScreen> createState() => _EditorBookFormScreenState();
}

class _EditorBookFormScreenState extends ConsumerState<EditorBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _autor;
  late final TextEditingController _preco;
  late final TextEditingController _estoque;
  late final TextEditingController _descricao;
  String _genero = 'Romance';
  String _condicao = 'novo';
  bool _saving = false;

  final _lookupController = TextEditingController();
  Timer? _lookupDebounce;
  List<BookLookupItem> _lookupResults = [];
  bool _lookupLoading = false;
  String? _lookupError;
  String? _coverPreviewUrl;
  int? _openLibraryCoverId;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titulo = TextEditingController(text: b?.titulo ?? '');
    _autor = TextEditingController(text: b?.autor ?? '');
    _preco = TextEditingController(text: b?.preco ?? '');
    _estoque = TextEditingController(text: '${b?.estoque ?? 0}');
    _descricao = TextEditingController(text: b?.descricao ?? '');
    if (b?.genero != null && b!.genero!.isNotEmpty) {
      _genero = _generos.contains(b.genero) ? b.genero! : 'Romance';
    }
    if (b?.condicao != null && b!.condicao!.isNotEmpty) {
      final match = _condicoes.where((c) => c.$1 == b.condicao).map((c) => c.$1);
      if (match.isNotEmpty) _condicao = match.first;
    }
    _coverPreviewUrl = b?.imagemUrl;
    for (final c in [_titulo, _autor, _preco, _estoque, _descricao]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _lookupController.addListener(_onLookupQueryChanged);
  }

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _lookupController.dispose();
    _titulo.dispose();
    _autor.dispose();
    _preco.dispose();
    _estoque.dispose();
    _descricao.dispose();
    super.dispose();
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
      const SnackBar(
        content: Text('Dados preenchidos — confira preço e estoque antes de publicar.'),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(editorRepositoryProvider);
    try {
      if (widget.isEditing) {
        await repo.updateBook(
          id: widget.book!.id,
          titulo: _titulo.text.trim(),
          autor: _autor.text.trim(),
          preco: _preco.text.trim(),
          estoque: _estoque.text.trim(),
          genero: _genero,
          descricao: _descricao.text.trim(),
          condicao: _condicao,
        );
      } else {
        await repo.createBook(
          titulo: _titulo.text.trim(),
          autor: _autor.text.trim(),
          preco: _preco.text.trim(),
          estoque: _estoque.text.trim(),
          genero: _genero,
          descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
          openLibraryCoverId: _openLibraryCoverId,
          condicao: _condicao,
        );
      }
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final coverUrl = _coverPreviewUrl ?? book?.imagemUrl;
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
                    title: Text(
                      widget.isEditing ? 'Editar livro' : 'Novo livro',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
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
                          Positioned(
                            right: -30,
                            top: -20,
                            child: Icon(
                              Icons.auto_stories_rounded,
                              size: 160,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Hero(
                                tag: book != null ? 'book-cover-${book.id}' : 'book-cover-new',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
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
                                    child: BookCover(
                                      url: coverUrl,
                                      width: 100,
                                      height: 140,
                                      borderRadius: 16,
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
                                    if (_preco.text.trim().isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _previewChip(
                                            Icons.sell_outlined,
                                            'R\$ ${_preco.text.trim()}',
                                          ),
                                          _previewChip(
                                            Icons.inventory_2_outlined,
                                            '${_estoque.text.trim().isEmpty ? '0' : _estoque.text.trim()} un.',
                                          ),
                                          _previewChip(Icons.category_outlined, _genero),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (!widget.isEditing) ...[
                              const SizedBox(height: 12),
                              _FormSection(
                                title: 'Buscar obra',
                                icon: Icons.travel_explore_rounded,
                                children: [
                                  Text(
                                    'Open Library — título, autor ou ISBN',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.muted.withValues(alpha: 0.95),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _lookupController,
                                    decoration: InputDecoration(
                                      hintText: 'ex: O Alienista, Machado de Assis, 978…',
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
                                    Text(
                                      _lookupError!,
                                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                                    ),
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
                                        separatorBuilder: (_, __) => Divider(
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
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item.titulo,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          [
                                                            item.autor,
                                                            if (item.ano != null) '${item.ano}',
                                                            if (item.isbn != null)
                                                              'ISBN ${item.isbn}',
                                                          ].join(' · '),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            color: AppTheme.muted,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.north_west_rounded,
                                                    size: 18,
                                                    color: AppTheme.primary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  if (_openLibraryCoverId != null &&
                                      _coverPreviewUrl != null) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        BookCover(
                                          url: _coverPreviewUrl,
                                          width: 48,
                                          height: 68,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Capa da Open Library (será baixada ao publicar)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.muted.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            _FormSection(
                              title: 'Obra',
                              icon: Icons.menu_book_rounded,
                              children: [
                                _LabeledField(
                                  label: 'Título',
                                  child: TextFormField(
                                    controller: _titulo,
                                    textCapitalization: TextCapitalization.sentences,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      hintText: 'ex: O Alienista',
                                      prefixIcon: Icon(Icons.title_rounded),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty ? 'Informe o título' : null,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _LabeledField(
                                  label: 'Autor',
                                  child: TextFormField(
                                    controller: _autor,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      hintText: 'Nome do autor',
                                      prefixIcon: Icon(Icons.person_outline_rounded),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty ? 'Informe o autor' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FormSection(
                              title: 'Gênero',
                              icon: Icons.local_offer_outlined,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _generos.map((g) {
                                    final selected = _genero == g;
                                    return FilterChip(
                                      label: Text(g),
                                      selected: selected,
                                      showCheckmark: false,
                                      selectedColor: AppTheme.primarySoft,
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: selected ? AppTheme.primary : AppTheme.muted,
                                      ),
                                      side: BorderSide(
                                        color: selected
                                            ? AppTheme.primary.withValues(alpha: 0.4)
                                            : Colors.black.withValues(alpha: 0.08),
                                      ),
                                      onSelected: (_) => setState(() => _genero = g),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FormSection(
                              title: 'Condição',
                              icon: Icons.verified_outlined,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _condicoes.map((c) {
                                    final selected = _condicao == c.$1;
                                    return FilterChip(
                                      label: Text(c.$2),
                                      selected: selected,
                                      showCheckmark: false,
                                      selectedColor: AppTheme.primarySoft,
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: selected ? AppTheme.primary : AppTheme.muted,
                                      ),
                                      side: BorderSide(
                                        color: selected
                                            ? AppTheme.primary.withValues(alpha: 0.4)
                                            : Colors.black.withValues(alpha: 0.08),
                                      ),
                                      onSelected: (_) => setState(() => _condicao = c.$1),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FormSection(
                              title: 'Venda',
                              icon: Icons.payments_outlined,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _LabeledField(
                                        label: 'Preço (R\$)',
                                        child: TextFormField(
                                          controller: _preco,
                                          keyboardType: const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                          textInputAction: TextInputAction.next,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[\d.,]'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            hintText: '0,00',
                                            prefixIcon: Icon(Icons.attach_money_rounded),
                                          ),
                                          validator: (v) => v == null || v.trim().isEmpty
                                              ? 'Obrigatório'
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _LabeledField(
                                        label: 'Estoque',
                                        child: TextFormField(
                                          controller: _estoque,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            hintText: '0',
                                            prefixIcon: Icon(Icons.layers_outlined),
                                          ),
                                          validator: (v) => v == null ||
                                                  int.tryParse(v.trim()) == null
                                              ? 'Inválido'
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FormSection(
                              title: 'Sinopse',
                              icon: Icons.notes_rounded,
                              children: [
                                TextFormField(
                                  controller: _descricao,
                                  maxLines: 5,
                                  minLines: 4,
                                  textCapitalization: TextCapitalization.sentences,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _save(),
                                  decoration: const InputDecoration(
                                    hintText: 'Breve resumo da obra para o catálogo…',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Opcional · ajuda leitores na loja',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.muted.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _SaveBar(
              saving: _saving,
              label: widget.isEditing ? 'Salvar alterações' : 'Publicar no catálogo',
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
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
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.muted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.label,
    required this.onSave,
  });

  final bool saving;
  final String label;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: AppTheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : () => context.pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
