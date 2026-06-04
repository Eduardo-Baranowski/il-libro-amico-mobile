import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../storage/token_storage.dart';
import '../utils/jwt_utils.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class AuthState {
  const AuthState({
    this.token,
    this.role,
    this.name,
    this.imageUrl,
    this.isLoading = false,
  });

  final String? token;
  final UserRole? role;
  final String? name;
  final String? imageUrl;
  final bool isLoading;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  int? get userId => userIdFromToken(token);

  AuthState copyWith({
    String? token,
    UserRole? role,
    String? name,
    String? imageUrl,
    bool? isLoading,
    bool clearSession = false,
  }) {
    if (clearSession) {
      return const AuthState();
    }
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage) : super(const AuthState()) {
    _restore();
  }

  final TokenStorage _storage;

  Future<void> _restore() async {
    final token = await _storage.getToken();
    if (token == null) return;
    state = AuthState(
      token: token,
      role: await _storage.getRole(),
      name: await _storage.getName(),
      imageUrl: await _storage.getImageUrl(),
    );
  }

  Future<void> login(ApiClient api, String email, String senha) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await api.post<Map<String, dynamic>>(
        '/auth/login',
        body: {'email': email, 'senha': senha},
        parser: (d) => d as Map<String, dynamic>,
      );
      final login = LoginResponse.fromJson(res);
      await _storage.saveSession(
        token: login.token,
        role: login.role,
        name: login.name,
        imageUrl: login.imageUrl,
      );
      state = AuthState(
        token: login.token,
        role: login.role,
        name: login.name,
        imageUrl: login.imageUrl,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> register(ApiClient api, String nome, String email, String senha) async {
    state = state.copyWith(isLoading: true);
    try {
      await api.post(
        '/auth/register',
        body: {'nome': nome, 'email': email, 'senha': senha},
      );
      await login(api, email, senha);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = state.copyWith(clearSession: true);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(tokenStorageProvider));
});
