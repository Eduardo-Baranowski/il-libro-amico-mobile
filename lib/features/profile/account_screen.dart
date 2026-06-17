import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import 'api_settings_tile.dart';
import 'profile_edit_dialog.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _openProfileEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ProfileEditDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated) {
      return ListView(
        padding: const EdgeInsets.all(AppTheme.marginMobile),
        children: [
          Text('Sua conta', style: AppTheme.headlineSerif),
          const SizedBox(height: 8),
          Text(
            'Entre para mensagens, leituras e compras.',
            style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const ApiSettingsCard(),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => context.push('/entrar'), child: const Text('Entrar')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => context.push('/cadastro'), child: const Text('Criar conta')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 8, AppTheme.marginMobile, 32),
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => _openProfileEditor(context),
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
                    url: auth.imageUrl,
                    name: auth.name ?? '',
                    radius: 56,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: AppTheme.primary,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppTheme.surface, width: 3),
                  ),
                  child: InkWell(
                    onTap: () => _openProfileEditor(context),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          auth.name ?? 'Usuário',
          textAlign: TextAlign.center,
          style: AppTheme.displaySerif.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 4),
        Text(
          auth.role?.label ?? '',
          textAlign: TextAlign.center,
          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        if (auth.role == UserRole.leitor) ...[
          const SizedBox(height: 8),
          Center(
            child: BibStatusChip(label: 'Leitor', tone: BibChipTone.sage),
          ),
        ],
        const SizedBox(height: 28),
        _MenuSection(
          children: [
            _MenuTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Mensagens',
              onTap: () => context.push('/mensagens'),
            ),
            _MenuTile(
              icon: Icons.groups_outlined,
              title: 'Clube do livro',
              subtitle: 'Indique, vote e participe do sorteio',
              onTap: () => context.push('/clube'),
            ),
            if (auth.role == UserRole.leitor)
              _MenuTile(
                icon: Icons.library_books_outlined,
                title: 'Minha estante',
                onTap: () => context.go('/estante'),
              ),
          ],
        ),
        if (auth.role == UserRole.admin) ...[
          const SizedBox(height: 16),
          Text('Administração', style: AppTheme.labelSans.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 8),
          _MenuSection(
            children: [
              _MenuTile(
                icon: Icons.people_outline_rounded,
                title: 'Usuários',
                onTap: () => context.push('/admin/usuarios'),
              ),
              _MenuTile(
                icon: Icons.analytics_outlined,
                title: 'Relatórios',
                onTap: () => context.push('/admin/relatorios'),
              ),
              _MenuTile(
                icon: Icons.library_books_outlined,
                title: 'Moderação de Livros',
                onTap: () => context.push('/admin/livros'),
              ),
              _MenuTile(
                icon: Icons.business_rounded,
                title: 'Editoras',
                onTap: () => context.push('/admin/editoras'),
              ),
            ],
          ),
        ],
        if (auth.role == UserRole.editor) ...[
          const SizedBox(height: 16),
          Text('Editora', style: AppTheme.labelSans.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 8),
          _MenuSection(
            children: [
              _MenuTile(
                icon: Icons.storefront_outlined,
                title: 'Meu catálogo',
                onTap: () => context.go('/livros'),
              ),
              _MenuTile(
                icon: Icons.inbox_outlined,
                title: 'Solicitações',
                onTap: () => context.push('/editor/solicitacoes'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const ApiSettingsCard(),
        const SizedBox(height: 20),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/');
          },
          child: const Text('Sair'),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return BibCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: AppTheme.labelSans),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTheme.captionSans) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.outline),
      onTap: onTap,
    );
  }
}
