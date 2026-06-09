import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_notifier.dart';
import '../core/models/admin_editor_models.dart';
import '../core/models/user_role.dart';
import '../features/admin/admin_reports_screen.dart';
import '../features/admin/admin_users_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/books/book_detail_screen.dart';
import '../features/books/books_screen.dart';
import '../features/books/editor_public_screen.dart';
import '../features/editor/editor_book_form_screen.dart';
import '../features/editor/editor_requests_screen.dart';
import '../features/home/home_screen.dart';
import '../features/messages/chat_screen.dart';
import '../features/messages/conversations_screen.dart';
import '../features/profile/account_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shelves/shelves_screen.dart';
import '../features/shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/entrar' || path == '/cadastro';
      final needsAuth = path.startsWith('/mensagens') ||
          path.startsWith('/admin') ||
          path.startsWith('/editor/');

      if (needsAuth && !auth.isAuthenticated) {
        return '/entrar';
      }
      if (isAuthRoute && auth.isAuthenticated) {
        return '/';
      }
      if (path.startsWith('/admin') && auth.role != UserRole.admin) {
        return '/';
      }
      if (path.startsWith('/editor/') && auth.role != UserRole.editor) {
        return '/';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/livros',
                builder: (context, state) => const BooksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/estante',
                builder: (context, state) => const ShelvesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conta',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/buscar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/livro/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BookDetailScreen(bookId: id);
        },
      ),
      GoRoute(
        path: '/entrar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/cadastro',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/mensagens',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/mensagens/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = int.parse(state.pathParameters['userId']!);
          final name = state.uri.queryParameters['nome'];
          return ChatScreen(userId: userId, userName: name);
        },
      ),
      GoRoute(
        path: '/admin/usuarios',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/relatorios',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/editor/livro/novo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditorBookFormScreen(),
      ),
      GoRoute(
        path: '/editor/livro/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final book = state.extra as EditorBook?;
          return EditorBookFormScreen(book: book);
        },
      ),
      GoRoute(
        path: '/editor/solicitacoes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditorRequestsScreen(),
      ),
      GoRoute(
        path: '/editora/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditorPublicScreen(editorId: id);
        },
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
