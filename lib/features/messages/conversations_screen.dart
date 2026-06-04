import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  List<Conversation> _items = [];
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
      final res = await ref.read(readerRepositoryProvider).conversations();
      setState(() => _items = res.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar conversas.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mensagens')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Entre para ver suas mensagens.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push('/entrar'),
                child: const Text('Entrar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
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
                            Center(child: Text('Nenhuma conversa ainda.')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final c = _items[i];
                            return ListTile(
                              leading: UserAvatar(
                                url: c.userImagemUrl,
                                name: c.userNome,
                              ),
                              title: Text(c.userNome,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text(
                                c.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: c.unreadCount > 0
                                  ? CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.green,
                                      child: Text(
                                        '${c.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () => context.push(
                                '/mensagens/${c.userId}?nome=${Uri.encodeComponent(c.userNome)}',
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
