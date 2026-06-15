import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/models/user_role.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final index = navigationShell.currentIndex;
    final showSellFab = auth.role == UserRole.editor && index == 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          BibTopBar(onSearch: () => context.push('/buscar')),
          Expanded(child: navigationShell),
        ],
      ),
      floatingActionButton: showSellFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/editor/livro/novo'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Vender livro'),
            )
          : (auth.isAuthenticated && index == 0)
              ? FloatingActionButton(
                  onPressed: () => context.push('/buscar'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add_rounded),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTap,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Catálogo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Estante',
          ),
          NavigationDestination(
            icon: auth.isAuthenticated
                ? UserAvatar(url: auth.imageUrl, name: auth.name ?? '', radius: 12)
                : const Icon(Icons.person_outline),
            selectedIcon: auth.isAuthenticated
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    child: UserAvatar(url: auth.imageUrl, name: auth.name ?? '', radius: 10),
                  )
                : const Icon(Icons.person_rounded),
            label: 'Conta',
          ),
        ],
      ),
    );
  }
}
