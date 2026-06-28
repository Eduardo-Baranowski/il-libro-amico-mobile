import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/utils/image_mime.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_theme.dart';
import '../../data/reader_repository.dart';

class RegisterPhotoScreen extends ConsumerStatefulWidget {
  const RegisterPhotoScreen({super.key});

  @override
  ConsumerState<RegisterPhotoScreen> createState() => _RegisterPhotoScreenState();
}

class _RegisterPhotoScreenState extends ConsumerState<RegisterPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _image = picked;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Erro ao selecionar imagem.');
    }
  }

  String _getMimeType(String path) => mimeTypeFromPath(path);

  Future<void> _upload() async {
    if (_image == null) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final imageUrl = await ref.read(readerRepositoryProvider).uploadProfilePhoto(
            _image!.path,
            _getMimeType(_image!.path),
          );
      ref.read(authProvider.notifier).updateImageUrl(imageUrl);
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocorreu um erro ao enviar a foto.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto de perfil'),
        automaticallyImplyLeading: false, // Prevents going back to the register form
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Quase lá!',
              style: AppTheme.headlineSerif,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Adicione uma foto de perfil para que a comunidade possa te reconhecer.',
              style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _loading ? null : _pickImage,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighest,
                        shape: BoxShape.circle,
                        image: _image != null
                            ? DecorationImage(
                                image: FileImage(File(_image!.path)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _image == null
                          ? const Icon(Icons.person_outline_rounded, size: 64, color: AppTheme.outline)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading || _image == null ? null : _upload,
              child: Text(_loading ? 'Enviando...' : 'Concluir'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loading ? null : () => context.go('/'),
              child: const Text('Pular por enquanto'),
            ),
          ],
        ),
      ),
    );
  }
}
