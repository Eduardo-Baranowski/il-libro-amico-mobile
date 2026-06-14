import 'package:flutter/material.dart';

import '../../config/api_config.dart';

/// Configuração da URL da API (visível mesmo sem login).
class ApiSettingsCard extends StatefulWidget {
  const ApiSettingsCard({super.key});

  @override
  State<ApiSettingsCard> createState() => _ApiSettingsCardState();
}

class _ApiSettingsCardState extends State<ApiSettingsCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.instance.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String? value) async {
    await ApiConfig.instance.setOverride(value);
    if (mounted) {
      setState(() {
        _controller.text = ApiConfig.instance.baseUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL da API salva. Puxe para atualizar o feed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL da API',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Padrão: https://lumina-nodejs-api.vercel.app (produção)\n'
              'Dev local — AVD: http://10.0.2.2:5000 | Genymotion: http://10.0.3.2:5000\n'
              'No Android, 127.0.0.1 é convertido automaticamente para 10.0.2.2.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://lumina-nodejs-api.vercel.app',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ApiConfig.androidPresets.map((url) {
                return ActionChip(
                  label: Text(
                    url.replaceFirst('https://', '').replaceFirst('http://', ''),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    _controller.text = url;
                    _save(url);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _save(_controller.text),
                    child: const Text('Salvar'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _save(null),
                  child: const Text('Padrão'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
