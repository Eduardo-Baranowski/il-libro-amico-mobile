import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminBooksScreen extends ConsumerStatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  ConsumerState<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends ConsumerState<AdminBooksScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  PaginatedResponse<AdminBook>? _response;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _load(1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load(int page) async {
    if (page == 1) {
      if (mounted) setState(() => _loading = true);
    } else {
      if (mounted) setState(() => _loadingMore = true);
    }

    try {
      final response = await ref.read(adminRepositoryProvider).listBooks(page: page);
      if (mounted) {
        setState(() {
          _response = response;
          _currentPage = page;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao carregar livros.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _deleteBook(AdminBook book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover livro?'),
        content: Text(
          'Tem certeza que deseja remover "${book.titulo}" de ${book.editorNome} permanentemente do sistema? Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(adminRepositoryProvider).deleteBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Livro "${book.titulo}" removido permanentemente')),
        );
        _load(1);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Moderação de Livros'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _load(1),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _response == null || _response!.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhum livro no catálogo'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(1),
                      child: ListView.builder(
                        itemCount: _response!.items.length + (_loadingMore ? 1 : 0) + 1,
                        itemBuilder: (ctx, i) {
                          // Pagination info at top
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Total: ${_response!.total} livros',
                                style: AppTheme.labelSans.copyWith(color: Colors.grey),
                              ),
                            );
                          }

                          // Loading indicator at end
                          if (i == _response!.items.length + 1) {
                            if (_loadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            // Show load more button if not last page
                            if (_currentPage < _response!.pages) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () => _load(_currentPage + 1),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    label: const Text('Carregar mais'),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final book = _response!.items[i - 1];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.titulo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              book.autor,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                Chip(
                                                  label: Text('R\$ ${book.preco}', style: const TextStyle(fontSize: 12)),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                Chip(
                                                  label: Text('Est. ${book.estoque}', style: const TextStyle(fontSize: 12)),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                if (book.genero != null)
                                                  Chip(
                                                    label: Text(book.genero!, style: const TextStyle(fontSize: 12)),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteBook(book),
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                                        tooltip: 'Remover livro',
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.store_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Editora: ${book.editorNome}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
