import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/editor_repository.dart';

class EditorRequestsScreen extends ConsumerStatefulWidget {
  const EditorRequestsScreen({super.key});

  @override
  ConsumerState<EditorRequestsScreen> createState() => _EditorRequestsScreenState();
}

class _EditorRequestsScreenState extends ConsumerState<EditorRequestsScreen> {
  List<EditorRequest> _items = [];
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
      final list = await ref.read(editorRepositoryProvider).listRequests();
      setState(() => _items = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar solicitações.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(EditorRequest req) async {
    final controller = TextEditingController(text: req.resposta ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Responder — ${req.leitorNome}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Sua resposta…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(editorRepositoryProvider).respondRequest(req.id, controller.text.trim());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resposta enviada')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('Nenhuma solicitação')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final r = _items[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (r.livroImagemUrl != null)
                                          BookCover(
                                            url: r.livroImagemUrl,
                                            width: 40,
                                            height: 52,
                                          ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(r.leitorNome,
                                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                                              if (r.livroTitulo != null)
                                                Text('${r.livroTitulo} — ${r.livroAutor ?? ''}',
                                                    style: const TextStyle(
                                                      color: AppTheme.muted,
                                                      fontSize: 13,
                                                    )),
                                            ],
                                          ),
                                        ),
                                        Chip(label: Text(r.status)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(r.conteudo),
                                    if (r.resposta != null && r.resposta!.isNotEmpty) ...[
                                      const Divider(),
                                      Text('Resposta: ${r.resposta}',
                                          style: const TextStyle(fontStyle: FontStyle.italic)),
                                    ],
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _respond(r),
                                        child: Text(r.resposta == null ? 'Responder' : 'Editar resposta'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
