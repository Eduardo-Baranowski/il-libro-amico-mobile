import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/book_club_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../data/book_club_repository.dart';

class BookClubListScreen extends ConsumerStatefulWidget {
  const BookClubListScreen({super.key});

  @override
  ConsumerState<BookClubListScreen> createState() => _BookClubListScreenState();
}

class _BookClubListScreenState extends ConsumerState<BookClubListScreen> {
  final _searchController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  List<BookClub> _myClubs = [];
  List<BookClub> _exploreClubs = [];
  bool _loading = true;
  String? _error;
  final _joiningIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(bookClubRepositoryProvider).listClubs(search: search);
      if (mounted) {
        setState(() {
          _myClubs = res.myClubs;
          _exploreClubs = res.exploreClubs;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _ensureAuth() async {
    if (ref.read(authProvider).isAuthenticated) return true;
    if (mounted) context.push('/entrar');
    return false;
  }

  Future<void> _joinClub(BookClub club) async {
    if (!await _ensureAuth()) return;

    setState(() => _joiningIds.add(club.id));
    try {
      final result = await ref.read(bookClubRepositoryProvider).joinClub(clubId: club.id);
      if (!mounted) return;

      if (result.membershipStatus == 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        context.push('/clube/${club.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada! Aguarde aprovação do dono do clube.')),
        );
        await _load(search: _searchController.text.trim());
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _joiningIds.remove(club.id));
    }
  }

  Future<void> _joinByInviteCode() async {
    if (!await _ensureAuth()) return;

    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um código de convite')),
      );
      return;
    }

    try {
      final result = await ref.read(bookClubRepositoryProvider).joinClub(inviteCode: code);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      if (result.membershipStatus == 'active' && result.clubId != null) {
        context.push('/clube/${result.clubId}');
      } else {
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openCreateClub() async {
    if (!await _ensureAuth()) return;

    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();
    var privado = false;

    final created = await showModalBottomSheet<BookClub>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.marginMobile),
            child: BibCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Criar clube do livro', style: AppTheme.headlineSerif.copyWith(fontSize: 22)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome do clube'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clube privado'),
                    subtitle: const Text('Novos membros precisam de aprovação'),
                    value: privado,
                    onChanged: (v) => setModalState(() => privado = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final nome = nomeController.text.trim();
                      if (nome.isEmpty) return;
                      try {
                        final club = await ref.read(bookClubRepositoryProvider).createClub(
                              nome: nome,
                              descricao: descricaoController.text.trim(),
                              privado: privado,
                            );
                        if (context.mounted) Navigator.pop(context, club);
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
                    child: const Text('Criar clube'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nomeController.dispose();
    descricaoController.dispose();

    if (created != null && mounted) {
      context.push('/clube/${created.id}');
    }
  }

  void _openInviteCodeSheet() {
    _inviteCodeController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.marginMobile),
          child: BibCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Entrar com código', style: AppTheme.titleSerif),
                const SizedBox(height: 12),
                TextField(
                  controller: _inviteCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de convite',
                    hintText: 'Ex: ABC123',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _joinByInviteCode,
                  child: const Text('Entrar no clube'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BibDetailAppBar(title: 'Clubes do Livro'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateClub,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Criar clube'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(search: _searchController.text.trim()),
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
                  Text('Clubes do Livro', style: AppTheme.headlineSerif),
                  const SizedBox(height: 8),
                  Text(
                    'Participe de clubes existentes ou crie o seu para indicar livros e votar com amigos.',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar clubes públicos...',
                      filled: true,
                      fillColor: AppTheme.surfaceContainer,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.outline),
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.radiusXl,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (v) => _load(search: v.trim()),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openInviteCodeSheet,
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('Tenho um código de convite'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: AppTheme.bodySans.copyWith(color: AppTheme.error)),
                  ],
                  const SizedBox(height: 24),
                  if (_myClubs.isNotEmpty) ...[
                    BibSectionHeader(title: 'Meus clubes'),
                    ..._myClubs.map((club) => _ClubTile(
                          club: club,
                          onTap: () {
                            if (club.isPending) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Aguardando aprovação para entrar neste clube'),
                                ),
                              );
                              return;
                            }
                            context.push('/clube/${club.id}');
                          },
                        )),
                    const SizedBox(height: 24),
                  ],
                  BibSectionHeader(title: 'Explorar clubes'),
                  if (_exploreClubs.isEmpty)
                    BibCard(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Nenhum clube público encontrado.',
                        style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    )
                  else
                    ..._exploreClubs.map(
                      (club) => _ClubTile(
                        club: club,
                        showJoin: true,
                        joining: _joiningIds.contains(club.id),
                        onJoin: () => _joinClub(club),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ClubTile extends StatelessWidget {
  const _ClubTile({
    required this.club,
    this.onTap,
    this.showJoin = false,
    this.joining = false,
    this.onJoin,
  });

  final BookClub club;
  final VoidCallback? onTap;
  final bool showJoin;
  final bool joining;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.radiusXl,
          child: BibCard(
            padding: const EdgeInsets.all(16),
            child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                club.privado ? Icons.lock_outline_rounded : Icons.groups_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.nome, style: AppTheme.titleSerif.copyWith(fontSize: 16)),
                  if (club.descricao != null && club.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      club.descricao!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.captionSans.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                  if (club.isPending) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Aguardando aprovação',
                      style: AppTheme.captionSans.copyWith(color: AppTheme.secondary),
                    ),
                  ] else if (club.isOwner) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Dono do clube',
                      style: AppTheme.captionSans.copyWith(color: AppTheme.secondary),
                    ),
                  ],
                ],
              ),
            ),
            if (showJoin)
              joining
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    )
                  : FilledButton.tonal(
                      onPressed: onJoin,
                      child: Text(club.privado ? 'Solicitar' : 'Entrar'),
                    )
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.outline),
          ],
            ),
          ),
        ),
      ),
    );
  }
}
