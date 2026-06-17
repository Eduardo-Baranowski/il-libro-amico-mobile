import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<AdminUser> _users = [];
  bool _loading = true;
  String? _error;

  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  UserRole _papel = UserRole.editor;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ref.read(adminRepositoryProvider).listUsers(
        search: _searchController.text,
      );
      if (mounted) setState(() => _users = users);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar usuários.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_nome.text.trim().isEmpty || _email.text.trim().isEmpty || _senha.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, email e senha')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      await ref.read(adminRepositoryProvider).createUser(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            senha: _senha.text,
            papel: _papel,
          );
      _nome.clear();
      _email.clear();
      _senha.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário criado')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover usuário?'),
        content: Text(
          'Tem certeza que deseja remover o usuário "${user.nome}" permanentemente? TODOS os dados associados (livros, leituras, compras, clubes) serão removidos em cascata. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(adminRepositoryProvider).deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário "${user.nome}" removido permanentemente')),
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Usuários'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou email...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(180)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withAlpha(40),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Criar usuário',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nome,
                            decoration: const InputDecoration(labelText: 'Nome'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _email,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _senha,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<UserRole>(
                            value: _papel,
                            decoration: const InputDecoration(labelText: 'Papel'),
                            items: UserRole.values
                                .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                                .toList(),
                            onChanged: (v) => setState(() => _papel = v ?? UserRole.leitor),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _creating ? null : _create,
                            child: Text(_creating ? 'Criando…' : 'Criar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('${_users.length} usuários',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                  ),
                  ..._users.map(
                    (u) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            u.nome.isNotEmpty ? u.nome[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(u.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: u.papel == UserRole.admin 
                                    ? Colors.red.withAlpha(30) 
                                    : u.papel == UserRole.editor 
                                        ? Colors.blue.withAlpha(30)
                                        : Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                u.papel.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: u.papel == UserRole.admin 
                                      ? Colors.red.shade700 
                                      : u.papel == UserRole.editor 
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteUser(u),
                              tooltip: 'Remover',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
