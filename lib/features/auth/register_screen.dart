import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _termsAccepted = false;
  String? _error;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      setState(() => _error = 'Você deve aceitar os termos para continuar.');
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).register(
            ref.read(apiClientProvider),
            _nome.text.trim(),
            _email.text.trim(),
            _senha.text,
          );
      if (mounted) context.go('/cadastro/foto');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Falha no cadastro.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final router = GoRouter.of(context);
                        if (router.canPop()) {
                          router.pop();
                        } else {
                          router.go('/');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Criar conta',
                      style: AppTheme.headlineSerif.copyWith(
                        fontSize: 24,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: AppTheme.radiusXl,
                    boxShadow: AppTheme.cardShadow,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Junte-se à Bibliotheca',
                        style: AppTheme.headlineSerif.copyWith(
                          fontSize: 26,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comece sua jornada em nossa curadoria literária exclusiva.',
                        style: AppTheme.bodySans.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nome,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              decoration: const InputDecoration(labelText: 'Nome completo'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              decoration: const InputDecoration(labelText: 'E-mail'),
                              validator: (v) =>
                                  v == null || !v.contains('@') ? 'Email inválido' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _senha,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(labelText: 'Senha'),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Mínimo 6 caracteres'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _termsAccepted,
                                  activeColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  onChanged: (value) {
                                    setState(() {
                                      _termsAccepted = value ?? false;
                                      _error = null;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Concordo com os ',
                                      style: AppTheme.bodySans.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Termos de Uso',
                                          style: AppTheme.bodySans.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' e a ',
                                          style: AppTheme.bodySans.copyWith(
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Política de Privacidade',
                                          style: AppTheme.bodySans.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: AppTheme.bodySans.copyWith(
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: loading ? null : _submit,
                              child: Text(loading ? 'Cadastrando…' : 'Cadastrar'),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => context.go('/entrar'),
                                child: Text(
                                  'Já possui uma conta? Entrar',
                                  style: AppTheme.bodySans.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
