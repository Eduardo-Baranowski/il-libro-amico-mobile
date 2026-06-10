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
import '../core/storage/onboarding_storage.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/splash/welcome_quote_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) => OnboardingStorage());

// null = ainda carregando, false = não completou, true = completou
final onboardingCompletedProvider = StateNotifierProvider<OnboardingStateNotifier, bool?>((ref) {
  return OnboardingStateNotifier(ref.watch(onboardingStorageProvider));
});

class OnboardingStateNotifier extends StateNotifier<bool?> {
  OnboardingStateNotifier(this._storage) : super(null) {
    _restore();
  }
  final OnboardingStorage _storage;

  Future<void> _restore() async {
    state = await _storage.hasCompletedOnboarding();
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted(true);
    state = true;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _RouterListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final onboardingCompleted = ref.read(onboardingCompletedProvider);
      final path = state.uri.path;
      final isAuthRoute = path == '/entrar' || path == '/cadastro';
      final needsAuth = path.startsWith('/mensagens') ||
          path.startsWith('/admin') ||
          path.startsWith('/editor/');

      // Splash screen lida com a própria navegação após terminar a animação
      if (path == '/splash') return null;

      // Aguarda o carregamento do estado de onboarding (null = ainda inicializando)
      if (onboardingCompleted == null) return null;

      // Se o onboarding não foi completado, mostra sempre (independente de auth)
      if (onboardingCompleted == false && path != '/boas-vindas') {
        return '/boas-vindas';
      }
      // Quando onboarding já concluído, sai do /boas-vindas
      if (onboardingCompleted == true && path == '/boas-vindas') {
        return '/';
      }

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
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome-quote',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeQuoteScreen(),
      ),
      GoRoute(
        path: '/boas-vindas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
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

class _RouterListenable extends ChangeNotifier {
  _RouterListenable(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingCompletedProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
