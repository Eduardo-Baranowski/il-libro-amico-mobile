import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

class ShelvesScreen extends ConsumerStatefulWidget {
  const ShelvesScreen({super.key});

  @override
  ConsumerState<ShelvesScreen> createState() => _ShelvesScreenState();
}

class _ShelvesScreenState extends ConsumerState<ShelvesScreen> {
  String _tab = 'lendo';
  final _items = <ReadingItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ref.read(authProvider).isAuthenticated) {
      setState(() {
        _loading = false;
        _items.clear();
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(readerRepositoryProvider).readings(
            page: 1,
            perPage: 40,
            status: _tab,
          );
      setState(() => _items..clear()..addAll(res.items));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar estante.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _switchTab(String tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.marginMobile),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Minha estante', style: AppTheme.headlineSerif),
              const SizedBox(height: 8),
              Text(
                'Entre para ver livros que você está lendo, já leu ou quer ler.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.push('/entrar'), child: const Text('Entrar')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 8, AppTheme.marginMobile, 0),
          child: Text('Minha estante', style: AppTheme.headlineSerif),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile, vertical: 12),
          child: Row(
            children: [
              _TabChip(label: 'Lendo', value: 'lendo', selected: _tab == 'lendo', onTap: _switchTab),
              _TabChip(label: 'Lidos', value: 'lido', selected: _tab == 'lido', onTap: _switchTab),
              _TabChip(label: 'Quero ler', value: 'quero_ler', selected: _tab == 'quero_ler', onTap: _switchTab),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum livro nesta prateleira.',
                            style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.marginMobile,
                              0,
                              AppTheme.marginMobile,
                              24,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppTheme.gutterMobile,
                              crossAxisSpacing: AppTheme.gutterMobile,
                              childAspectRatio: 0.58,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                              final r = _items[i];
                              return _ShelfCard(
                                item: r,
                                showProgress: _tab == 'lendo',
                                showRating: _tab == 'lido',
                                onTap: () => context.push('/livro/${r.livroId}'),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: AppTheme.radiusLg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTheme.labelSans.copyWith(
              color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({
    required this.item,
    required this.showProgress,
    required this.showRating,
    required this.onTap,
  });

  final ReadingItem item;
  final bool showProgress;
  final bool showRating;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: BookCover(url: item.imagemUrl, width: 200, height: 400, borderRadius: 0),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleSerif.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(item.autor, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.captionSans),
                  if (showRating && item.nota != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < item.nota! ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                  if (showProgress) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.35,
                      backgroundColor: AppTheme.surfaceContainer,
                      color: AppTheme.primary,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
