import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/book_club_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../data/book_club_repository.dart';

class BookClubRequestsScreen extends ConsumerStatefulWidget {
  const BookClubRequestsScreen({super.key, required this.clubId});

  final int clubId;

  @override
  ConsumerState<BookClubRequestsScreen> createState() => _BookClubRequestsScreenState();
}

class _BookClubRequestsScreenState extends ConsumerState<BookClubRequestsScreen> {
  List<BookClubMemberRequest> _requests = [];
  bool _loading = true;
  String? _error;
  final _processingIds = <int>{};

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
      final items = await ref.read(bookClubRepositoryProvider).getPendingRequests(widget.clubId);
      if (mounted) setState(() => _requests = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(BookClubMemberRequest request, bool approve) async {
    setState(() => _processingIds.add(request.id));
    try {
      if (approve) {
        await ref.read(bookClubRepositoryProvider).approveRequest(widget.clubId, request.id);
      } else {
        await ref.read(bookClubRepositoryProvider).rejectRequest(widget.clubId, request.id);
      }
      if (mounted) {
        setState(() => _requests.removeWhere((r) => r.id == request.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Solicitação aprovada' : 'Solicitação recusada'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BibDetailAppBar(title: 'Solicitações de entrada'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.marginMobile),
                children: [
                  Text('Solicitações pendentes', style: AppTheme.headlineSerif),
                  const SizedBox(height: 8),
                  Text(
                    'Aprove ou recuse pedidos de entrada no seu clube privado.',
                    style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: AppTheme.bodySans.copyWith(color: AppTheme.error)),
                    ),
                  if (_requests.isEmpty)
                    BibCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 40, color: AppTheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma solicitação pendente',
                            style: AppTheme.titleSerif.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._requests.map((request) {
                      final processing = _processingIds.contains(request.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BibCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.secondaryContainer,
                                backgroundImage: request.imagemUrl != null
                                    ? NetworkImage(request.imagemUrl!)
                                    : null,
                                child: request.imagemUrl == null
                                    ? Text(
                                        request.userNome.isNotEmpty
                                            ? request.userNome[0].toUpperCase()
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
                                    Text(request.userNome, style: AppTheme.titleSerif.copyWith(fontSize: 16)),
                                    if (request.userEmail != null)
                                      Text(
                                        request.userEmail!,
                                        style: AppTheme.captionSans.copyWith(color: AppTheme.onSurfaceVariant),
                                      ),
                                  ],
                                ),
                              ),
                              if (processing)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                                )
                              else ...[
                                IconButton(
                                  onPressed: () => _respond(request, false),
                                  icon: const Icon(Icons.close_rounded, color: AppTheme.error),
                                  tooltip: 'Recusar',
                                ),
                                IconButton(
                                  onPressed: () => _respond(request, true),
                                  icon: const Icon(Icons.check_rounded, color: AppTheme.primary),
                                  tooltip: 'Aprovar',
                                ),
                              ],
                            ],
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
