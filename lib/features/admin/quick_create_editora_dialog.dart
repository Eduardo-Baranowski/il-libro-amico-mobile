import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as dart_io;

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_mime.dart';
import '../../data/admin_repository.dart';

/// Modal de cadastro rápido de editora (retorna [Editora] criada via `Navigator.pop`).
class QuickCreateEditoraDialog extends ConsumerStatefulWidget {
  const QuickCreateEditoraDialog({super.key, this.initialName});

  final String? initialName;

  @override
  ConsumerState<QuickCreateEditoraDialog> createState() =>
      _QuickCreateEditoraDialogState();
}

class _QuickCreateEditoraDialogState extends ConsumerState<QuickCreateEditoraDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  bool _loading = false;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final nome = _nomeController.text.trim();
      final imageFile = _pickedImage != null
          ? (fieldName: 'imagem', filePath: _pickedImage!.path, mimeType: mimeTypeFromPath(_pickedImage!.path))
          : null;
      final id = await ref.read(adminRepositoryProvider).createEditora(nome: nome, imageFile: imageFile);
      if (!mounted) return;
      Navigator.of(context).pop(
        Editora(id: id, nome: nome, criadoEm: ''),
      );
    } on ApiException catch (e) {
      // If the editora already exists, try to find it and return the existing record
      if (mounted) {
        final nome = _nomeController.text.trim();
        try {
          final list = await ref.read(adminRepositoryProvider).listEditoras(search: nome);
          if (list.isNotEmpty) {
            Navigator.of(context).pop(list.first);
            return;
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar a editora.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_rounded, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Nova editora',
                    style: AppTheme.labelSans.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Cadastro rápido para vincular ao livro.',
                style: AppTheme.captionSans.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primarySoft,
                      backgroundImage: _pickedImage != null ? FileImage(dart_io.File(_pickedImage!.path)) : null,
                      child: _pickedImage == null ? const Icon(Icons.add_a_photo, color: AppTheme.primary) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Nome da editora',
                        prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o nome da editora';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_loading ? 'Salvando…' : 'Criar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
