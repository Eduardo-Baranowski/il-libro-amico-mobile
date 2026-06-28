import 'dart:async';
import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/utils/image_mime.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminNacionalidadesScreen extends ConsumerStatefulWidget {
  const AdminNacionalidadesScreen({super.key});

  @override
  ConsumerState<AdminNacionalidadesScreen> createState() => _AdminNacionalidadesScreenState();
}

class _AdminNacionalidadesScreenState extends ConsumerState<AdminNacionalidadesScreen> {
  List<NacionalidadeAdmin> _items = [];
  bool _loading = true;
  String? _error;

  final _nome = TextEditingController();
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
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ref.read(adminRepositoryProvider).listNacionalidadesAdmin();
      if (mounted) setState(() => _items = rows);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar nacionalidades.');
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome')));
      return;
    }
    setState(() => _creating = true);
    try {
      final imageFile = _pickedImage != null
          ? (fieldName: 'flag', filePath: _pickedImage!.path, mimeType: mimeTypeFromPath(_pickedImage!.path))
          : null;

      await ref.read(adminRepositoryProvider).createNacionalidade(
            nome: _nome.text.trim(),
            imageFile: imageFile,
          );
      _nome.clear();
      setState(() => _pickedImage = null);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nacionalidade criada')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _delete(NacionalidadeAdmin n) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Confirmar'),
      content: Text('Excluir nacionalidade "${n.nome}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))],
    ));
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteNacionalidade(n.id);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nacionalidade excluída')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _edit(NacionalidadeAdmin n) async {
    final nomeController = TextEditingController(text: n.nome);
    XFile? editImage;
    await showDialog<void>(context: context, builder: (_) => StatefulBuilder(builder: (c, setStateDialog) {
      return AlertDialog(
        title: const Text('Editar nacionalidade'),
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
                backgroundImage: editImage != null ? FileImage(dart_io.File(editImage!.path)) : (n.flagUrl != null ? NetworkImage(n.flagUrl!) as ImageProvider : null),
                child: editImage == null && n.flagUrl == null ? const Icon(Icons.add_a_photo, color: AppTheme.primary) : null,
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
                  ? (fieldName: 'flag', filePath: editImage!.path, mimeType: mimeTypeFromPath(editImage!.path))
                  : null;
              await ref.read(adminRepositoryProvider).updateNacionalidade(id: n.id, nome: nomeController.text.trim().isEmpty ? null : nomeController.text.trim(), imageFile: imageFile);
              Navigator.pop(context);
              await _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nacionalidade atualizada')));
            } on ApiException catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            }
          }, child: const Text('Salvar')),
        ],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nacionalidades'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Criar nacionalidade', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(children: [
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
                        Expanded(child: TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome'), textCapitalization: TextCapitalization.words)),
                      ]),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _creating ? null : _create, child: Text(_creating ? 'Criando…' : 'Criar')),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('${_items.length} nacionalidades', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey))),
                ..._items.map((n) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          backgroundImage: n.flagUrl != null ? NetworkImage(n.flagUrl!) : null,
                          child: n.flagUrl == null ? Text(n.nome.isNotEmpty ? n.nome[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                        ),
                        title: Text(n.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(n.criadoEm),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(n)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(n)),
                        ]),
                      ),
                    ))
              ]),
            ),
    );
  }
}
