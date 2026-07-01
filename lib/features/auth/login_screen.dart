import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).login(
            ref.read(apiClientProvider),
            _email.text.trim(),
            _senha.text,
          );
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Falha no login. Verifique a API e a rede.');
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
                      'Entrar',
                      style: AppTheme.headlineSerif.copyWith(
                        fontSize: 24,
                        color: AppTheme.primary,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/images/login/login_cover.png',
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 220,
                                  alignment: Alignment.center,
                                  color: AppTheme.surfaceContainer,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceWhite,
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: AppTheme.cardShadow,
                                    ),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      size: 64,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                    colors: [
                                      AppTheme.surfaceWhite.withValues(alpha: 0.92),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Bem-vindo de volta',
                              style: AppTheme.headlineSerif.copyWith(
                                fontSize: 26,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Acesse sua conta para continuar gerenciando leituras, livros e recomendações.',
                              style: AppTheme.bodySans.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [AutofillHints.email],
                                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                    ),
                                    validator: (v) =>
                                        v == null || !v.contains('@') ? 'Email inválido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _senha,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [AutofillHints.password],
                                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                                    decoration: const InputDecoration(
                                      labelText: 'Senha',
                                    ),
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Informe a senha' : null,
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primarySoft,
                                        borderRadius: AppTheme.radiusLg,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: AppTheme.bodySans.copyWith(
                                                color: AppTheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  Semantics(
                                    button: true,
                                    enabled: !loading,
                                    label: loading ? 'Entrando na conta' : 'Entrar na conta',
                                    child: FilledButton(
                                      onPressed: loading ? null : _submit,
                                      child: loading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Text('Entrar'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Esqueceu a senha?',
                                      style: AppTheme.bodySans.copyWith(
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: TextButton(
                                      onPressed: () => context.push('/cadastro'),
                                      child: Text(
                                        'Criar conta de leitor',
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 18,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sua jornada literária continua aqui',
                      style: AppTheme.bodySans.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
