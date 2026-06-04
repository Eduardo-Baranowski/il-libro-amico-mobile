import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

class EditorPublicScreen extends ConsumerStatefulWidget {
  const EditorPublicScreen({super.key, required this.editorId});

  final int editorId;

  @override
  ConsumerState<EditorPublicScreen> createState() => _EditorPublicScreenState();
}

class _EditorPublicScreenState extends ConsumerState<EditorPublicScreen> {
  List<Book> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await ref.read(readerRepositoryProvider).editorBooks(widget.editorId);
      setState(() => _books = books);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Editora não encontrada.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editora')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _books.length,
                    itemBuilder: (context, i) {
                      final b = _books[i];
                      return ListTile(
                        leading: BookCover(url: b.imagemUrl, width: 40, height: 52),
                        title: Text(b.titulo),
                        subtitle: Text('${b.autor} · R\$ ${b.preco}'),
                        onTap: () => context.push('/livro/${b.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
