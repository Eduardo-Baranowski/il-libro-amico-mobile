import 'dart:async';
import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/utils/image_mime.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminEditorasScreen extends ConsumerStatefulWidget {
  const AdminEditorasScreen({super.key});

  @override
  ConsumerState<AdminEditorasScreen> createState() => _AdminEditorasScreenState();
}

class _AdminEditorasScreenState extends ConsumerState<AdminEditorasScreen> {
  List<Editora> _editoras = [];
  bool _loading = true;
  String? _error;

  final _nome = TextEditingController();
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
      final editoras = await ref.read(adminRepositoryProvider).listEditoras(
            search: _searchController.text,
          );
      if (mounted) setState(() => _editoras = editoras);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar editoras.');
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

  Future<void> _delete(Editora e) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Confirmar'),
      content: Text('Excluir editora "${e.nome}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))],
    ));
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteEditora(e.id);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editora excluída')));
    } on ApiException catch (ex) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ex.message)));
    }
  }

  Future<void> _edit(Editora e) async {
    final nomeController = TextEditingController(text: e.nome);
    XFile? editImage;
    await showDialog<void>(context: context, builder: (_) => StatefulBuilder(builder: (c, setStateDialog) {
      return AlertDialog(
        title: const Text('Editar editora'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (file != null) setStateDialog(() => editImage = file);
              },
              child: CircleAvatar(
                radius: 28,
                backgroundImage: editImage != null ? FileImage(dart_io.File(editImage!.path)) : (e.imagemUrl != null ? NetworkImage(e.imagemUrl!) as ImageProvider : null),
                child: editImage == null && e.imagemUrl == null ? const Icon(Icons.add_a_photo, color: AppTheme.primary) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome'))),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            try {
              final imageFile = editImage != null
                  ? (fieldName: 'imagem', filePath: editImage!.path, mimeType: mimeTypeFromPath(editImage!.path))
                  : null;
              await ref.read(adminRepositoryProvider).updateEditora(id: e.id, nome: nomeController.text.trim().isEmpty ? null : nomeController.text.trim(), imageFile: imageFile);
              Navigator.pop(context);
              await _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editora atualizada')));
            } on ApiException catch (ex) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ex.message)));
            }
          }, child: const Text('Salvar')),
        ],
      );
    }));
  }

  Future<void> _create() async {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da editora')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final imageFile = _pickedImage != null
          ? (fieldName: 'imagem', filePath: _pickedImage!.path, mimeType: mimeTypeFromPath(_pickedImage!.path))
          : null;

      await ref.read(adminRepositoryProvider).createEditora(
            nome: _nome.text.trim(),
            imageFile: imageFile,
          );
      _nome.clear();
      setState(() => _pickedImage = null);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editora criada com sucesso')),
        );
      }
    } on ApiException catch (e) {
      // Try to find existing editora by name (in case it was created in another table/endpoint)
      if (mounted) {
        try {
          final list = await ref.read(adminRepositoryProvider).listEditoras(search: _nome.text.trim());
          if (list.isNotEmpty) {
            await _load();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Editora já existe e foi recarregada.')));
            _nome.clear();
            setState(() => _pickedImage = null);
            return;
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Editoras'),
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
                hintText: 'Pesquisar editoras...',
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
                          const Text('Criar editora',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primarySoft,
                                  backgroundImage: _pickedImage != null
                                      ? FileImage(dart_io.File(_pickedImage!.path))
                                      : null,
                                  child: _pickedImage == null
                                      ? const Icon(Icons.add_a_photo, color: AppTheme.primary)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _nome,
                                  decoration: const InputDecoration(labelText: 'Nome da editora'),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _creating ? null : _create,
                            child: Text(_creating ? 'Criando…' : 'Criar Editora'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('${_editoras.length} editoras',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                  ),
                  ..._editoras.map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          backgroundImage: e.imagemUrl != null ? NetworkImage(e.imagemUrl!) : null,
                          child: e.imagemUrl == null
                              ? Text(
                                  e.nome.isNotEmpty ? e.nome[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(e.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: e.criadoEm != null ? Text(e.criadoEm!) : null,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(e)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(e)),
                        ]),
                        onTap: () => _edit(e),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
