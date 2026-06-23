import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

final autorProfileProvider = FutureProvider.autoDispose.family<AutorProfile, int>((ref, id) {
  return ref.watch(readerRepositoryProvider).autorProfile(id);
});

class AutorScreen extends ConsumerWidget {
  const AutorScreen({super.key, required this.autorId});

  final int autorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(autorProfileProvider(autorId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(err is ApiException ? err.message : 'Erro ao carregar autor.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(autorProfileProvider(autorId)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  profile.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.85),
                        AppTheme.secondary.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.marginMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _StatCard(label: 'Livros', value: '${profile.totalLivros}'),
                        const SizedBox(width: 12),
                        _StatCard(label: 'Leituras', value: '${profile.totalLeituras}'),
                      ],
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(profile.bio!, style: AppTheme.bodySans.copyWith(height: 1.5)),
                    ],
                    const SizedBox(height: 24),
                    Text('Obras no acervo', style: AppTheme.headlineSerif.copyWith(fontSize: 20)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (profile.livros.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Nenhum livro cadastrado ainda.',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.muted),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final livro = profile.livros[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 0, AppTheme.marginMobile, 12),
                      child: Material(
                        color: AppTheme.surfaceWhite,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.radiusLg,
                          side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/livro/${livro.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                BookCover(url: livro.imagemUrl, width: 48, height: 68, borderRadius: 8),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        livro.titulo,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.titleSerif.copyWith(fontSize: 15),
                                      ),
                                      if (livro.genero != null) ...[
                                        const SizedBox(height: 4),
                                        Text(livro.genero!, style: AppTheme.captionSans),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: profile.livros.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: AppTheme.radiusLg,
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTheme.displaySerif.copyWith(fontSize: 28, color: AppTheme.primary)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: AppTheme.captionSans.copyWith(letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }
}
