import 'package:flutter/material.dart';

import '../../../core/models/book_club_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/book_cover.dart';

class NominationCard extends StatelessWidget {
  const NominationCard({
    super.key,
    required this.nomination,
    required this.onVote,
    this.compact = false,
    this.votingEnabled = true,
  });

  final BookClubNomination nomination;
  final VoidCallback onVote;
  final bool compact;
  final bool votingEnabled;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactNominationCard(
        nomination: nomination,
        onVote: onVote,
        votingEnabled: votingEnabled,
      );
    }
    return _FullNominationCard(
      nomination: nomination,
      onVote: onVote,
      votingEnabled: votingEnabled,
    );
  }
}

class _CompactNominationCard extends StatelessWidget {
  const _CompactNominationCard({
    required this.nomination,
    required this.onVote,
    required this.votingEnabled,
  });

  final BookClubNomination nomination;
  final VoidCallback onVote;
  final bool votingEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.radiusXl,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.15)),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppTheme.radiusMd,
            child: SizedBox(
              width: 72,
              height: 96,
              child: BookCover(url: nomination.imagemUrl, width: 72, height: 96, borderRadius: 8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomination.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleSerif.copyWith(fontSize: 16),
                  ),
                  Text(
                    nomination.autor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.captionSans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '${nomination.votesCount} votos',
                        style: AppTheme.labelSans.copyWith(color: AppTheme.primary),
                      ),
                      const Spacer(),
                      if (votingEnabled)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: nomination.votedByMe ? Colors.white : AppTheme.primary,
                            backgroundColor: nomination.votedByMe ? AppTheme.primary : null,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: onVote,
                          child: Text(nomination.votedByMe ? 'Votado' : 'Votar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullNominationCard extends StatelessWidget {
  const _FullNominationCard({
    required this.nomination,
    required this.onVote,
    required this.votingEnabled,
  });

  final BookClubNomination nomination;
  final VoidCallback onVote;
  final bool votingEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.radiusXl,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.15)),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppTheme.radiusMd,
                child: SizedBox(
                  width: 96,
                  height: 144,
                  child: BookCover(url: nomination.imagemUrl, width: 96, height: 144, borderRadius: 8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nomination.titulo, style: AppTheme.titleSerif),
                    Text(
                      nomination.autor,
                      style: AppTheme.labelSans.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    if (nomination.genero != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: AppTheme.radiusSm,
                        ),
                        child: Text(
                          nomination.genero!.toUpperCase(),
                          style: AppTheme.captionSans.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: AppTheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${nomination.votesCount}',
                              style: AppTheme.displaySerif.copyWith(
                                fontSize: 28,
                                color: AppTheme.primary,
                                height: 1,
                              ),
                            ),
                            Text(
                              'VOTOS',
                              style: AppTheme.captionSans.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        if (votingEnabled)
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    nomination.votedByMe ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                                foregroundColor:
                                    nomination.votedByMe ? Colors.white : AppTheme.onSurface,
                              ),
                              onPressed: onVote,
                              icon: Icon(
                                nomination.votedByMe
                                    ? Icons.check_circle_rounded
                                    : Icons.how_to_vote_outlined,
                                size: 18,
                              ),
                              label: Text(nomination.votedByMe ? 'Votado' : 'Votar'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (nomination.indicadoPor != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Indicado por ${nomination.indicadoPor!.nome}',
                style: AppTheme.captionSans.copyWith(
                  color: AppTheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FeaturedBookCard extends StatelessWidget {
  const FeaturedBookCard({
    super.key,
    required this.book,
    this.onJoinDiscussion,
    this.onDetails,
  });

  final BookClubNomination book;
  final VoidCallback? onJoinDiscussion;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.radiusXl,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: book.imagemUrl != null && book.imagemUrl!.isNotEmpty
                ? Image.network(
                    book.imagemUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.primarySoft,
                      child: const Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 48),
                    ),
                  )
                : Container(
                    color: AppTheme.primarySoft,
                    child: const Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 48),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.cycleTitulo != null)
                  Text(
                    'LEITURA DO CLUBE',
                    style: AppTheme.captionSans.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(book.titulo, style: AppTheme.headlineSerif.copyWith(fontSize: 24)),
                if (book.motivo != null && book.motivo!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${book.motivo!}"',
                    style: AppTheme.bodySans.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(book.autor, style: AppTheme.labelSans)),
                    if (book.genero != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: AppTheme.radiusSm,
                        ),
                        child: Text(
                          book.genero!,
                          style: AppTheme.captionSans.copyWith(color: AppTheme.onSecondaryContainer),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onDetails != null && book.livroId != null)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDetails,
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: const Text('Ver livro'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
