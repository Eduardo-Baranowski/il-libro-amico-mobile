import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/book_club_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../data/book_club_repository.dart';

class BookClubMembersScreen extends ConsumerStatefulWidget {
  const BookClubMembersScreen({super.key, required this.clubId});

  final int clubId;

  @override
  ConsumerState<BookClubMembersScreen> createState() => _BookClubMembersScreenState();
}

class _BookClubMembersScreenState extends ConsumerState<BookClubMembersScreen> {
  List<BookClubMember> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(bookClubRepositoryProvider).getMembers(widget.clubId);
      if (mounted) setState(() => _members = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BibDetailAppBar(title: 'Membros do clube'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.marginMobile),
                children: [
                  Text('Membros do clube', style: AppTheme.headlineSerif),
                  const SizedBox(height: 8),
                  Text(
                    '${_members.length} ${_members.length == 1 ? 'membro' : 'membros'} ativos',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: AppTheme.bodySans.copyWith(color: AppTheme.error)),
                    ),
                  if (_members.isEmpty)
                    BibCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.groups_outlined, size: 40, color: AppTheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum membro encontrado',
                            style: AppTheme.titleSerif.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._members.map((member) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BibCard(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () => context.push('/usuario/${member.userId}'),
                            borderRadius: AppTheme.radiusXl,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppTheme.secondaryContainer,
                                  backgroundImage:
                                      member.imagemUrl != null ? NetworkImage(member.imagemUrl!) : null,
                                  child: member.imagemUrl == null
                                      ? Text(
                                          member.userNome.isNotEmpty
                                              ? member.userNome[0].toUpperCase()
                                              : '?',
                                          style: AppTheme.labelSans,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.userNome,
                                        style: AppTheme.titleSerif.copyWith(fontSize: 16),
                                      ),
                                      if (member.isOwner)
                                        Text(
                                          'Dono do clube',
                                          style: AppTheme.captionSans.copyWith(color: AppTheme.secondary),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.outline),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
