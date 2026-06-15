import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

class PublicUserScreen extends ConsumerStatefulWidget {
  const PublicUserScreen({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<PublicUserScreen> createState() => _PublicUserScreenState();
}

class _PublicUserScreenState extends ConsumerState<PublicUserScreen> {
  PublicUser? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ref.read(readerRepositoryProvider).publicUser(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar o perfil.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUser, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_user == null) {
      return const Center(child: Text('Usuário não encontrado.'));
    }

    final auth = ref.watch(authProvider);
    final isMe = auth.isAuthenticated && auth.userId == _user!.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 24, AppTheme.marginMobile, 32),
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: UserAvatar(
              url: _user!.imagemUrl,
              name: _user!.nome,
              radius: 56,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _user!.nome,
          textAlign: TextAlign.center,
          style: AppTheme.displaySerif.copyWith(fontSize: 26),
        ),
        if (_user!.headline != null && _user!.headline!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _user!.headline!,
            textAlign: TextAlign.center,
            style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: BibStatusChip(
            label: _user!.papel.label,
            tone: _user!.papel == UserRole.editor ? BibChipTone.terracotta : BibChipTone.sage,
          ),
        ),
        const SizedBox(height: 32),
        if (!isMe)
          Center(
            child: FilledButton.icon(
              onPressed: () {
                if (!auth.isAuthenticated) {
                  context.push('/entrar');
                  return;
                }
                context.push('/mensagens/${_user!.id}?nome=${Uri.encodeComponent(_user!.nome)}');
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              label: const Text('Enviar mensagem'),
            ),
          ),
        if (!isMe) const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatColumn(label: 'Lidos', value: _user!.lidos.toString()),
            _StatColumn(label: 'Seguidores', value: _user!.seguidores.toString()),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),
        Text('Sobre', style: AppTheme.titleSerif.copyWith(fontSize: 20)),
        const SizedBox(height: 12),
        Text(
          _user!.bio != null && _user!.bio!.isNotEmpty
              ? _user!.bio!
              : 'Sem biografia ainda.',
          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.headlineSerif.copyWith(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.captionSans),
      ],
    );
  }
}
