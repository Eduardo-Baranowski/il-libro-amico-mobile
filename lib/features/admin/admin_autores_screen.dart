import 'dart:async';
import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/utils/image_mime.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminAutoresScreen extends ConsumerStatefulWidget {
  const AdminAutoresScreen({super.key});

  @override
  ConsumerState<AdminAutoresScreen> createState() => _AdminAutoresScreenState();
}

class _AdminAutoresScreenState extends ConsumerState<AdminAutoresScreen> {
  List<AdminAuthor> _autores = [];
  bool _loading = true;
  String? _error;

  final _nome = TextEditingController();
  final _nacionalidade = TextEditingController();
  final _bio = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _creating = false;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nome.dispose();
    _nacionalidade.dispose();
    _bio.dispose();
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
      final autores = await ref.read(adminRepositoryProvider).listAuthors(search: _searchController.text);
      if (mounted) setState(() => _autores = autores);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar autores.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _create() async {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do autor')));
      return;
    }
    setState(() => _creating = true);
    try {
      final imageFile = _pickedImage != null
          ? (fieldName: 'imagem', filePath: _pickedImage!.path, mimeType: mimeTypeFromPath(_pickedImage!.path))
          : null;

      await ref.read(adminRepositoryProvider).createAuthor(
            nome: _nome.text.trim(),
            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
            nacionalidade: _nacionalidade.text.trim().isEmpty ? null : _nacionalidade.text.trim(),
            imageFile: imageFile,
          );
      _nome.clear();
      _bio.clear();
      _nacionalidade.clear();
      setState(() => _pickedImage = null);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Autor criado com sucesso')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _deleteAuthor(AdminAuthor a) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Confirmar'),
      content: Text('Excluir autor "${a.nome}"?'),
      actions: [TextButton(onPressed: () => context.pop(false), child: const Text('Cancelar')), FilledButton(onPressed: () => context.pop(true), child: const Text('Excluir'))],
    ));
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteAuthor(a.id);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Autor excluído')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Autores'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: BackButton(color: Colors.white, onPressed: () => context.pop()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquisar autores...',
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
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Criar autor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primarySoft,
                                  backgroundImage: _pickedImage != null ? FileImage(dart_io.File(_pickedImage!.path)) : null,
                                  child: _pickedImage == null ? const Icon(Icons.add_a_photo, color: AppTheme.primary) : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome do autor'), textCapitalization: TextCapitalization.words),
                                    TextField(controller: _nacionalidade, decoration: const InputDecoration(labelText: 'Nacionalidade')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(controller: _bio, decoration: const InputDecoration(labelText: 'Biografia'), maxLines: 3),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _creating ? null : _create, child: Text(_creating ? 'Criando…' : 'Criar Autor')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('${_autores.length} autores', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                  ),
                  ..._autores.map((a) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            backgroundImage: a.imagemUrl != null ? NetworkImage(a.imagemUrl!) : null,
                            child: a.imagemUrl == null ? Text(a.nome.isNotEmpty ? a.nome[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                          ),
                          title: Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: a.nacionalidade != null ? Text(a.nacionalidade!) : null,
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final res = await context.push('/admin/autores/${a.id}');
                                if (res == true) await _load();
                              },
                            ),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteAuthor(a)),
                          ]),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
