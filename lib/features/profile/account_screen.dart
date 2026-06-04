import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import 'api_settings_tile.dart';
import '../../core/models/user_role.dart';
import '../../core/widgets/book_cover.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conta')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ApiSettingsCard(),
            const SizedBox(height: 16),
            const Text(
              'Entre para acessar mensagens, leituras e compras.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/entrar'),
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/cadastro'),
              child: const Text('Criar conta'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: UserAvatar(
                url: auth.imageUrl,
                name: auth.name ?? '',
                radius: 28,
              ),
              title: Text(
                auth.name ?? 'Usuário',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(auth.role?.label ?? ''),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Mensagens'),
            onTap: () => context.push('/mensagens'),
          ),
          if (auth.role == UserRole.admin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Administração',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Usuários'),
              onTap: () => context.push('/admin/usuarios'),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Relatórios'),
              onTap: () => context.push('/admin/relatorios'),
            ),
          ],
          if (auth.role == UserRole.editor) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Editora',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: const Text('Meu catálogo'),
              onTap: () => context.go('/livros'),
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Solicitações'),
              onTap: () => context.push('/editor/solicitacoes'),
            ),
          ],
          if (auth.role == UserRole.leitor) ...[
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Minhas leituras'),
              subtitle: const Text('Em breve no app'),
              onTap: () {},
            ),
          ],
          const ApiSettingsCard(),
          const SizedBox(height: 16),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
