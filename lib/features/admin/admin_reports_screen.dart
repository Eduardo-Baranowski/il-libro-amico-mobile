import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/admin_editor_models.dart';
import '../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  AdminReport? _report;
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
      final r = await ref.read(adminRepositoryProvider).reports();
      setState(() => _report = r);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao carregar relatórios.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshMetrics() async {
    try {
      await ref.read(adminRepositoryProvider).refreshMetrics();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Métricas atualizadas')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _metricCard('Usuários', '${r!.totalUsuarios}', AppTheme.primary),
                      const SizedBox(height: 12),
                      _metricCard('Livros', '${r.totalLivros}', Colors.indigo),
                      const SizedBox(height: 12),
                      _metricCard(
                        'Solicitações',
                        '${r.solicitacoes.values.fold(0, (a, b) => a + b)}',
                        Colors.teal,
                      ),
                      const SizedBox(height: 24),
                      const Text('Usuários por papel',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      ...r.usuarios.entries.map(
                        (e) => ListTile(
                          title: Text(e.key),
                          trailing: Text('${e.value}'),
                        ),
                      ),
                      const Divider(height: 32),
                      const Text('Solicitações por status',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      ...r.solicitacoes.entries.map(
                        (e) => ListTile(
                          title: Text(e.key),
                          trailing: Text('${e.value}'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _refreshMetrics,
                        child: const Text('Sincronizar métricas'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
