import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';
import '../profile/profile_edit_dialog.dart';

final profileDetailsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(readerRepositoryProvider);
  return repo.profileDetails();
});

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

  Widget _buildProfileImage(String? url, String name) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainer, width: 4),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceLow,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
                errorWidget: (context, url, error) => _avatarPlaceholder(initial),
              )
            : _avatarPlaceholder(initial),
      ),
    );
  }

  Widget _avatarPlaceholder(String initial) {
    return Container(
      color: AppTheme.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppTheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: 48,
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: AppTheme.titleSerif.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppTheme.captionSans.copyWith(
            fontSize: 10,
            letterSpacing: 1.1,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.outlineVariant.withValues(alpha: 0.4),
    );
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

    final profileAsync = ref.watch(profileDetailsProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro ao carregar perfil: $err')),
      data: (profile) {
        final user = profile['user'] as Map<String, dynamic>;
        final stats = profile['stats'] as Map<String, dynamic>;
        final generos = (profile['generos'] as List?)?.cast<String>() ?? [];
        final name = user['nome'] as String? ?? '';
        final bio = user['bio'] as String? ?? '';
        final imageUrl = user['imagem_url'] as String?;

        final lidosCount = stats['lidos'] ?? 0;
        final vendaCount = stats['venda'] ?? 0;
        final seguidoresCount = stats['seguidores'] ?? 0;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileDetailsProvider);
            await _load();
          },
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Profile Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 24, AppTheme.marginMobile, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with Edit Button Stack
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildProfileImage(imageUrl, name),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              elevation: 2,
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const ProfileEditDialog(),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // User Name
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: AppTheme.displaySerif.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 6),
                      // Bio
                      if (bio.isNotEmpty)
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodySans.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('$lidosCount', 'Lidos'),
                            _buildVerticalDivider(),
                            _buildStatItem('$vendaCount', 'À Venda'),
                            _buildVerticalDivider(),
                            _buildStatItem('$seguidoresCount', 'Seguidores'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Favorite Genres Wrap
                      if (generos.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: generos.map((g) => Chip(
                            label: Text(g),
                            labelStyle: AppTheme.labelSans.copyWith(
                              fontSize: 12,
                              color: AppTheme.onSecondaryContainer,
                            ),
                            backgroundColor: AppTheme.secondaryContainer,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              // 2. Tab Bar Section
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile, vertical: 8),
                  child: Row(
                    children: [
                      _TabChip(label: 'Lendo', value: 'lendo', selected: _tab == 'lendo', onTap: _switchTab),
                      _TabChip(label: 'Lidos', value: 'lido', selected: _tab == 'lido', onTap: _switchTab),
                      _TabChip(label: 'Quero ler', value: 'quero_ler', selected: _tab == 'quero_ler', onTap: _switchTab),
                    ],
                  ),
                ),
              ),
              // 3. Grid of books
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(_error!)),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Nenhum livro nesta prateleira.',
                      style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.marginMobile,
                    12,
                    AppTheme.marginMobile,
                    40,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppTheme.gutterMobile,
                      crossAxisSpacing: AppTheme.gutterMobile,
                      childAspectRatio: 0.55,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final r = _items[i];
                        return _ShelfCard(
                          item: r,
                          showProgress: _tab == 'lendo',
                          showRating: _tab == 'lido',
                          onTap: () => context.push('/livro/${r.livroId}'),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
                    if (item.paginas > 0) ...[
                      LinearProgressIndicator(
                        value: (item.paginasLidas / item.paginas).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.surfaceContainer,
                        color: AppTheme.primary,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((item.paginasLidas / item.paginas).clamp(0.0, 1.0) * 100).toStringAsFixed(0)}% lido',
                        style: AppTheme.captionSans.copyWith(fontSize: 10),
                      ),
                    ] else ...[
                      Text(
                        item.paginasLidas > 0
                            ? '${item.paginasLidas} páginas lidas'
                            : 'Lendo',
                        style: AppTheme.captionSans.copyWith(fontSize: 10),
                      ),
                    ],
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
