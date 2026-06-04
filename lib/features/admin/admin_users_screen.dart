import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/models/user_role.dart';
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ref.read(adminRepositoryProvider).listUsers();
      setState(() => _users = users);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
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
                          TextField(
                            controller: _email,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          TextField(
                            controller: _senha,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            obscureText: true,
                          ),
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
                  Text('${_users.length} usuários',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._users.map(
                    (u) => Card(
                      child: ListTile(
                        title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(u.email),
                        trailing: Chip(label: Text(u.papel.name)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
