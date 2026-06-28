import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/book_club_models.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../data/book_club_repository.dart';
import '../../data/search_repository.dart';
import 'widgets/nominate_book_sheet.dart';
import 'widgets/nomination_card.dart';

class BookClubVotingScreen extends ConsumerStatefulWidget {
  const BookClubVotingScreen({super.key, required this.clubId});

  final int clubId;

  @override
  ConsumerState<BookClubVotingScreen> createState() => _BookClubVotingScreenState();
}

class _BookClubVotingScreenState extends ConsumerState<BookClubVotingScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _items = <BookClubNomination>[];
  BookClubCycleInfo? _cycle;
  int _maxVotes = 3;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _pages = 1;
  final _activities = <BookClubActivity>[];
  final _votingIds = <int>{};
  final _deletingIds = <int>{};
  BookClub? _club;
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(page: 1);
    _loadClub();
    _loadActivity();
  }

  bool get _isOwnerOrAdmin {
    final auth = ref.read(authProvider);
    return _club?.isOwner == true || auth.role == UserRole.admin;
  }

  Future<void> _loadClub() async {
    try {
      final hub = await ref.read(bookClubRepositoryProvider).hub(widget.clubId);
      if (mounted) setState(() => _club = hub.club);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wasInBackground) {
      // Recarrega ao voltar para a tela
      _load(page: 1);
      _loadActivity();
    }
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    }
  }

  Future<void> _loadActivity() async {
    try {
      final items = await ref.read(bookClubRepositoryProvider).activity(widget.clubId);
      if (mounted) setState(() => _activities..clear()..addAll(items));
    } catch (_) {}
  }

  Future<void> _load({required int page, String? search}) async {
    if (page > 1 && (_loadingMore || page > _pages)) return;

    setState(() {
      if (page == 1) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final res = await ref.read(bookClubRepositoryProvider).nominations(
            widget.clubId,
            page: page,
            search: search ?? _searchController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(res.items);
        _cycle = res.cycle;
        _page = res.page;
        _pages = res.pages;
        _maxVotes = res.maxVotesPerUser;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
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
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((n) => n.id == nomination.id);
        if (index >= 0) {
          _items[index] = _items[index].copyWith(
            votesCount: result.votesCount,
            votedByMe: result.voted,
          );
        }
      });
      _loadActivity();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _votingIds.remove(nomination.id));
    }
  }

  Future<void> _deleteNomination(BookClubNomination nomination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover indicação'),
        content: Text('Tem certeza que deseja remover "${nomination.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingIds.add(nomination.id));
    try {
      await ref.read(bookClubRepositoryProvider).deleteNomination(widget.clubId, nomination.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((n) => n.id == nomination.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Indicação removida com sucesso')),
        );
      }
      _loadActivity();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(nomination.id));
    }
  }

  Future<void> _openNominate() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      if (mounted) context.push('/entrar');
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
          editoraId: data.editoraId,
          editora: data.editora,
          motivo: data.motivo,
          imageFile: data.imageFile,
          editoraImageFile: data.editoraImageFile,
        ),
      ),
    );

    if (submitted == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livro indicado com sucesso!')),
        );
      }
      await _load(page: 1);
      await _loadActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BibDetailAppBar(title: 'Indicações e votação'),
      floatingActionButton: _cycle?.isOpen == true
          ? FloatingActionButton.extended(
              onPressed: _openNominate,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Indicar livro'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await _load(page: 1);
          await _loadActivity();
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.marginMobile,
                  8,
                  AppTheme.marginMobile,
                  96,
                ),
                children: [
                  if (_cycle != null) ...[
                    Text(
                      'CICLO ${_cycle!.titulo.toUpperCase()}',
                      style: AppTheme.labelSans.copyWith(color: AppTheme.secondary, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text('Indicações e votação', style: AppTheme.headlineSerif),
                    const SizedBox(height: 8),
                    Text(
                      'Proponha sua próxima leitura ou apoie as indicações atuais. '
                      'O sorteio considera os votos como peso na escolha.',
                      style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar títulos ou autores...',
                        filled: true,
                        fillColor: AppTheme.surfaceContainer,
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.outline),
                        border: OutlineInputBorder(
                          borderRadius: AppTheme.radiusXl,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _load(page: 1),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: AppTheme.bodySans.copyWith(color: AppTheme.error)),
                    ),
                  ..._items.map(
                    (n) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: NominationCard(
                          nomination: n,
                          votingEnabled: _cycle?.isOpen ?? false,
                          onVote: _votingIds.contains(n.id) ? () {} : () => _vote(n),
                          onTapBook: n.livroId != null ? () => context.push('/livro/${n.livroId}') : null,
                          onDelete: _isOwnerOrAdmin && !_deletingIds.contains(n.id)
                              ? () => _deleteNomination(n)
                              : null,
                        ),
                      );
                    },
                  ),
                  if (_page < _pages)
                    Center(
                      child: _loadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: AppTheme.primary),
                            )
                          : TextButton(
                              onPressed: () => _load(page: _page + 1),
                              child: const Text('Carregar mais'),
                            ),
                    ),
                  if (_activities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    BibSectionHeader(title: 'Atividade recente'),
                    BibCard(
                      child: Column(
                        children: [
                          for (final activity in _activities.take(8))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.secondaryContainer,
                                    child: Icon(
                                      activity.tipo == 'voto'
                                          ? Icons.how_to_vote_outlined
                                          : Icons.add_rounded,
                                      size: 16,
                                      color: AppTheme.onSecondaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      activity.description,
                                      style: AppTheme.labelSans.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  BibCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppTheme.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Você pode usar até $_maxVotes votos por ciclo e realocá-los até o encerramento da votação.',
                            style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
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
