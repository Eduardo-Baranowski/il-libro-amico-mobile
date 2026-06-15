import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/models/book_club_models.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../data/book_club_repository.dart';
import '../../data/search_repository.dart';
import 'widgets/nominate_book_sheet.dart';
import 'widgets/nomination_card.dart';

class BookClubHubScreen extends ConsumerStatefulWidget {
  const BookClubHubScreen({super.key, required this.clubId});

  final int clubId;

  @override
  ConsumerState<BookClubHubScreen> createState() => _BookClubHubScreenState();
}

class _BookClubHubScreenState extends ConsumerState<BookClubHubScreen> {
  BookClubHub? _hub;
  bool _loading = true;
  String? _error;
  final _votingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      if (!refresh) _loading = true;
      _error = null;
    });
    try {
      final hub = await ref.read(bookClubRepositoryProvider).hub(widget.clubId);
      if (mounted) setState(() => _hub = hub);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isOwnerOrAdmin {
    final auth = ref.read(authProvider);
    return _hub?.club?.isOwner == true || auth.role == UserRole.admin;
  }

  Future<void> _vote(BookClubNomination nomination) async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      if (mounted) context.push('/entrar');
      return;
    }

    setState(() => _votingIds.add(nomination.id));
    try {
      final result =
          await ref.read(bookClubRepositoryProvider).toggleVote(widget.clubId, nomination.id);
      if (!mounted || _hub == null) return;

      setState(() {
        _hub = _hub!.copyWith(
          nominationsPreview: _hub!.nominationsPreview.map((n) {
            if (n.id != nomination.id) return n;
            return n.copyWith(votesCount: result.votesCount, votedByMe: result.voted);
          }).toList(),
          userStats: _hub!.userStats != null
              ? BookClubUserStats(
                  votesUsed: _hub!.maxVotesPerUser - result.votesRemaining,
                  votesRemaining: result.votesRemaining,
                  hasNominated: _hub!.userStats!.hasNominated,
                  myNominationId: _hub!.userStats!.myNominationId,
                )
              : null,
        );
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _votingIds.remove(nomination.id));
    }
  }

  Future<void> _openNominate() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      if (mounted) context.push('/entrar');
      return;
    }
    if (_hub?.userStats?.hasNominated == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já indicou um livro neste ciclo')),
      );
      return;
    }

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NominateBookSheet(
        searchBooks: (query) => ref.read(searchRepositoryProvider).search(query),
        onSubmit: (data) => ref.read(bookClubRepositoryProvider).nominate(
              widget.clubId,
              livroId: data.livroId,
              titulo: data.titulo,
              autor: data.autor,
              motivo: data.motivo,
            ),
      ),
    );

    if (submitted == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livro indicado com sucesso!')),
        );
      }
      await _load(refresh: true);
    }
  }

  String _formatDrawDate(String? iso) {
    if (iso == null) return 'Em breve';
    final date = DateTime.tryParse(iso);
    if (date == null) return 'Em breve';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _performDraw() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Realizar Sorteio'),
        content: const Text('Deseja sortear o livro do mês agora? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sortear'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(bookClubRepositoryProvider).draw(widget.clubId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorteio realizado com sucesso!')),
        );
      }
      await _load(refresh: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openInviteDialog() async {
    final queryController = TextEditingController();
    List<SearchUserHit> results = [];
    bool searching = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Convidar membro'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: queryController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nome ou e-mail',
                    hintText: 'Digite para buscar...',
                  ),
                  onSubmitted: (q) async {
                    if (q.trim().length < 2) return;
                    setDialogState(() => searching = true);
                    try {
                      final res = await ref.read(searchRepositoryProvider).search(q.trim());
                      setDialogState(() {
                        results = res.users;
                        searching = false;
                      });
                    } catch (_) {
                      setDialogState(() => searching = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (searching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                else if (results.isEmpty)
                  Text(
                    'Busque um usuário para convidar',
                    style: AppTheme.captionSans.copyWith(color: AppTheme.onSurfaceVariant),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final user = results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                user.imagemUrl != null ? NetworkImage(user.imagemUrl!) : null,
                            child: user.imagemUrl == null ? Text(user.nome[0]) : null,
                          ),
                          title: Text(user.nome),
                          onTap: () async {
                            try {
                              await ref
                                  .read(bookClubRepositoryProvider)
                                  .inviteUser(widget.clubId, userId: user.id);
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text('${user.nome} adicionado ao clube')),
                                );
                              }
                            } on ApiException catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(SnackBar(content: Text(e.message)));
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
    queryController.dispose();
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final clubName = _hub?.club?.nome ?? 'Clube do Livro';

    return Scaffold(
      appBar: BibDetailAppBar(title: clubName),
      floatingActionButton: _hub?.cycle.isOpen == true
          ? FloatingActionButton.extended(
              onPressed: _openNominate,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Indicar livro'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppTheme.marginMobile),
                    children: [
                      Text(clubName, style: AppTheme.headlineSerif),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTheme.bodySans.copyWith(color: AppTheme.error)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.go('/clube'),
                        child: const Text('Voltar aos clubes'),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.marginMobile,
                      8,
                      AppTheme.marginMobile,
                      96,
                    ),
                    children: [
                      if (_hub != null) ...[
                        _CycleHeader(cycle: _hub!.cycle, clubName: clubName),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/clube/${widget.clubId}/membros'),
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Ver membros'),
                          ),
                        ),
                        if (_isOwnerOrAdmin) ...[
                          if (_hub!.club?.conviteCodigo != null) ...[
                            const SizedBox(height: 12),
                            BibCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.vpn_key_outlined, color: AppTheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Código de convite', style: AppTheme.labelSans),
                                        Text(
                                          _hub!.club!.conviteCodigo!,
                                          style: AppTheme.titleSerif.copyWith(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _copyInviteCode(_hub!.club!.conviteCodigo!),
                                    icon: const Icon(Icons.copy_rounded),
                                    tooltip: 'Copiar código',
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.push('/clube/${widget.clubId}/solicitacoes'),
                                  icon: const Icon(Icons.person_add_alt_1_outlined),
                                  label: const Text('Solicitações'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openInviteDialog,
                                  icon: const Icon(Icons.group_add_outlined),
                                  label: const Text('Convidar'),
                                ),
                              ),
                            ],
                          ),
                          if (_hub!.cycle.dataSorteio == null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _performDraw,
                                icon: const Icon(Icons.casino_rounded),
                                label: Text(
                                  auth.role == UserRole.admin && _hub!.club?.isOwner != true
                                      ? 'Realizar Sorteio (Admin)'
                                      : 'Realizar Sorteio',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        if (_hub!.featuredBook != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text('Livro do mês', style: AppTheme.headlineSerif.copyWith(fontSize: 22)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primarySoft.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _hub!.featuredBook!.cycleTitulo ?? _hub!.cycle.titulo,
                                  style: AppTheme.labelSans.copyWith(color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FeaturedBookCard(
                            book: _hub!.featuredBook!,
                            onDetails: _hub!.featuredBook!.livroId != null
                                ? () => context.push('/livro/${_hub!.featuredBook!.livroId}')
                                : null,
                          ),
                          const SizedBox(height: 28),
                        ],
                        BibSectionHeader(
                          title: 'Próximo sorteio',
                          actionLabel: 'Ver todas',
                          onAction: () => context.push('/clube/${widget.clubId}/votacao'),
                        ),
                        Text(
                          'O sorteio da leitura do clube acontece em ${_hub!.cycle.diasAteSorteio} dias.',
                          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        BibCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _formatDrawDate(_hub!.cycle.dataFimVotacao),
                                style: AppTheme.labelSans,
                              ),
                              const Spacer(),
                              Text(
                                '${_hub!.totalNominations} indicações',
                                style: AppTheme.captionSans.copyWith(color: AppTheme.outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_hub!.userStats != null)
                          BibCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.how_to_vote_outlined, color: AppTheme.secondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Você tem ${_hub!.userStats!.votesRemaining} de ${_hub!.maxVotesPerUser} votos restantes neste ciclo.',
                                    style: AppTheme.bodySans,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (_hub!.nominationsPreview.isEmpty)
                          BibCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(Icons.auto_stories_outlined, size: 40, color: AppTheme.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhuma indicação ainda',
                                  style: AppTheme.titleSerif.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Seja o primeiro a sugerir um livro para o sorteio!',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._hub!.nominationsPreview.map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: NominationCard(
                                nomination: n,
                                compact: true,
                                votingEnabled: _hub!.cycle.isOpen,
                                onVote: _votingIds.contains(n.id) ? () {} : () => _vote(n),
                              ),
                            ),
                          ),
                        if (_hub!.totalNominations > _hub!.nominationsPreview.length)
                          Center(
                            child: TextButton.icon(
                              onPressed: () => context.push('/clube/${widget.clubId}/votacao'),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text('Ver todas as ${_hub!.totalNominations} indicações'),
                            ),
                          ),
                        const SizedBox(height: 24),
                        _GuidelinesCard(maxVotes: _hub!.maxVotesPerUser),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _CycleHeader extends StatelessWidget {
  const _CycleHeader({required this.cycle, required this.clubName});

  final BookClubCycleInfo cycle;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CICLO ${cycle.titulo.toUpperCase()}',
          style: AppTheme.labelSans.copyWith(
            color: AppTheme.secondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(clubName, style: AppTheme.headlineSerif),
        const SizedBox(height: 8),
        Text(
          'Indique títulos, vote nas sugestões da comunidade e participe do sorteio da leitura do mês.',
          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _GuidelinesCard extends StatelessWidget {
  const _GuidelinesCard({required this.maxVotes});

  final int maxVotes;

  @override
  Widget build(BuildContext context) {
    return BibCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Regras do clube', style: AppTheme.titleSerif),
                const SizedBox(height: 8),
                Text(
                  'Cada membro pode indicar 1 livro e usar até $maxVotes votos por ciclo. '
                  'No sorteio, títulos com mais votos têm maior chance de serem escolhidos para o debate.',
                  style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
