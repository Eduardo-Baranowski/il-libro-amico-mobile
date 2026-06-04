import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../data/reader_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.userId, this.userName});

  final int userId;
  final String? userName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messages = <DirectMessage>[];
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  int _lastId = 0;
  bool _loading = true;
  Timer? _poll;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _sync(full: true);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _sync());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sync({bool full = false}) async {
    try {
      final batch = await ref.read(readerRepositoryProvider).messagesWith(
            widget.userId,
            afterId: full ? 0 : _lastId,
          );
      if (!mounted) return;
      setState(() {
        if (full) _messages.clear();
        for (final m in batch) {
          if (!_messages.any((x) => x.id == m.id)) {
            _messages.add(m);
          }
        }
        _messages.sort((a, b) => a.id.compareTo(b.id));
        if (_messages.isNotEmpty) {
          _lastId = _messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
        }
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(readerRepositoryProvider).sendMessage(widget.userId, text);
      _controller.clear();
      await _sync(full: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meId = ref.watch(authProvider).userId;

    return Scaffold(
      appBar: AppBar(title: Text(widget.userName ?? 'Conversa')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isMe = m.senderId == meId;
                      final time = m.dataEnvio != null
                          ? DateFormat.Hm().format(DateTime.parse(m.dataEnvio!))
                          : '';
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: isMe
                                ? null
                                : Border.all(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                m.conteudo,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white70
                                      : AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Escreva uma mensagem…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
