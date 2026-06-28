import 'dart:async';
import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/utils/image_mime.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminAuthorFormScreen extends ConsumerStatefulWidget {
  const AdminAuthorFormScreen({super.key, this.authorId});

  final int? authorId;

  @override
  ConsumerState<AdminAuthorFormScreen> createState() => _AdminAuthorFormScreenState();
}

class _AdminAuthorFormScreenState extends ConsumerState<AdminAuthorFormScreen> {
  final _nome = TextEditingController();
  final _nacionalidade = TextEditingController();
  final _bio = TextEditingController();
  List<String> _nationalities = [];
  XFile? _pickedImage;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _fetchNationalities();
  }

  Future<void> _fetchNationalities() async {
    try {
      final list = await ref.read(adminRepositoryProvider).listAuthorNationalities();
      if (mounted) setState(() => _nationalities = list);
    } catch (_) {}
  }

  Future<void> _openCreateNationalityDialog() async {
    final nomeController = TextEditingController();
    XFile? picked;

    await showDialog<void>(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('Criar nacionalidade'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (file != null) setStateDialog(() => picked = file);
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: picked != null ? FileImage(dart_io.File(picked!.path)) : null,
                  child: picked == null ? const Icon(Icons.add_a_photo) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome'))),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () async {
              final name = nomeController.text.trim();
              if (name.isEmpty) return;
              try {
                final imageFile = picked != null
                    ? (fieldName: 'flag', filePath: picked!.path, mimeType: mimeTypeFromPath(picked!.path))
                    : null;
                await ref.read(adminRepositoryProvider).createNacionalidade(nome: name, imageFile: imageFile);
                Navigator.pop(ctx);
                await _fetchNationalities();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nacionalidade criada')));
              } catch (e) {
                if (e is Exception) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            }, child: const Text('Criar')),
          ],
        );
      });
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _nacionalidade.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.authorId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref.read(adminRepositoryProvider).getAuthor(widget.authorId!);
      _nome.text = detail.nome;
      _bio.text = detail.bio ?? '';
      _nacionalidade.text = detail.nacionalidade ?? '';
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar autor.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _save() async {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do autor')));
      return;
    }
    setState(() => _saving = true);
    try {
      final imageFile = _pickedImage != null
          ? (fieldName: 'imagem', filePath: _pickedImage!.path, mimeType: mimeTypeFromPath(_pickedImage!.path))
          : null;

      if (widget.authorId == null) {
        await ref.read(adminRepositoryProvider).createAuthor(
              nome: _nome.text.trim(),
              bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
              nacionalidade: _nacionalidade.text.trim().isEmpty ? null : _nacionalidade.text.trim(),
              imageFile: imageFile,
            );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Autor criado')));
      } else {
        await ref.read(adminRepositoryProvider).updateAuthor(
              id: widget.authorId!,
              nome: _nome.text.trim(),
              bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
              nacionalidade: _nacionalidade.text.trim().isEmpty ? null : _nacionalidade.text.trim(),
              imageFile: imageFile,
            );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Autor atualizado')));
      }
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.authorId == null ? 'Novo autor' : 'Editar autor'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: BackButton(color: Colors.white, onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.primarySoft,
                      backgroundImage: _pickedImage != null ? FileImage(dart_io.File(_pickedImage!.path)) : null,
                      child: _pickedImage == null ? const Icon(Icons.add_a_photo, color: AppTheme.primary, size: 36) : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome'), textCapitalization: TextCapitalization.words),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.toLowerCase();
                      if (q.isEmpty) return _nationalities;
                      return _nationalities.where((e) => e.toLowerCase().contains(q)).toList();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      controller.text = _nacionalidade.text;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      controller.addListener(() {
                        _nacionalidade.text = controller.text;
                      });
                      return Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Nacionalidade'),
                            validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty) return null;
                              if (!_nationalities.contains(val)) return 'Selecione uma nacionalidade existente';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Criar nacionalidade',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _openCreateNationalityDialog,
                        ),
                      ]);
                    },
                    onSelected: (selection) {
                      _nacionalidade.text = selection;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: _bio, decoration: const InputDecoration(labelText: 'Biografia'), maxLines: 6),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Salvando…' : 'Salvar')),
                ],
              ),
            ),
    );
  }
}
